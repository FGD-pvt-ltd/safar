
const express = require("express");
const path = require("path");

const { stops, connections } = require("./data/network");

const {
  listDisruptions,
  setDisruption,
  clearDisruption,
  clearAllDisruptions
} = require("./services/disruptionStore");

const {
  findFastestJourney,
  findAlternativeJourneys
} = require("./services/journeyService");

const { rankJourneys } = require("./services/aiRankingService");
const { findGtfsJourneys } = require("./services/gtfsJourneyService");
const { loadAllGtfs, getGtfsSummary } = require("./services/gtfsImporter");

const app = express();
const PORT = process.env.PORT || 5000;

const DATA_NOTICE =
  "LOW CONFIDENCE: route times and fares use simulated development data, not verified live Chennai transit information.";

const GTFS_NOTICE =
  "LOW CONFIDENCE: Static schedule data from official GTFS feeds (CUMTA/CMRL/MTC/SRR). Fares apply where published; live vehicle tracking and delay updates are not available.";

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "SAFAR backend is running.",
    features: [
      "alternative routes",
      "budget filtering",
      "route preferences",
      "simulated disruption recovery",
      "recommendation explanations",
      "gtfs timetable search",
      "fastapi route ranking"
    ],
    dataConfidence: "low",
    timestamp: new Date().toISOString()
  });
});

app.get("/api/stops", (req, res) => {
  const query = String(req.query.search || "").trim().toLowerCase();

  const filtered = query
    ? stops.filter(stop =>
        stop.name.toLowerCase().includes(query) ||
        stop.id.toLowerCase().includes(query)
      )
    : stops;

  res.json({
    success: true,
    count: filtered.length,
    stops: filtered
  });
});

app.get("/api/connections", (req, res) => {
  res.json({
    success: true,
    count: connections.length,
    connections,
    dataConfidence: "low",
    dataNotice: "Connection durations and fares are illustrative mock data."
  });
});

app.get("/api/disruptions", (req, res) => {
  res.json({
    success: true,
    disruptions: listDisruptions()
  });
});

app.post("/api/disruptions", (req, res) => {
  const { connectionId, status, delayMinutes, reason } = req.body || {};

  if (!connectionId) {
    return res.status(400).json({
      success: false,
      message: "connectionId is required."
    });
  }

  if (!connections.some(connection => connection.id === connectionId)) {
    return res.status(404).json({
      success: false,
      message: "Connection not found."
    });
  }

  try {
    const disruption = setDisruption(connectionId, {
      status,
      delayMinutes,
      reason
    });

    return res.status(201).json({
      success: true,
      disruption
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.delete("/api/disruptions/:connectionId", (req, res) => {
  const removed = clearDisruption(req.params.connectionId);

  res.json({
    success: true,
    removed,
    message: removed
      ? "Disruption cleared."
      : "No disruption existed for that connection."
  });
});

app.delete("/api/disruptions", (req, res) => {
  clearAllDisruptions();

  res.json({
    success: true,
    message: "All simulated disruptions cleared."
  });
});

// --- GTFS Specific Endpoints ---

app.get("/api/gtfs/summary", (req, res) => {
  try {
    const summary = getGtfsSummary();
    res.json({
      success: true,
      dataType: "static_gtfs_schedule",
      datasets: summary,
      dataNotice: GTFS_NOTICE
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

app.get("/api/gtfs/stops", (req, res) => {
  try {
    const query = String(req.query.search || "").trim().toLowerCase();
    const datasetFilter = String(req.query.dataset || "").trim();

    const datasets = loadAllGtfs();
    const matchingStops = [];

    for (const [name, ds] of Object.entries(datasets)) {
      if (datasetFilter && datasetFilter !== name) continue;
      for (const stop of ds.stops) {
        if (!query || stop.stop_name.toLowerCase().includes(query) || stop.stop_id.toLowerCase().includes(query)) {
          matchingStops.push({
            dataset: name,
            stopId: stop.stop_id,
            stopName: stop.stop_name,
            lat: stop.stop_lat,
            lon: stop.stop_lon,
            zoneId: stop.zone_id || null
          });
        }
      }
    }

    res.json({
      success: true,
      count: matchingStops.length,
      stops: matchingStops.slice(0, 100),
      dataNotice: GTFS_NOTICE
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

function parseTimeString(timeStr) {
  if (!timeStr || typeof timeStr !== "string") return 0;
  const parts = timeStr.split(":").map(Number);
  if (parts.length >= 2 && !Number.isNaN(parts[0]) && !Number.isNaN(parts[1])) {
    return parts[0] * 3600 + parts[1] * 60 + (parts[2] || 0);
  }
  return 0;
}

function readJourneyInput(body = {}) {
  const maxFareRaw = body.maxFare ?? body.budget;
  let maxFare = null;
  if (maxFareRaw !== undefined && maxFareRaw !== null && maxFareRaw !== "") {
    const num = Number(maxFareRaw);
    if (Number.isFinite(num) && num >= 0) {
      maxFare = num;
    }
  }

  const maxTransfersRaw = body.maxTransfers;
  let maxTransfers = null;
  if (maxTransfersRaw !== undefined && maxTransfersRaw !== null && maxTransfersRaw !== "") {
    const num = Number(maxTransfersRaw);
    if (Number.isInteger(num) && num >= 0) {
      maxTransfers = num;
    }
  }

  const departureAfterSeconds = body.departureAfterSeconds !== undefined
    ? Number(body.departureAfterSeconds)
    : (body.departureTime ? parseTimeString(body.departureTime) : 0);

  return {
    originId: String(body.originId || body.originStopId || "").trim(),
    destinationId: String(body.destinationId || body.destinationStopId || "").trim(),
    preference: body.preference || "balanced",
    maxFare,
    maxTransfers,
    travelDate: body.travelDate ? String(body.travelDate).trim() : null,
    departureAfterSeconds,
    useGtfs: Boolean(body.useGtfs || body.travelDate)
  };
}

async function handleGtfsJourneySearch(input, res) {
  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId (or originStopId) and destinationId (or destinationStopId) are required."
    });
  }

  if (!input.travelDate) {
    return res.status(400).json({
      success: false,
      message: "travelDate (YYYY-MM-DD) is required for GTFS schedule searches."
    });
  }

  try {
    const gtfsResult = findGtfsJourneys({
      originStopId: input.originId,
      destinationStopId: input.destinationId,
      travelDate: input.travelDate,
      departureAfterSeconds: input.departureAfterSeconds,
      maxTransfers: input.maxTransfers ?? 3,
      maxResults: 10
    });

    if (!gtfsResult.routes || gtfsResult.routes.length === 0) {
      return res.json({
        success: true,
        dataType: "static_gtfs_schedule",
        originStopId: input.originId,
        destinationStopId: input.destinationId,
        travelDate: input.travelDate,
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        budgetExceeded: false,
        routes: [],
        candidatesEvaluated: gtfsResult.candidatesEvaluated || 0,
        searchLimitReached: gtfsResult.searchLimitReached || false,
        message: gtfsResult.message || "No scheduled journey was found.",
        dataNotice: GTFS_NOTICE,
        rankingProvider: "none",
        aiRankingUsed: false
      });
    }

    const rankedResult = await rankJourneys({
      journeys: gtfsResult.routes,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers
    });

    return res.json({
      success: true,
      dataType: "static_gtfs_schedule",
      originStopId: input.originId,
      destinationStopId: input.destinationId,
      travelDate: input.travelDate,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers,
      budgetExceeded: input.maxFare !== null && rankedResult.routes.length === 0,
      routes: rankedResult.routes.slice(0, 5),
      unpricedRoutes: rankedResult.unpricedRoutes || [],
      candidatesEvaluated: gtfsResult.candidatesEvaluated,
      searchLimitReached: gtfsResult.searchLimitReached,
      rankingProvider: rankedResult.rankingProvider,
      aiRankingUsed: rankedResult.aiRankingUsed,
      fallbackReason: rankedResult.fallbackReason || null,
      inputCount: rankedResult.inputCount,
      eligibleCount: rankedResult.eligibleCount,
      excludedCount: rankedResult.excludedCount,
      message: rankedResult.routes.length === 0
        ? (input.maxFare !== null
            ? `No scheduled journey with verified fare meets budget of ₹${input.maxFare}.`
            : "No scheduled journey satisfies constraints.")
        : `Showing ${rankedResult.routes.length} scheduled journeys ranked by ${input.preference}.`,
      dataNotice: GTFS_NOTICE
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
}

app.post("/api/gtfs/journeys/search", async (req, res) => {
  const input = readJourneyInput(req.body);
  input.useGtfs = true;
  return handleGtfsJourneySearch(input, res);
});

app.post("/api/journeys/search", async (req, res) => {
  const input = readJourneyInput(req.body);

  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  if (input.useGtfs) {
    return handleGtfsJourneySearch(input, res);
  }

  try {
    const candidateResult = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      listDisruptions(),
      {
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        returnAllCandidates: true
      }
    );

    if (!candidateResult.routes || candidateResult.routes.length === 0) {
      return res.json({
        success: true,
        origin: candidateResult.origin,
        destination: candidateResult.destination,
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        budgetExceeded: false,
        routes: [],
        candidatesEvaluated: 0,
        searchLimitReached: candidateResult.searchLimitReached || false,
        message: candidateResult.message || "No available route was found in the current network.",
        dataNotice: DATA_NOTICE,
        rankingProvider: "none",
        aiRankingUsed: false
      });
    }

    const rankedResult = await rankJourneys({
      journeys: candidateResult.routes,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers
    });

    const isBudgetExceeded = input.maxFare !== null && rankedResult.routes.length === 0;

    return res.json({
      success: true,
      origin: candidateResult.origin,
      destination: candidateResult.destination,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers,
      budgetExceeded: isBudgetExceeded,
      routes: rankedResult.routes.slice(0, 3),
      unpricedRoutes: rankedResult.unpricedRoutes || [],
      candidatesEvaluated: candidateResult.candidatesEvaluated,
      searchLimitReached: candidateResult.searchLimitReached,
      rankingProvider: rankedResult.rankingProvider,
      aiRankingUsed: rankedResult.aiRankingUsed,
      fallbackReason: rankedResult.fallbackReason || null,
      inputCount: rankedResult.inputCount,
      eligibleCount: rankedResult.eligibleCount,
      excludedCount: rankedResult.excludedCount,
      message: isBudgetExceeded
        ? `No route was found within ₹${input.maxFare}.`
        : `Showing up to ${Math.min(3, rankedResult.routes.length)} alternatives ranked by your selected preference.`,
      dataNotice: DATA_NOTICE
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.post("/api/journeys/alternatives", async (req, res) => {
  const input = readJourneyInput(req.body);

  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  if (input.useGtfs) {
    return handleGtfsJourneySearch(input, res);
  }

  try {
    const candidateResult = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      listDisruptions(),
      {
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        returnAllCandidates: true
      }
    );

    if (!candidateResult.routes || candidateResult.routes.length === 0) {
      return res.json({
        success: true,
        origin: candidateResult.origin,
        destination: candidateResult.destination,
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        budgetExceeded: false,
        routes: [],
        candidatesEvaluated: 0,
        searchLimitReached: candidateResult.searchLimitReached || false,
        message: candidateResult.message || "No available route was found in the current network.",
        dataNotice: DATA_NOTICE,
        rankingProvider: "none",
        aiRankingUsed: false
      });
    }

    const rankedResult = await rankJourneys({
      journeys: candidateResult.routes,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers
    });

    const isBudgetExceeded = input.maxFare !== null && rankedResult.routes.length === 0;

    return res.json({
      success: true,
      origin: candidateResult.origin,
      destination: candidateResult.destination,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers,
      budgetExceeded: isBudgetExceeded,
      routes: rankedResult.routes.slice(0, 3),
      unpricedRoutes: rankedResult.unpricedRoutes || [],
      candidatesEvaluated: candidateResult.candidatesEvaluated,
      searchLimitReached: candidateResult.searchLimitReached,
      rankingProvider: rankedResult.rankingProvider,
      aiRankingUsed: rankedResult.aiRankingUsed,
      fallbackReason: rankedResult.fallbackReason || null,
      inputCount: rankedResult.inputCount,
      eligibleCount: rankedResult.eligibleCount,
      excludedCount: rankedResult.excludedCount,
      message: isBudgetExceeded
        ? `No route was found within ₹${input.maxFare}.`
        : `Showing up to ${Math.min(3, rankedResult.routes.length)} alternatives ranked by your selected preference.`,
      dataNotice: DATA_NOTICE
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.post("/api/recovery/recommendations", async (req, res) => {
  const input = readJourneyInput(req.body);

  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  try {
    const disruptions = listDisruptions();

    const baselineCandidates = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      [],
      {
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        returnAllCandidates: true
      }
    );

    const recommendationCandidates = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      disruptions,
      {
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers,
        returnAllCandidates: true
      }
    );

    const [rankedBaseline, rankedRecommendation] = await Promise.all([
      rankJourneys({
        journeys: baselineCandidates.routes || [],
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers
      }),
      rankJourneys({
        journeys: recommendationCandidates.routes || [],
        preference: input.preference,
        maxFare: input.maxFare,
        maxTransfers: input.maxTransfers
      })
    ]);

    const formatJourneyResult = (cand, ranked) => ({
      success: true,
      origin: cand.origin,
      destination: cand.destination,
      preference: input.preference,
      maxFare: input.maxFare,
      maxTransfers: input.maxTransfers,
      budgetExceeded: input.maxFare !== null && ranked.routes.length === 0,
      routes: ranked.routes.slice(0, 3),
      candidatesEvaluated: cand.candidatesEvaluated || 0,
      searchLimitReached: cand.searchLimitReached || false,
      rankingProvider: ranked.rankingProvider,
      aiRankingUsed: ranked.aiRankingUsed,
      fallbackReason: ranked.fallbackReason || null,
      message: ranked.routes.length === 0
        ? (input.maxFare !== null ? `No route was found within ₹${input.maxFare}.` : "No available route was found.")
        : `Showing up to ${Math.min(3, ranked.routes.length)} alternatives.`,
      dataNotice: DATA_NOTICE
    });

    return res.json({
      success: true,
      baseline: formatJourneyResult(baselineCandidates, rankedBaseline),
      recommendation: formatJourneyResult(recommendationCandidates, rankedRecommendation),
      activeDisruptions: disruptions.length,
      rankingProvider: rankedRecommendation.rankingProvider,
      aiRankingUsed: rankedRecommendation.aiRankingUsed,
      dataNotice: DATA_NOTICE
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.use((err, req, res, next) => {
  console.error("SAFAR server error:", err.message);

  res.status(500).json({
    success: false,
    message: "An unexpected server error occurred."
  });
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`SAFAR server running at http://localhost:${PORT}`);
  });
}

module.exports = app;
