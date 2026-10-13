function getAiServiceUrl() {
  const url = process.env.AI_SERVICE_URL;
  if (!url || url === "undefined" || url === "null") {
    return "http://127.0.0.1:8001";
  }
  return url;
}

function getAiTimeoutMs() {
  const parsed = Number(process.env.AI_TIMEOUT_MS);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 1000;
}

const VALID_PREFERENCES = [
  "balanced",
  "cheapest",
  "fastest",
  "fewest_transfers"
];

function validatePreference(preference) {
  if (!VALID_PREFERENCES.includes(preference)) {
    throw new Error(
      "Preference must be fastest, cheapest, balanced, or fewest_transfers."
    );
  }
}

function isEligible(route, maxFare, maxTransfers) {
  // Never assume unknown fare satisfies budget.
  if (maxFare != null) {
    if (route.fare == null || !Number.isFinite(Number(route.fare)) || Number(route.fare) > maxFare) {
      return false;
    }
  }

  if (maxTransfers != null) {
    if (route.transfers == null || Number(route.transfers) > maxTransfers) {
      return false;
    }
  }

  return true;
}

function fallbackRank(routes, preference) {
  if (!routes || routes.length === 0) return [];

  const timeValues = routes.map(r => Number(r.durationMinutes) || 0);
  const transferValues = routes.map(r => Number(r.transfers) || 0);

  const pricedRoutes = routes.filter(
    r => r.fare !== null && r.fare !== undefined && Number.isFinite(Number(r.fare))
  );
  const fareValues = pricedRoutes.map(r => Number(r.fare));

  function score(value, values) {
    if (!values || values.length === 0) return 100;
    const min = Math.min(...values);
    const max = Math.max(...values);
    return max === min ? 100 : 100 * (max - value) / (max - min);
  }

  return routes
    .map(route => {
      const timeScore = score(Number(route.durationMinutes) || 0, timeValues);
      const transferScore = score(Number(route.transfers) || 0, transferValues);
      const hasFare = route.fare !== null && route.fare !== undefined && Number.isFinite(Number(route.fare));
      const fareScore = hasFare ? score(Number(route.fare), fareValues) : 0;

      let localScore;

      if (!hasFare) {
        // Unpriced schedule fallback: weight duration and transfers
        if (preference === "fewest_transfers") {
          localScore = 0.75 * transferScore + 0.25 * timeScore;
        } else if (preference === "fastest") {
          localScore = 0.80 * timeScore + 0.20 * transferScore;
        } else {
          localScore = 0.60 * timeScore + 0.40 * transferScore;
        }
      } else if (preference === "fewest_transfers") {
        localScore =
          0.70 * transferScore +
          0.20 * timeScore +
          0.10 * fareScore;
      } else {
        const weights = {
          fastest: { time: 0.70, fare: 0.10, transfers: 0.20 },
          cheapest: { time: 0.15, fare: 0.70, transfers: 0.15 },
          balanced: { time: 0.45, fare: 0.35, transfers: 0.20 }
        }[preference] || { time: 0.45, fare: 0.35, transfers: 0.20 };

        localScore =
          weights.time * timeScore +
          weights.fare * fareScore +
          weights.transfers * transferScore;
      }

      return {
        ...route,
        score: Math.round(localScore),
        preference
      };
    })
    .sort((a, b) =>
      b.score - a.score ||
      (Number(a.durationMinutes) || 0) - (Number(b.durationMinutes) || 0) ||
      (Number(a.transfers) || 0) - (Number(b.transfers) || 0) ||
      (a.fare ?? Infinity) - (b.fare ?? Infinity)
    );
}

async function rankJourneys({
  journeys = [],
  preference = "balanced",
  maxFare = null,
  maxTransfers = null
}) {
  validatePreference(preference);

  if (!Array.isArray(journeys) || journeys.length === 0) {
    return {
      success: true,
      rankingProvider: "none",
      aiRankingUsed: false,
      fallbackReason: null,
      preference,
      inputCount: 0,
      eligibleCount: 0,
      excludedCount: 0,
      routes: []
    };
  }

  // Partition candidates into priced vs unpriced
  const priced = [];
  const unpriced = [];

  for (const journey of journeys) {
    if (journey.fare !== null && journey.fare !== undefined && Number.isFinite(Number(journey.fare))) {
      priced.push(journey);
    } else {
      unpriced.push({ ...journey, fare: null });
    }
  }

  // If budget constraint is set, unpriced candidates cannot satisfy it
  const eligiblePriced = priced.filter(j => isEligible(j, maxFare, maxTransfers));
  const candidateMap = new Map();
  const seenCandidateIds = new Set();

  const candidatesForAi = eligiblePriced.map((journey, index) => {
    let routeId = String(journey.candidateId || journey.id || journey.route_id || `CANDIDATE_${index + 1}`);
    if (seenCandidateIds.has(routeId)) {
      routeId = `${routeId}_${index + 1}`;
    }
    seenCandidateIds.add(routeId);
    candidateMap.set(routeId, journey);

    // Map base travel time and delay separately to avoid double-counting delay in FastAPI
    const totalDelay = (journey.segments || []).reduce(
      (sum, s) => sum + (Number(s.delayMinutes) || 0),
      0
    );

    let baseDuration = Number(journey.durationMinutes) || 0;
    if (Array.isArray(journey.segments) && journey.segments.length > 0 && journey.segments[0].baseDurationMinutes !== undefined) {
      baseDuration = journey.segments.reduce(
        (sum, s) => sum + (Number(s.baseDurationMinutes) || Number(s.durationMinutes) || 0),
        0
      );
    } else if (totalDelay > 0) {
      baseDuration = Math.max(0, baseDuration - totalDelay);
    }

    return {
      route_id: routeId,
      travel_time_minutes: Number(baseDuration),
      expected_delay_minutes: Number(totalDelay),
      fare: Number(journey.fare),
      transfers: Math.round(Number(journey.transfers) || 0)
    };
  });

  function makeLocalFallback(reason) {
    const fallbackRoutes = fallbackRank(eligiblePriced, preference).map((route, index) => ({
      ...route,
      rank: index + 1,
      recommendation: index === 0
        ? "Best match according to Express fallback ranking"
        : "Alternative option"
    }));

    return {
      success: true,
      rankingProvider: "express-fallback",
      aiRankingUsed: false,
      fallbackReason: reason,
      preference,
      inputCount: journeys.length,
      eligibleCount: fallbackRoutes.length,
      excludedCount: journeys.length - fallbackRoutes.length,
      routes: fallbackRoutes,
      unpricedRoutes: unpriced
    };
  }

  // If there are priced eligible candidates, call FastAPI
  if (candidatesForAi.length > 0) {
    const serviceUrl = getAiServiceUrl();
    const timeoutMs = getAiTimeoutMs();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetch(`${serviceUrl}/rank-routes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          routes: candidatesForAi,
          preference,
          max_fare: maxFare,
          max_transfers: maxTransfers
        })
      });

      if (!response.ok) {
        return makeLocalFallback(`FastAPI returned HTTP ${response.status}`);
      }

      const result = await response.json();

      if (!Array.isArray(result.routes)) {
        return makeLocalFallback("FastAPI returned an invalid routes field");
      }

      const seen = new Set();
      const rankedRoutes = [];

      for (const ranked of result.routes) {
        const original = candidateMap.get(ranked.route_id);

        if (!original || seen.has(ranked.route_id)) {
          return makeLocalFallback("FastAPI returned an unknown or duplicate route ID");
        }

        const candidate = candidatesForAi.find(
          route => route.route_id === ranked.route_id
        );

        if (!isEligible(candidate, maxFare, maxTransfers)) {
          return makeLocalFallback("FastAPI returned a route outside the constraints");
        }

        if (!Number.isFinite(Number(ranked.score))) {
          return makeLocalFallback("FastAPI returned an invalid score");
        }

        seen.add(ranked.route_id);

        rankedRoutes.push({
          ...original,
          candidateId: original.candidateId || original.id || ranked.route_id,
          score: Number(ranked.score),
          preference: ranked.preference || preference,
          rank: rankedRoutes.length + 1,
          reasons: ranked.reasons || [],
          score_components: ranked.score_components || null,
          recommendation: rankedRoutes.length === 0
            ? "Best match for your selected preference"
            : "Alternative option"
        });
      }

      return {
        success: true,
        rankingProvider: "fastapi",
        aiRankingUsed: true,
        preference,
        inputCount: journeys.length,
        eligibleCount: rankedRoutes.length,
        excludedCount: journeys.length - rankedRoutes.length,
        routes: rankedRoutes,
        unpricedRoutes: unpriced,
        metadata: result.metadata || null
      };
    } catch (error) {
      return makeLocalFallback(
        error.name === "AbortError"
          ? `FastAPI request timed out (${timeoutMs}ms)`
          : `FastAPI is unavailable: ${error.message}`
      );
    } finally {
      clearTimeout(timeout);
    }
  }

  // If no candidates had verified fares to send to FastAPI
  if (priced.length > 0 && eligiblePriced.length === 0) {
    // All priced candidates violated hard constraints
    return {
      success: true,
      rankingProvider: "none",
      aiRankingUsed: false,
      fallbackReason: "All priced candidates exceeded fare or transfer constraints",
      preference,
      inputCount: journeys.length,
      eligibleCount: 0,
      excludedCount: journeys.length,
      routes: [],
      unpricedRoutes: unpriced,
      message: maxFare !== null
        ? `No candidate journey with a verified fare satisfies budget ₹${maxFare}.`
        : "No candidate journey satisfies transfer constraints."
    };
  }

  // All candidates are unpriced (static GTFS feeds without fare tables)
  if (maxFare !== null) {
    // Under a budget constraint, unknown fares cannot be presented as satisfying the budget
    return {
      success: true,
      rankingProvider: "none",
      aiRankingUsed: false,
      fallbackReason: "Candidate journeys have unknown fares; cannot verify against maxFare",
      preference,
      inputCount: journeys.length,
      eligibleCount: 0,
      excludedCount: journeys.length,
      routes: [],
      unpricedRoutes: unpriced,
      message: `No candidate journey has a verified fare to evaluate against the budget constraint of ₹${maxFare}.`
    };
  }

  // No budget constraint: filter unpriced candidates by transfer limit and rank by duration & transfers
  const eligibleUnpriced = maxTransfers !== null
    ? unpriced.filter(j => (Number(j.transfers) || 0) <= maxTransfers)
    : unpriced;

  const rankedSchedule = fallbackRank(eligibleUnpriced, preference).map((route, index) => ({
    ...route,
    rank: index + 1,
    recommendation: index === 0
      ? "Fastest scheduled option (fare unpriced in static schedule)"
      : "Alternative scheduled option"
  }));

  return {
    success: true,
    rankingProvider: "schedule-fallback",
    aiRankingUsed: false,
    fallbackReason: "Static GTFS schedule does not contain fare tables; ranked by journey duration and transfers",
    preference,
    inputCount: journeys.length,
    eligibleCount: rankedSchedule.length,
    excludedCount: journeys.length - rankedSchedule.length,
    routes: rankedSchedule,
    unpricedRoutes: []
  };
}

module.exports = {
  rankJourneys,
  fallbackRank,
  isEligible
};
