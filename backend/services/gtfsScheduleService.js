
const { loadAllGtfs } = require("./gtfsImporter");

const WEEKDAYS = [
  "sunday",
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday"
];

let cachedDatasets = null;

function getDatasets() {
  if (!cachedDatasets) {
    cachedDatasets = loadAllGtfs();
  }

  return cachedDatasets;
}

function toGtfsDate(date) {
  return date.toISOString().slice(0, 10).replace(/-/g, "");
}

function parseTravelDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || "")) {
    throw new Error("Travel date must use YYYY-MM-DD format.");
  }

  const date = new Date(`${value}T12:00:00Z`);

  if (
    Number.isNaN(date.getTime()) ||
    date.toISOString().slice(0, 10) !== value
  ) {
    throw new Error("Invalid travel date.");
  }

  return date;
}

function serviceRunsOnDate(dataset, serviceId, date) {
  const dateString = toGtfsDate(date);

  // Explicit exceptions override the regular weekly calendar.
  const exceptions = dataset.calendarDates.filter(
    row => row.service_id === serviceId && row.date === dateString
  );

  if (exceptions.length > 0) {
    const latest = exceptions[exceptions.length - 1];

    if (latest.exception_type === "1") return true;
    if (latest.exception_type === "2") return false;
  }

  const weekday = WEEKDAYS[date.getUTCDay()];

  const calendar = dataset.calendars.find(
    row => row.service_id === serviceId
  );

  if (calendar) {
    return (
      calendar.start_date <= dateString &&
      calendar.end_date >= dateString &&
      calendar[weekday] === "1"
    );
  }

  // If calendar.txt has no entry, an explicit exception of type 1
  // is required to establish that the service operates on this date.
  return false;
}

function timeToSeconds(value) {
  if (!/^\d{1,3}:[0-5]\d:[0-5]\d$/.test(value || "")) {
    return null;
  }

  const [hours, minutes, seconds] = value.split(":").map(Number);

  return hours * 3600 + minutes * 60 + seconds;
}

function getScheduledConnections(travelDate) {
  const date = parseTravelDate(travelDate);
  const datasets = getDatasets();

  const connections = [];
  const errors = [];

  for (const [datasetName, dataset] of Object.entries(datasets)) {
    if (!dataset.valid) {
      errors.push({
        dataset: datasetName,
        message: "Dataset failed GTFS structural validation."
      });
      continue;
    }

    const activeServices = new Set();

    const serviceIds = new Set([
      ...dataset.calendars.map(row => row.service_id),
      ...dataset.calendarDates.map(row => row.service_id)
    ]);

    for (const serviceId of serviceIds) {
      if (serviceRunsOnDate(dataset, serviceId, date)) {
        activeServices.add(serviceId);
      }
    }

    const tripsById = new Map(
      dataset.trips.map(trip => [trip.trip_id, trip])
    );

    for (const [tripId, rawStopTimes] of dataset.stopTimesByTrip) {
      const trip = tripsById.get(tripId);

      if (!trip || !activeServices.has(trip.service_id)) {
        continue;
      }

      const times = rawStopTimes;

      for (let i = 0; i < times.length - 1; i++) {
        const from = times[i];
        const to = times[i + 1];

        const departure = timeToSeconds(from.departure_time);
        const arrival = timeToSeconds(to.arrival_time);

        if (
          !from.stop_id ||
          !to.stop_id ||
          departure === null ||
          arrival === null ||
          arrival < departure
        ) {
          continue;
        }

        const durationMinutes = (arrival - departure) / 60;

        if (durationMinutes <= 0 || durationMinutes > 1440) {
          continue;
        }

        connections.push({
          id: `${datasetName}:${tripId}:${from.stop_sequence}-${to.stop_sequence}`,
          source: datasetName,
          tripId,
          routeId: trip.route_id,
          serviceId: trip.service_id,
          fromStopId: from.stop_id,
          toStopId: to.stop_id,
          departureTime: from.departure_time,
          arrivalTime: to.arrival_time,
          departureSeconds: departure,
          arrivalSeconds: arrival,
          durationMinutes,
          fare: null,
          scheduled: true
        });
      }
    }
  }

  return {
    travelDate,
    dataType: "static_gtfs_schedule",
    connections,
    errors,
    summary: {
      connectionCount: connections.length,
      byDataset: {
        cmrl: connections.filter(c => c.source === "cmrl").length,
        mtc: connections.filter(c => c.source === "mtc").length,
        suburbanRail: connections.filter(
          c => c.source === "suburbanRail"
        ).length
      }
    }
  };
}

module.exports = {
  getScheduledConnections,
  serviceRunsOnDate,
  timeToSeconds
};
