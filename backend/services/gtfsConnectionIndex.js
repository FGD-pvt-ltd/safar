
const { getScheduledConnections } = require("./gtfsScheduleService");

const MAX_CACHED_DATES = 2;
const dateCache = new Map();

function getConnectionIndex(travelDate) {
  if (dateCache.has(travelDate)) {
    const cached = dateCache.get(travelDate);

    // Refresh insertion order so recently used dates stay cached.
    dateCache.delete(travelDate);
    dateCache.set(travelDate, cached);

    return cached;
  }

  const result = getScheduledConnections(travelDate);
  const byDepartureStop = new Map();

  for (const connection of result.connections) {
    if (!byDepartureStop.has(connection.fromStopId)) {
      byDepartureStop.set(connection.fromStopId, []);
    }

    byDepartureStop.get(connection.fromStopId).push(connection);
  }

  for (const connections of byDepartureStop.values()) {
    connections.sort(
      (a, b) => a.departureSeconds - b.departureSeconds
    );
  }

  const index = {
    travelDate: result.travelDate,
    dataType: result.dataType,
    byDepartureStop,
    datasets: result.datasets,
    summary: result.summary,
    errors: result.errors
  };

  dateCache.set(travelDate, index);

  while (dateCache.size > MAX_CACHED_DATES) {
    const oldestDate = dateCache.keys().next().value;
    dateCache.delete(oldestDate);
  }

  return index;
}

function findConnectionsFrom(stopId, travelDate, afterSeconds = 0) {
  if (!stopId || typeof stopId !== "string") {
    throw new Error("A valid GTFS stop ID is required.");
  }

  if (
    !Number.isFinite(afterSeconds) ||
    afterSeconds < 0 ||
    afterSeconds > 172800
  ) {
    throw new Error("Departure time must be between 0 and 172800 seconds.");
  }

  const index = getConnectionIndex(travelDate);
  const connections = index.byDepartureStop.get(stopId) || [];

  // Find the first departure at or after the requested time.
  let low = 0;
  let high = connections.length;

  while (low < high) {
    const middle = Math.floor((low + high) / 2);

    if (connections[middle].departureSeconds < afterSeconds) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }

  return {
    travelDate,
    stopId,
    dataType: index.dataType,
    connections: connections.slice(low),
    totalDeparturesAtStop: connections.length,
    summary: index.summary
  };
}

function clearConnectionIndexCache() {
  dateCache.clear();
}

module.exports = {
  getConnectionIndex,
  findConnectionsFrom,
  clearConnectionIndexCache
};
