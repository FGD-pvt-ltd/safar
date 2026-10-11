
const { stops, connections } = require("../data/network");

function findFastestJourney(originId, destinationId) {
  const stopIds = new Set(stops.map((stop) => stop.id));

  if (!stopIds.has(originId) || !stopIds.has(destinationId)) {
    const error = new Error("Unknown origin or destination stop");
    error.statusCode = 400;
    throw error;
  }

  if (originId === destinationId) {
    return {
      origin: stops.find((s) => s.id === originId),
      destination: stops.find((s) => s.id === destinationId),
      totalDurationMinutes: 0,
      estimatedFare: 0,
      transfers: 0,
      segments: []
    };
  }

  // Build the graph from the transport connections.
  const graph = new Map(stops.map((stop) => [stop.id, []]));

  for (const connection of connections) {
    if (
      !graph.has(connection.from) ||
      !graph.has(connection.to) ||
      !Number.isFinite(connection.durationMinutes) ||
      connection.durationMinutes <= 0
    ) {
      continue;
    }

    graph.get(connection.from).push(connection);

    if (connection.bidirectional) {
      graph.get(connection.to).push({
        ...connection,
        from: connection.to,
        to: connection.from
      });
    }
  }

  // Dijkstra's algorithm: shortest travel time.
  const distances = new Map(
    stops.map((stop) => [stop.id, Infinity])
  );
  const previous = new Map();
  const unvisited = new Set(stopIds);

  distances.set(originId, 0);

  while (unvisited.size > 0) {
    let current = null;
    let bestDistance = Infinity;

    for (const stopId of unvisited) {
      const distance = distances.get(stopId);

      if (distance < bestDistance) {
        bestDistance = distance;
        current = stopId;
      }
    }

    if (current === null) break;
    if (current === destinationId) break;

    unvisited.delete(current);

    for (const edge of graph.get(current)) {
      if (!unvisited.has(edge.to)) continue;

      const candidate =
        distances.get(current) + edge.durationMinutes;

      if (candidate < distances.get(edge.to)) {
        distances.set(edge.to, candidate);
        previous.set(edge.to, {
          stopId: current,
          connection: edge
        });
      }
    }
  }

  if (!Number.isFinite(distances.get(destinationId))) {
    return null;
  }

  // Reconstruct the journey.
  const segments = [];
  let current = destinationId;

  while (current !== originId) {
    const step = previous.get(current);

    if (!step) return null;

    segments.unshift(step.connection);
    current = step.stopId;
  }

  const usedStops = [originId, ...segments.map((s) => s.to)];
  const stopById = new Map(stops.map((stop) => [stop.id, stop]));

  const journeySegments = segments.map((segment) => ({
    from: stopById.get(segment.from),
    to: stopById.get(segment.to),
    mode: segment.mode,
    service: segment.service,
    durationMinutes: segment.durationMinutes,
    estimatedFare: segment.fare
  }));

  // Count changes between transport modes as transfers.
  let transfers = 0;

  for (let i = 1; i < segments.length; i++) {
    if (segments[i].mode !== segments[i - 1].mode) {
      transfers++;
    }
  }

  return {
    origin: stopById.get(originId),
    destination: stopById.get(destinationId),
    totalDurationMinutes: distances.get(destinationId),
    estimatedFare: segments.reduce(
      (total, segment) => total + (segment.fare ?? 0),
      0
    ),
    transfers,
    stopsVisited: usedStops.map((id) => stopById.get(id)),
    segments: journeySegments,
    dataSource: "mock",
    warning: "Sample data only. Not suitable for real-time travel decisions."
  };
}

module.exports = { findFastestJourney };
