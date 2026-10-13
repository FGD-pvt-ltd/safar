const test = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");

const app = require("../server");
const { findGtfsJourneys } = require("../services/gtfsJourneyService");
const { rankJourneys } = require("../services/aiRankingService");

const AI_URL = process.env.AI_SERVICE_URL || "http://127.0.0.1:8001";

let server;
let baseUrl;

test.before(async () => {
  // Verify FastAPI service is live on port 8001
  try {
    const res = await fetch(`${AI_URL}/health`);
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
  } catch (err) {
    throw new Error(
      `Live FastAPI AI service is required on ${AI_URL} for real GTFS verification tests.\n` +
      `Start it with: cd ai-service && .venv/bin/python -m uvicorn app.main:app --port 8001\n` +
      `Original error: ${err.message}`
    );
  }

  // Start Express on an ephemeral port
  await new Promise((resolve) => {
    server = http.createServer(app);
    server.listen(0, "127.0.0.1", () => {
      baseUrl = `http://127.0.0.1:${server.address().port}`;
      resolve();
    });
  });
});

test.after(async () => {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("Real GTFS Candidate Generation: CMRL direct and transfer routes from 2021 timetable", () => {
  const result = findGtfsJourneys({
    originStopId: "201_1", // Puratchi Thalaivar Dr.M.G.Ramachandran Central Metro
    destinationStopId: "216_1", // Arignar Anna Alandur Metro
    travelDate: "2021-06-01", // Active WD service calendar
    departureAfterSeconds: 28800, // 08:00:00
    maxTransfers: 1,
    maxResults: 5
  });

  assert.equal(result.success, true);
  assert.ok(result.routes.length >= 2, "Expected at least 2 real GTFS journeys");

  // Candidate 1: Direct route
  const direct = result.routes.find(r => r.transfers === 0);
  assert.ok(direct, "Direct GTFS journey should exist");
  assert.equal(direct.originStopId, "201_1");
  assert.equal(direct.destinationStopId, "216_1");
  assert.equal(direct.departureTime, "08:09:19");
  assert.equal(direct.arrivalTime, "08:43:23");
  assert.equal(direct.durationMinutes, 35);
  assert.equal(direct.fare, 40, "Fare must be ₹40 resolved from CMRL fare_rules.txt (SCC -> SAL)");
  assert.ok(direct.segments.length > 0);
  assert.equal(direct.segments[0].tripId, "WD0171005");
  assert.equal(direct.segments[0].routeId, "17201");

  // Candidate 2: Transfer route
  const transfer = result.routes.find(r => r.transfers === 1);
  assert.ok(transfer, "Transfer GTFS journey should exist");
  assert.equal(transfer.durationMinutes, 40);
  assert.equal(transfer.transfers, 1);
  assert.equal(transfer.fare, 40);
  const distinctTrips = new Set(transfer.segments.map(s => s.tripId));
  assert.equal(distinctTrips.size, 2, "Transfer route must use 2 distinct GTFS trips");
  assert.ok(distinctTrips.has("WD0171005"));
  assert.ok(distinctTrips.has("WD0023102"));
});

test("Real GTFS Candidates Ranked by Live FastAPI Service: Route IDs, scores, and explanations", async () => {
  const gtfs = findGtfsJourneys({
    originStopId: "201_1",
    destinationStopId: "216_1",
    travelDate: "2021-06-01",
    departureAfterSeconds: 28800,
    maxTransfers: 1,
    maxResults: 2
  });

  assert.equal(gtfs.routes.length, 2);

  const ranked = await rankJourneys({
    journeys: gtfs.routes,
    preference: "fastest"
  });

  // Verify FastAPI was the ranking provider
  assert.equal(ranked.success, true);
  assert.equal(ranked.rankingProvider, "fastapi");
  assert.equal(ranked.aiRankingUsed, true);
  assert.equal(ranked.preference, "fastest");
  assert.equal(ranked.inputCount, 2);
  assert.equal(ranked.eligibleCount, 2);
  assert.equal(ranked.excludedCount, 0);

  // Direct route (35m, 0 xfer) ranks first with score 100
  const top = ranked.routes[0];
  assert.equal(top.rank, 1);
  assert.equal(top.score, 100);
  assert.equal(top.durationMinutes, 35);
  assert.equal(top.transfers, 0);
  assert.equal(top.fare, 40);
  assert.ok(Array.isArray(top.reasons));
  assert.ok(top.reasons.length > 0);
  assert.deepEqual(top.score_components, { time: 0, fare: 0, transfers: 0 });

  // Transfer route (40m, 1 xfer) ranks second with score 15
  const second = ranked.routes[1];
  assert.equal(second.rank, 2);
  assert.equal(second.score, 15);
  assert.equal(second.durationMinutes, 40);
  assert.equal(second.transfers, 1);
  assert.deepEqual(second.score_components, { time: 70, fare: 0, transfers: 15 });

  // Verify original GTFS segments and metadata were preserved
  assert.equal(top.segments[0].tripId, "WD0171005");
  assert.equal(top.segments[0].fromStopId, "201_1");
});

test("Preferences on Real GTFS Candidates: Deterministic scoring weights verified across all 4 modes", async () => {
  const gtfs = findGtfsJourneys({
    originStopId: "201_1",
    destinationStopId: "216_1",
    travelDate: "2021-06-01",
    departureAfterSeconds: 28800,
    maxTransfers: 1,
    maxResults: 2
  });

  const expectedScores = {
    fastest: { topScore: 100, secondScore: 15, components: { time: 70, fare: 0, transfers: 15 } },
    fewest_transfers: { topScore: 100, secondScore: 20, components: { time: 20, fare: 0, transfers: 60 } },
    balanced: { topScore: 100, secondScore: 30, components: { time: 50, fare: 0, transfers: 20 } },
    cheapest: { topScore: 100, secondScore: 60, components: { time: 20, fare: 0, transfers: 20 } }
  };

  for (const [pref, expected] of Object.entries(expectedScores)) {
    const ranked = await rankJourneys({
      journeys: gtfs.routes,
      preference: pref
    });

    assert.equal(ranked.rankingProvider, "fastapi");
    assert.equal(ranked.aiRankingUsed, true);
    assert.equal(ranked.preference, pref);
    assert.equal(ranked.routes[0].score, expected.topScore, `${pref} top score should be ${expected.topScore}`);
    assert.equal(ranked.routes[1].score, expected.secondScore, `${pref} second score should be ${expected.secondScore}`);
    assert.deepEqual(ranked.routes[1].score_components, expected.components, `${pref} score components mismatch`);
  }
});

test("Real MTC Journey (Unknown Fare): Follows unknown-fare policy (never zero, excluded under budget)", async () => {
  const unpricedJourney = {
    candidateId: "MTC_TRIP_71695",
    originStopId: "5822",
    destinationStopId: "2820",
    departureTime: "04:35:00",
    arrivalTime: "04:37:00",
    durationMinutes: 2,
    transfers: 0,
    fare: null, // MTC has no fare table in GTFS
    segments: [
      { tripId: "71695", fromStopId: "5822", toStopId: "2820", durationMinutes: 2 }
    ]
  };

  // Under budget constraint: unknown fare cannot be assumed to satisfy budget
  const budgetResult = await rankJourneys({
    journeys: [unpricedJourney],
    maxFare: 50
  });
  assert.equal(budgetResult.success, true);
  assert.equal(budgetResult.eligibleCount, 0);
  assert.equal(budgetResult.routes.length, 0);
  assert.ok(budgetResult.message.includes("50"));

  // Without budget constraint: preserved as fare: null and ranked by schedule fallback
  const fallbackResult = await rankJourneys({
    journeys: [unpricedJourney],
    preference: "fastest"
  });
  assert.equal(fallbackResult.success, true);
  assert.equal(fallbackResult.rankingProvider, "schedule-fallback");
  assert.equal(fallbackResult.aiRankingUsed, false);
  assert.equal(fallbackResult.routes.length, 1);
  assert.equal(fallbackResult.routes[0].fare, null, "Fare must remain null, never converted to 0");
});

test("Express End-to-End Real GTFS Search: POST /api/gtfs/journeys/search returns AI-ranked schedule routes", async () => {
  const res = await fetch(`${baseUrl}/api/gtfs/journeys/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      originStopId: "201_1",
      destinationStopId: "216_1",
      travelDate: "2021-06-01",
      departureTime: "08:00:00",
      preference: "fastest"
    })
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.dataType, "static_gtfs_schedule");
  assert.equal(data.rankingProvider, "fastapi");
  assert.equal(data.aiRankingUsed, true);
  assert.ok(data.routes.length >= 2);

  const topRoute = data.routes[0];
  assert.equal(topRoute.fare, 40);
  assert.equal(topRoute.durationMinutes, 35);
  assert.equal(topRoute.transfers, 0);
  assert.equal(topRoute.score, 100);
  assert.ok(data.dataNotice.includes("LOW CONFIDENCE"));
});
