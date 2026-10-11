
const { stops, connections } = require("../data/network");

function findFastestJourney(originId, destinationId, disruptionList = []) {
  const origin = stops.find(stop => stop.id === originId);
  const destination = stops.find(stop => stop.id === destinationId);

  if (!origin || !destination) {
    throw new Error("Invalid origin or destination stop.");
  }

  if (originId === destinationId) {
    return {
      origin,
      destination,
      durationMinutes: 0,
      fare: 0,
      transfers: 0,
      segments: [],
      warning: "Same origin and destination."
    };
  }

  const disruptionMap = new Map(
    disruptionList.map(item => [item.connectionId, item])
  );

  const graph = new Map(stops.map(stop => [stop.id, []]));

  for (const connection of connections) {
    const disruption = disruptionMap.get(connection.id);

    if (disruption?.status === "cancelled") {
      continue;
    }

    const delay =
      disruption?.status === "delayed"
        ? Number(disruption.delayMinutes) || 0
        : 0;

    const edge = {
      ...connection,
      effectiveDuration: connection.durationMinutes + delay
    };

    graph.get(connection.from).push({
      ...edge,
      nextStop: connection.to
    });

    if (connection.bidirectional) {
      graph.get(connection.to).push({
        ...edge,
        from: connection.to,
        to: connection.from,
        nextStop: connection.from
      });
    }
  }

  const distances = new Map(stops.map(stop => [stop.id, Infinity]));
  const previous = new Map();
  const visited = new Set();

  distances.set(originId, 0);

  while (visited.size < stops.length) {
    let currentId = null;
    let bestDistance = Infinity;

    for (const stop of stops) {
      const distance = distances.get(stop.id);

      if (!visited.has(stop.id) && distance < bestDistance) {
        bestDistance = distance;
        currentId = stop.id;
      }
    }

    if (currentId === null || bestDistance === Infinity) {
      break;
    }

    if (currentId === destinationId) {
      break;
    }

    visited.add(currentId);

    for (const edge of graph.get(currentId)) {
      if (visited.has(edge.nextStop)) continue;

      const newDistance =
        distances.get(currentId) + edge.effectiveDuration;

      if (newDistance < distances.get(edge.nextStop)) {
        distances.set(edge.nextStop, newDistance);
        previous.set(edge.nextStop, {
          stopId: currentId,
          edge
        });
      }
    }
  }

  if (distances.get(destinationId) === Infinity) {
    return {
      origin,
      destination,
      reachable: false,
      message: "No available route was found.",
      warning: "The sample network may not contain a valid alternative."
    };
  }

  const segments = [];
  let cursor = destinationId;

  while (cursor !== originId) {
    const step = previous.get(cursor);

    if (!step) {
      throw new Error("Could not reconstruct the journey.");
    }

    segments.unshift({
      connectionId: step.edge.id,
      from: step.edge.from,
      to: step.edge.to,
      fromName: stops.find(s => s.id === step.edge.from).name,
      toName: stops.find(s => s.id === step.edge.to).name,
      mode: step.edge.mode,
      durationMinutes: step.edge.effectiveDuration,
      baseDurationMinutes: step.edge.durationMinutes,
      delayMinutes: step.edge.effectiveDuration - step.edge.durationMinutes,
      fare: step.edge.fare
    });

    cursor = step.stopId;
  }

  let transfers = 0;

  for (let i = 1; i < segments.length; i++) {
    if (segments[i].mode !== segments[i - 1].mode) {
      transfers++;
    }
  }

  return {
    reachable: true,
    origin,
    destination,
    durationMinutes: distances.get(destinationId),
    fare: segments.reduce((sum, segment) => sum + segment.fare, 0),
    transfers,
    segments,
    warning:
      "Uses illustrative sample data, not live schedules or verified fares."
  };
}

module.exports = { findFastestJourney };
