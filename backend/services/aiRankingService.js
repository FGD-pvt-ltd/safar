
const AI_SERVICE_URL =
  process.env.AI_SERVICE_URL || "http://127.0.0.1:8000";

const VALID_PREFERENCES = new Set([
  "balanced",
  "cheapest",
  "fastest",
  "fewest_transfers",
]);

function normalizePreference(preference) {
  return VALID_PREFERENCES.has(preference)
    ? preference
    : "balanced";
}

function passesConstraints(route, maxFare, maxTransfers) {
  if (maxFare != null && route.fare > maxFare) return false;
  if (maxTransfers != null && route.transfers > maxTransfers) {
    return false;
  }
  return true;
}

function localFallbackScore(routes, preference) {
  const weights = {
    fastest: { time: 0.7, fare: 0.1, transfers: 0.2 },
    cheapest: { time: 0.15, fare: 0.7, transfers: 0.15 },
    balanced: { time: 0.45, fare: 0.35, transfers: 0.2 },
    fewest_transfers: { time: 0.15, fare: 0.15, transfers: 0.7 },
  };

  const w = weights[preference];

  function normalized(value, values) {
    const min = Math.min(...values);
    const max = Math.max(...values);
    return max === min ? 100 : 100 * (max - value) / (max - min);
  }

  const times = routes.map(r => r.durationMinutes);
  const fares = routes.map(r => r.fare);
  const transfers = routes.map(r => r.transfers);

  return routes
    .map(route => ({
      ...route,
      score: Number((
        w.time * normalized(route.durationMinutes, times) +
        w.fare * normalized(route.fare, fares) +
        w.transfers * normalized(route.transfers, transfers)
      ).toFixed(2)),
      preference,
    }))
    .sort((a, b) => b.score - a.score);
}

async function rankJourneys({
  journeys,
  preference = "balanced",
  maxFare = null,
  maxTransfers = null,
  timeoutMs = 5000,
}) {
  const selectedPreference = normalizePreference(preference);

  // IDs remain stable within this ranking request.
  const journeyById = new Map();
  const routes = journeys.map((journey, index) => {
    const routeId = `CANDIDATE_${index + 1}`;
    journeyById.set(routeId, journey);

    return {
      route_id: routeId,
      travel_time_minutes: journey.durationMinutes,
      fare: journey.fare,
      transfers: journey.transfers,
    };
  });

  const fallback = (reason) => {
    const eligible = routes.filter(route =>
      passesConstraints(route, maxFare, maxTransfers)
    );

    const ranked = localFallbackScore(
      eligible.map(route => ({
        ...journeyById.get(route.route_id),
        candidateId: route.route_id,
      })),
      selectedPreference
    ).map((journey, index) => {
      const { candidateId, ...original } = journey;
      return {
        ...original,
        rank: index + 1,
        recommendation: index === 0
          ? "Best match according to local fallback ranking"
          : undefined,
      };
    });

    return {
      success: true,
      rankingProvider: "express-fallback",
      aiRankingUsed: false,
      fallbackReason: reason,
      preference: selectedPreference,
      inputCount: journeys.length,
      eligibleCount: eligible.length,
      excludedCount: journeys.length - eligible.length,
      routes: ranked,
    };
  };

  if (routes.length === 0) {
    return {
      success: true,
      rankingProvider: "fastapi",
      aiRankingUsed: true,
      preference: selectedPreference,
      inputCount: 0,
      eligibleCount: 0,
      excludedCount: 0,
      routes: [],
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(`${AI_SERVICE_URL}/rank-routes`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: controller.signal,
      body: JSON.stringify({
        routes,
        preference: selectedPreference,
        max_fare: maxFare,
        max_transfers: maxTransfers,
      }),
    });

    if (!response.ok) {
      return fallback(`FastAPI returned HTTP ${response.status}`);
    }

    const result = await response.json();

    if (
      !Array.isArray(result.routes) ||
      result.input_count !== undefined && result.input_count !== routes.length
    ) {
      return fallback("FastAPI response failed validation");
    }

    const seen = new Set();
    const rankedRoutes = [];

    for (const item of result.routes) {
      const original = journeyById.get(item.route_id);

      // Never return an unknown or duplicate route ID.
      if (!original || seen.has(item.route_id)) continue;

      // Independently enforce constraints on the returned routes.
      if (!passesConstraints(
        routes.find(route => route.route_id === item.route_id),
        maxFare,
        maxTransfers
      )) continue;

      if (!Number.isFinite(Number(item.score))) {
        return fallback("FastAPI returned an invalid score");
      }

      seen.add(item.route_id);
      rankedRoutes.push({
        ...original,
        score: Number(item.score),
        preference: item.preference || selectedPreference,
        rank: rankedRoutes.length + 1,
        candidateId: item.route_id,
      });
    }

    // Reject incomplete responses instead of silently hiding routes.
    if (rankedRoutes.length !== result.routes.length) {
      return fallback("FastAPI returned unknown, duplicate, or ineligible routes");
    }

    return {
      success: true,
      rankingProvider: "fastapi",
      aiRankingUsed: true,
      preference: selectedPreference,
      inputCount: result.input_count ?? routes.length,
      eligibleCount: result.eligible_count ?? rankedRoutes.length,
      excludedCount: result.excluded_count ??
        routes.length - rankedRoutes.length,
      routes: rankedRoutes,
    };
  } catch (error) {
    const reason = error.name === "AbortError"
      ? "FastAPI request timed out"
      : "FastAPI is unavailable";

    return fallback(reason);
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = { rankJourneys };
