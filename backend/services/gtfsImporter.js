
const fs = require("fs");
const path = require("path");
const { parse } = require("csv-parse/sync");

const GTFS_ROOT = path.join(__dirname, "..", "gtfs");

const DATASETS = {
  cmrl: path.join(GTFS_ROOT, "cmrl-gtfs"),
  mtc: path.join(GTFS_ROOT, "mtc-gtfs"),
  suburbanRail: path.join(GTFS_ROOT, "srr-gtfs")
};

function readCsv(filePath, required = false) {
  if (!fs.existsSync(filePath)) {
    if (required) {
      throw new Error(`Required GTFS file is missing: ${filePath}`);
    }
    return [];
  }

  const content = fs.readFileSync(filePath, "utf8");

  return parse(content, {
    columns: true,
    skip_empty_lines: true,
    bom: true,
    relax_column_count: false,
    trim: true
  });
}

function numberOrNull(value) {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function loadDataset(name, directory) {
  const stops = readCsv(path.join(directory, "stops.txt"), true);
  const routes = readCsv(path.join(directory, "routes.txt"), true);
  const trips = readCsv(path.join(directory, "trips.txt"), true);
  const stopTimes = readCsv(path.join(directory, "stop_times.txt"), true);

  const calendars = readCsv(path.join(directory, "calendar.txt"));
  const calendarDates = readCsv(
    path.join(directory, "calendar_dates.txt")
  );

  const stopIds = new Set(stops.map(stop => stop.stop_id));
  const tripIds = new Set(trips.map(trip => trip.trip_id));
  const routeIds = new Set(routes.map(route => route.route_id));

  const errors = [];

  for (const stop of stops) {
    if (!stop.stop_id || !stop.stop_name) {
      errors.push("A stop is missing stop_id or stop_name.");
      break;
    }
  }

  for (const trip of trips) {
    if (!trip.trip_id || !trip.route_id) {
      errors.push("A trip is missing trip_id or route_id.");
      break;
    }

    if (!routeIds.has(trip.route_id)) {
      errors.push(`Trip ${trip.trip_id} references a missing route.`);
      break;
    }
  }

  for (const stopTime of stopTimes) {
    if (!tripIds.has(stopTime.trip_id)) {
      errors.push(
        `Stop time references missing trip ${stopTime.trip_id}.`
      );
      break;
    }

    if (!stopIds.has(stopTime.stop_id)) {
      errors.push(
        `Stop time references missing stop ${stopTime.stop_id}.`
      );
      break;
    }

    if (
      numberOrNull(stopTime.stop_sequence) === null ||
      numberOrNull(stopTime.stop_sequence) < 0
    ) {
      errors.push(
        `Trip ${stopTime.trip_id} has an invalid stop sequence.`
      );
      break;
    }
  }

  const stopTimesByTrip = new Map();

  for (const stopTime of stopTimes) {
    if (!stopTimesByTrip.has(stopTime.trip_id)) {
      stopTimesByTrip.set(stopTime.trip_id, []);
    }

    stopTimesByTrip.get(stopTime.trip_id).push({
      ...stopTime,
      stop_sequence: Number(stopTime.stop_sequence)
    });
  }

  for (const rows of stopTimesByTrip.values()) {
    rows.sort((a, b) => a.stop_sequence - b.stop_sequence);
  }

  const stopsById = new Map(
    stops.map(stop => [
      stop.stop_id,
      {
        ...stop,
        stop_lat: numberOrNull(stop.stop_lat),
        stop_lon: numberOrNull(stop.stop_lon)
      }
    ])
  );

  return {
    name,
    directory,
    valid: errors.length === 0,
    errors,
    stops,
    routes,
    trips,
    stopTimes,
    calendars,
    calendarDates,
    stopsById,
    stopTimesByTrip,
    summary: {
      stops: stops.length,
      routes: routes.length,
      trips: trips.length,
      stopTimes: stopTimes.length,
      calendars: calendars.length,
      calendarDates: calendarDates.length,
      tripsWithStopTimes: stopTimesByTrip.size
    }
  };
}

function loadAllGtfs() {
  const datasets = {};

  for (const [name, directory] of Object.entries(DATASETS)) {
    datasets[name] = loadDataset(name, directory);
  }

  return datasets;
}

function getGtfsSummary() {
  const datasets = loadAllGtfs();

  return Object.fromEntries(
    Object.entries(datasets).map(([name, dataset]) => [
      name,
      {
        valid: dataset.valid,
        errors: dataset.errors,
        ...dataset.summary
      }
    ])
  );
}

module.exports = {
  loadDataset,
  loadAllGtfs,
  getGtfsSummary
};
