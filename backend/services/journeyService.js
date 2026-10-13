
const { stops, connections } = require("../data/network");

const DATA_NOTICE =
  "LOW CONFIDENCE: route times and fares use simulated development data, not verified live Chennai transit information.";

const WEIGHTS = {
  fastest: { time: 0.70, fare: 0.10, transfers: 0.20 },
  cheapest: { time: 0.15, fare: 0.70, transfers: 0.15 },
  balanced: { time: 0.45, fare: 0.35, transfers: 0.20 }
};

const VALID_PREFERENCES = [
  "fastest",
  "cheapest",
  "balanced",
  "fewest_transfers"
];

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

  if (!VALID_PREFERENCES.includes(preference)) {
    throw new Error(
      "Preference must be fastest, cheapest, balanced, or fewest_transfers."
    );
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
      disruptionCount: 0,
      connectionIds: [],
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
      candidatesEvaluated: 1,
      searchLimitReached: false,
      message: "Origin and destination are the same.",
      dataNotice: DATA_NOTICE
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

  // Best-first search over simple paths.
  // A path cannot revisit a stop.
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

    const currentPath = queue.shift();
    expanded++;

    if (currentPath.currentId === destinationId) {
      const modes = currentPath.segments.map(segment => segment.mode);
      let transfers = 0;

      for (let i = 1; i < modes.length; i++) {
        if (modes[i] !== modes[i - 1]) {
          transfers++;
        }
      }

      candidates.push({
        reachable: true,
        origin,
        destination,
        durationMinutes: currentPath.durationMinutes,
        fare: currentPath.fare,
        transfers,
        segments: currentPath.segments,
        disruptionCount: currentPath.segments.filter(
          segment => segment.disrupted
        ).length,
        connectionIds: currentPath.segments.map(
          segment => segment.connectionId
        ),
        dataConfidence: "low",
        dataNotice: DATA_NOTICE
      });

      continue;
    }

    for (const edge of graph.get(currentPath.currentId) || []) {
      if (currentPath.visited.has(edge.nextStop)) {
        continue;
      }

      const nextVisited = new Set(currentPath.visited);
      nextVisited.add(edge.nextStop);

      const fromName =
        stops.find(stop => stop.id === edge.from)?.name || edge.from;

      const toName =
        stops.find(stop => stop.id === edge.to)?.name || edge.to;

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
        segments: [...currentPath.segments, segment],
        durationMinutes:
          currentPath.durationMinutes + edge.effectiveDuration,
        fare: currentPath.fare + edge.fare
      });
    }
  }

  const unique = new Map();

  for (const route of candidates) {
    const key = route.connectionIds.join(">");
    if (!unique.has(key)) {
      unique.set(key, route);
    }
  }

  const allRoutes = Array.from(unique.values());

  if (allRoutes.length === 0) {
    return {
      success: true,
      origin,
      destination,
      preference,
      maxFare,
      budgetExceeded: false,
      routes: [],
      candidatesEvaluated: 0,
      searchLimitReached: expanded >= MAX_EXPANSIONS,
      message: "No available route was found in the current network.",
      dataNotice: DATA_NOTICE
    };
  }

  // Candidate-generation mode for external ranking services.
  // Do not apply fare filtering or local top-three ranking here.
  if (options.returnAllCandidates === true) {
    return {
      success: true,
      origin,
      destination,
      preference,
      maxFare,
      budgetExceeded: false,
      routes: allRoutes,
      candidatesEvaluated: allRoutes.length,
      searchLimitReached: expanded >= MAX_EXPANSIONS,
      message: `Generated ${allRoutes.length} candidate journeys for external ranking.`,
      dataNotice: DATA_NOTICE
    };
  }

  // Preserve the existing local behavior for callers that do not
  // explicitly request the full candidate pool.
  const withinBudget = maxFare === null
    ? allRoutes
    : allRoutes.filter(route => route.fare <= maxFare);

  const budgetExceeded = withinBudget.length === 0;

  const pool = budgetExceeded
    ? [...allRoutes]
        .sort((a, b) =>
          a.fare - b.fare ||
          a.durationMinutes - b.durationMinutes
        )
        .slice(0, 3)
    : withinBudget;

  const minTime = Math.min(...pool.map(route => route.durationMinutes));
  const maxTime = Math.max(...pool.map(route => route.durationMinutes));
  const minFare = Math.min(...pool.map(route => route.fare));
  const maxFareInPool = Math.max(...pool.map(route => route.fare));
  const minTransfers = Math.min(...pool.map(route => route.transfers));
  const maxTransfers = Math.max(...pool.map(route => route.transfers));

  function rangeScore(value, min, max) {
    if (max === min) {
      return 100;
    }

    return 100 * (1 - (value - min) / (max - min));
  }

  const ranked = pool.map(route => {
    const timeScore = rangeScore(
      route.durationMinutes,
      minTime,
      maxTime
    );

    const fareScore = rangeScore(route.fare, minFare, maxFareInPool);

    const transferScore = rangeScore(
      route.transfers,
      minTransfers,
      maxTransfers
    );

    let score;

    if (preference === "fewest_transfers") {
      // Prefer fewer transfers, then shorter duration, then lower fare.
      score =
        route.transfers === minTransfers
          ? 100
          : rangeScore(route.transfers, minTransfers, maxTransfers);

      score =
        score * 0.70 +
        timeScore * 0.20 +
        fareScore * 0.10;
    } else {
      const weights = WEIGHTS[preference];

      score = Math.round(
        timeScore * weights.time +
        fareScore * weights.fare +
        transferScore * weights.transfers
      );
    }

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
        "Includes a disrupted connection; its delay is included in the estimate"
      );
    } else {
      explanation.push("Avoids currently reported simulated disruptions");
    }

    return {
      ...route,
      score: Math.round(score),
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
    recommendation: index === 0
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
