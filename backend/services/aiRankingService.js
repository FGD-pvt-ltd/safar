
const AI_SERVICE_URL =
  process.env.AI_SERVICE_URL || "http://127.0.0.1:8001";

const VALID_PREFERENCES = [
  "balanced",
  "cheapest",
  "fastest",
  "fewest_transfers"
];

function validatePreference(preference) {
  if (!VALID_PREFERENCES.includes(preference)) {
    throw new Error("Invalid journey preference.");
  }
}

function isEligible(route, maxFare, maxTransfers) {
  if (maxFare != null && route.fare > maxFare) return false;
  if (maxTransfers != null && route.transfers > maxTransfers) return false;
  return true;
}

function fallbackRank(routes, preference) {
  const timeValues = routes.map(r => r.durationMinutes);
  const fareValues = routes.map(r => r.fare);
  const transferValues = routes.map(r => r.transfers);

  function score(value, values) {
    const min = Math.min(...values);
    const max = Math.max(...values);
    return max === min ? 100 : 100 * (max - value) / (max - min);
  }

  return routes
    .map(route => {
      let localScore;

      if (preference === "fewest_transfers") {
        localScore =
          0.70 * score(route.transfers, transferValues) +
          0.20 * score(route.durationMinutes, timeValues) +
          0.10 * score(route.fare, fareValues);
      } else {
        const weights = {
          fastest: { time: 0.70, fare: 0.10, transfers: 0.20 },
          cheapest: { time: 0.15, fare: 0.70, transfers: 0.15 },
          balanced: { time: 0.45, fare: 0.35, transfers: 0.20 }
        }[preference];

        localScore =
          weights.time * score(route.durationMinutes, timeValues) +
          weights.fare * score(route.fare, fareValues) +
          weights.transfers * score(route.transfers, transferValues);
      }

      return { ...route, score: Math.round(localScore), preference };
    })
    .sort((a, b) =>
      b.score - a.score ||
      a.durationMinutes - b.durationMinutes ||
      a.fare - b.fare
    );
}

async function rankJourneys({
  journeys,
  preference = "balanced",
  maxFare = null,
  maxTransfers = null
}) {
  validatePreference(preference);

  const candidateMap = new Map();

  const candidates = journeys.map((journey, index) => {
    const routeId = `CANDIDATE_${index + 1}`;

    candidateMap.set(routeId, journey);

    return {
      route_id: routeId,
      travel_time_minutes: journey.durationMinutes,
      fare: journey.fare,
      transfers: journey.transfers
    };
  });

  const localEligible = candidates.filter(candidate =>
    isEligible(candidate, maxFare, maxTransfers)
  );

  function fallback(reason) {
    const routes = fallbackRank(
      localEligible.map(candidate => ({
        ...candidateMap.get(candidate.route_id),
        candidateId: candidate.route_id
      })),
      preference
    ).map((route, index) => ({
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
      inputCount: candidates.length,
      eligibleCount: routes.length,
      excludedCount: candidates.length - routes.length,
      routes
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);

  try {
    const response = await fetch(`${AI_SERVICE_URL}/rank-routes`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: controller.signal,
      body: JSON.stringify({
        routes: candidates,
        preference,
        max_fare: maxFare,
        max_transfers: maxTransfers
      })
    });

    if (!response.ok) {
      return fallback(`FastAPI returned HTTP ${response.status}`);
    }

    const result = await response.json();

    if (!Array.isArray(result.routes)) {
      return fallback("FastAPI returned an invalid routes field");
    }

    const seen = new Set();
    const rankedRoutes = [];

    for (const ranked of result.routes) {
      const original = candidateMap.get(ranked.route_id);

      if (!original || seen.has(ranked.route_id)) {
        return fallback("FastAPI returned an unknown or duplicate route ID");
      }

      const candidate = candidates.find(
        route => route.route_id === ranked.route_id
      );

      if (!isEligible(candidate, maxFare, maxTransfers)) {
        return fallback("FastAPI returned a route outside the constraints");
      }

      if (!Number.isFinite(Number(ranked.score))) {
        return fallback("FastAPI returned an invalid score");
      }

      seen.add(ranked.route_id);

      rankedRoutes.push({
        ...original,
        candidateId: ranked.route_id,
        score: Number(ranked.score),
        preference: ranked.preference || preference,
        rank: rankedRoutes.length + 1,
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
      inputCount: result.input_count ?? candidates.length,
      eligibleCount: result.eligible_count ?? rankedRoutes.length,
      excludedCount: result.excluded_count ??
        candidates.length - rankedRoutes.length,
      routes: rankedRoutes
    };
  } catch (error) {
    return fallback(
      error.name === "AbortError"
        ? "FastAPI request timed out"
        : "FastAPI is unavailable"
    );
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = { rankJourneys };
