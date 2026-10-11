
const { stops, connections } = require("../data/network");

const DATA_NOTICE =
  "LOW CONFIDENCE: route times and fares use simulated development data, not verified live Chennai transit information.";

const WEIGHTS = {
  fastest: { time: 0.70, fare: 0.10, transfers: 0.20 },
  cheapest: { time: 0.15, fare: 0.70, transfers: 0.15 },
  balanced: { time: 0.45, fare: 0.35, transfers: 0.20 }
};

function findAlternativeJourneys(
  originId,
  destinationId,
  disruptionList = [],
  options = {}
) {
  const origin = stops.find(stop => stop.id === originId);
  const destination = stops.find(stop => stop.id === destinationId);

  if (!origin || !destination) {
    throw new Error("Please select valid origin and destination stops.");
  }

  const preference = options.preference || "balanced";

  if (!WEIGHTS[preference]) {
    throw new Error("Preference must be fastest, cheapest, or balanced.");
  }

  let maxFare = null;

  if (
    options.maxFare !== undefined &&
    options.maxFare !== null &&
    options.maxFare !== ""
  ) {
    maxFare = Number(options.maxFare);

    if (!Number.isFinite(maxFare) || maxFare < 0 || maxFare > 100000) {
      throw new Error("Budget must be between ₹0 and ₹100000.");
    }
  }

  if (originId === destinationId) {
    const journey = {
      reachable: true,
      origin,
      destination,
      durationMinutes: 0,
      fare: 0,
      transfers: 0,
      segments: [],
      score: 100,
      preference,
      explanation: "You are already at your destination.",
      dataConfidence: "low",
      dataNotice: DATA_NOTICE
    };

    return {
      success: true,
      origin,
      destination,
      preference,
      maxFare,
      budgetExceeded: false,
      routes: [journey],
      message: "Origin and destination are the same."
    };
  }

  const disruptionMap = new Map(
    disruptionList.map(item => [item.connectionId, item])
  );

  const graph = new Map(stops.map(stop => [stop.id, []]));

  for (const connection of connections) {
    const disruption = disruptionMap.get(connection.id);

    if (disruption?.status === "cancelled") continue;

    const delay =
      disruption?.status === "delayed"
        ? Math.max(0, Number(disruption.delayMinutes) || 0)
        : 0;

    const edge = {
      ...connection,
      effectiveDuration: connection.durationMinutes + delay,
      delayMinutes: delay,
      disrupted: Boolean(disruption)
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

  // Best-first search over simple paths. A path cannot revisit a stop.
  // The expansion limit prevents excessive work on larger networks.
  const queue = [{
    currentId: originId,
    visited: new Set([originId]),
    segments: [],
    durationMinutes: 0,
    fare: 0
  }];

  const candidates = [];
  let expanded = 0;
  const MAX_EXPANSIONS = 12000;
  const MAX_CANDIDATES = 1000;

  while (
    queue.length &&
    expanded < MAX_EXPANSIONS &&
    candidates.length < MAX_CANDIDATES
  ) {
    queue.sort((a, b) => a.durationMinutes - b.durationMinutes);
    const path = queue.shift();
    expanded++;

    if (path.currentId === destinationId) {
      const modes = path.segments.map(segment => segment.mode);
      let transfers = 0;

      for (let i = 1; i < modes.length; i++) {
        if (modes[i] !== modes[i - 1]) transfers++;
      }

      candidates.push({
        reachable: true,
        origin,
        destination,
        durationMinutes: path.durationMinutes,
        fare: path.fare,
        transfers,
        segments: path.segments,
        disruptionCount: path.segments.filter(s => s.disrupted).length,
        connectionIds: path.segments.map(s => s.connectionId)
      });

      continue;
    }

    for (const edge of graph.get(path.currentId)) {
      if (path.visited.has(edge.nextStop)) continue;

      const nextVisited = new Set(path.visited);
      nextVisited.add(edge.nextStop);

      const fromName = stops.find(s => s.id === edge.from)?.name || edge.from;
      const toName = stops.find(s => s.id === edge.to)?.name || edge.to;

      const segment = {
        connectionId: edge.id,
        from: edge.from,
        to: edge.to,
        fromName,
        toName,
        mode: edge.mode,
        durationMinutes: edge.effectiveDuration,
        baseDurationMinutes: edge.durationMinutes,
        delayMinutes: edge.delayMinutes,
        fare: edge.fare,
        disrupted: edge.disrupted
      };

      queue.push({
        currentId: edge.nextStop,
        visited: nextVisited,
        segments: [...path.segments, segment],
        durationMinutes: path.durationMinutes + edge.effectiveDuration,
        fare: path.fare + edge.fare
      });
    }
  }

  if (!candidates.length) {
    return {
      success: true,
      origin,
      destination,
      preference,
      maxFare,
      budgetExceeded: false,
      routes: [],
      message: "No available route was found in the current network.",
      dataNotice: DATA_NOTICE
    };
  }

  const unique = new Map();

  for (const route of candidates) {
    const key = route.connectionIds.join(">");
    if (!unique.has(key)) unique.set(key, route);
  }

  const allRoutes = Array.from(unique.values());
  const withinBudget = maxFare === null
    ? allRoutes
    : allRoutes.filter(route => route.fare <= maxFare);

  // If no route meets the budget, return the cheapest alternatives
  // with an explicit warning rather than pretending they fit.
  const budgetExceeded = withinBudget.length === 0;
  const pool = budgetExceeded
    ? [...allRoutes].sort((a, b) =>
        a.fare - b.fare ||
        a.durationMinutes - b.durationMinutes
      ).slice(0, 3)
    : withinBudget;

  const weights = WEIGHTS[preference];

  function rangeScore(value, min, max) {
    if (max === min) return 100;
    return 100 * (1 - (value - min) / (max - min));
  }

  const minTime = Math.min(...pool.map(r => r.durationMinutes));
  const maxTime = Math.max(...pool.map(r => r.durationMinutes));
  const minFare = Math.min(...pool.map(r => r.fare));
  const maxFareInPool = Math.max(...pool.map(r => r.fare));
  const minTransfers = Math.min(...pool.map(r => r.transfers));
  const maxTransfers = Math.max(...pool.map(r => r.transfers));

  const ranked = pool.map(route => {
    const timeScore = rangeScore(route.durationMinutes, minTime, maxTime);
    const fareScore = rangeScore(route.fare, minFare, maxFareInPool);
    const transferScore = rangeScore(
      route.transfers,
      minTransfers,
      maxTransfers
    );

    const score = Math.round(
      timeScore * weights.time +
      fareScore * weights.fare +
      transferScore * weights.transfers
    );

    const explanation = [];

    if (route.durationMinutes === minTime) {
      explanation.push("Fastest estimated journey among these options");
    }

    if (route.fare === minFare) {
      explanation.push("Lowest estimated fare among these options");
    }

    if (route.transfers === minTransfers) {
      explanation.push("Fewest transport-mode changes among these options");
    }

    if (route.disruptionCount > 0) {
      explanation.push(
        "Includes a delayed connection; the delay is included in the estimate"
      );
    } else {
      explanation.push("Avoids currently reported simulated disruptions");
    }

    return {
      ...route,
      score,
      preference,
      explanation: explanation.join(". ") + ".",
      dataConfidence: "low",
      dataNotice: DATA_NOTICE
    };
  });

  ranked.sort((a, b) =>
    b.score - a.score ||
    a.durationMinutes - b.durationMinutes ||
    a.fare - b.fare
  );

  const routes = ranked.slice(0, 3).map((route, index) => ({
    ...route,
    rank: index + 1,
    recommendation:
      index === 0
        ? "Best match for your selected preference"
        : "Alternative option"
  }));

  return {
    success: true,
    origin,
    destination,
    preference,
    maxFare,
    budgetExceeded,
    routes,
    candidatesEvaluated: allRoutes.length,
    searchLimitReached: expanded >= MAX_EXPANSIONS,
    message: budgetExceeded
      ? `No route was found within ₹${maxFare}. Showing the cheapest alternatives instead.`
      : `Showing up to ${routes.length} alternatives ranked by your selected preference.`,
    dataNotice: DATA_NOTICE
  };
}

// Backward-compatible wrapper for code that expects one fastest journey.
function findFastestJourney(originId, destinationId, disruptionList = []) {
  const result = findAlternativeJourneys(
    originId,
    destinationId,
    disruptionList,
    { preference: "fastest" }
  );

  return result.routes[0] || {
    reachable: false,
    origin: result.origin,
    destination: result.destination,
    message: result.message,
    warning: DATA_NOTICE
  };
}

module.exports = {
  findFastestJourney,
  findAlternativeJourneys
};
