const test = require("node:test");
const assert = require("node:assert/strict");

const { rankJourneys, fallbackRank, isEligible } = require("../services/aiRankingService");

const samplePricedJourneys = [
  {
    candidateId: "C1",
    durationMinutes: 45,
    fare: 15,
    transfers: 1,
    origin: { id: "A", name: "Stop A" },
    destination: { id: "B", name: "Stop B" }
  },
  {
    candidateId: "C2",
    durationMinutes: 30,
    fare: 35,
    transfers: 0,
    origin: { id: "A", name: "Stop A" },
    destination: { id: "B", name: "Stop B" }
  },
  {
    candidateId: "C3",
    durationMinutes: 60,
    fare: 10,
    transfers: 2,
    origin: { id: "A", name: "Stop A" },
    destination: { id: "B", name: "Stop B" }
  }
];

test("isEligible correctly checks maxFare and maxTransfers", () => {
  assert.equal(isEligible({ fare: 20, transfers: 1 }, 30, 2), true);
  assert.equal(isEligible({ fare: 40, transfers: 1 }, 30, 2), false); // over budget
  assert.equal(isEligible({ fare: 20, transfers: 3 }, 30, 2), false); // over transfers
  assert.equal(isEligible({ fare: null, transfers: 1 }, 30, 2), false); // unknown fare cannot meet budget
  assert.equal(isEligible({ fare: null, transfers: 1 }, null, 2), true); // no budget constraint allows unpriced
});

test("Successful FastAPI ranking maps scores, ranks, and reasons back to original journeys", async () => {
  // Test against running FastAPI on port 8001
  const result = await rankJourneys({
    journeys: samplePricedJourneys,
    preference: "balanced"
  });

  assert.equal(result.success, true);
  assert.equal(result.rankingProvider, "fastapi");
  assert.equal(result.aiRankingUsed, true);
  assert.equal(result.routes.length, 3);

  // Each route must retain its original fields plus ranking fields
  const first = result.routes[0];
  assert.ok(first.candidateId);
  assert.ok(first.origin);
  assert.ok(first.destination);
  assert.equal(typeof first.score, "number");
  assert.equal(first.rank, 1);
  assert.ok(Array.isArray(first.reasons));
});

test("Delay mapping separates base duration and delay to avoid double counting", async () => {
  const journeysWithDelay = [
    {
      candidateId: "D1",
      durationMinutes: 45, // 30 min base + 15 min delay
      fare: 20,
      transfers: 1,
      segments: [
        { connectionId: "C1", durationMinutes: 45, baseDurationMinutes: 30, delayMinutes: 15 }
      ]
    },
    {
      candidateId: "D2",
      durationMinutes: 50,
      fare: 20,
      transfers: 1,
      segments: [
        { connectionId: "C2", durationMinutes: 50, baseDurationMinutes: 50, delayMinutes: 0 }
      ]
    }
  ];

  const result = await rankJourneys({
    journeys: journeysWithDelay,
    preference: "fastest"
  });

  assert.equal(result.success, true);
  if (result.aiRankingUsed) {
    // D1 has effective time 30+15=45; D2 has 50. D1 should rank higher
    assert.equal(result.routes[0].candidateId, "D1");
    assert.ok(result.routes[0].reasons.some(r => r.includes("delay")));
  }
});

test("Supports all four preferences (balanced, cheapest, fastest, fewest_transfers)", async () => {
  const preferences = ["balanced", "cheapest", "fastest", "fewest_transfers"];
  for (const pref of preferences) {
    const result = await rankJourneys({
      journeys: samplePricedJourneys,
      preference: pref
    });
    assert.equal(result.success, true);
    assert.equal(result.preference, pref);
    assert.equal(result.routes.length, 3);
  }
});

test("Rejects invalid preferences", async () => {
  await assert.rejects(
    () => rankJourneys({ journeys: samplePricedJourneys, preference: "invalid" }),
    /Preference must be fastest, cheapest, balanced, or fewest_transfers/
  );
});

test("Enforces hard maximum fare constraint", async () => {
  const result = await rankJourneys({
    journeys: samplePricedJourneys,
    maxFare: 20 // only C1 (₹15) and C3 (₹10) fit; C2 (₹35) is excluded
  });

  assert.equal(result.success, true);
  assert.equal(result.routes.length, 2);
  assert.ok(result.routes.every(r => r.fare <= 20));
});

test("Enforces hard maximum transfers constraint", async () => {
  const result = await rankJourneys({
    journeys: samplePricedJourneys,
    maxTransfers: 1 // only C1 (1) and C2 (0) fit; C3 (2) is excluded
  });

  assert.equal(result.success, true);
  assert.equal(result.routes.length, 2);
  assert.ok(result.routes.every(r => r.transfers <= 1));
});

test("Unknown fares with budget constraint are never treated as ₹0 and are excluded", async () => {
  const unpricedJourney = {
    candidateId: "U1",
    durationMinutes: 20,
    fare: null,
    transfers: 0
  };

  const result = await rankJourneys({
    journeys: [unpricedJourney],
    maxFare: 50
  });

  assert.equal(result.success, true);
  // Must NOT claim unpriced journey satisfies the budget
  assert.equal(result.eligibleCount, 0);
  assert.equal(result.routes.length, 0);
  assert.ok(result.unpricedRoutes.length > 0);
});

test("Unknown fares without budget constraint are preserved with fare: null under schedule fallback", async () => {
  const unpricedJourneys = [
    { candidateId: "U1", durationMinutes: 25, fare: null, transfers: 0 },
    { candidateId: "U2", durationMinutes: 40, fare: null, transfers: 1 }
  ];

  const result = await rankJourneys({
    journeys: unpricedJourneys,
    preference: "fastest"
  });

  assert.equal(result.success, true);
  assert.equal(result.aiRankingUsed, false);
  assert.equal(result.rankingProvider, "schedule-fallback");
  assert.equal(result.routes.length, 2);
  assert.equal(result.routes[0].fare, null, "Fare must remain null, never fabricated as 0");
  assert.equal(result.routes[0].candidateId, "U1", "Faster unpriced journey ranks first");
});

test("Empty candidate list returns empty result safely", async () => {
  const result = await rankJourneys({ journeys: [] });
  assert.equal(result.success, true);
  assert.equal(result.inputCount, 0);
  assert.equal(result.routes.length, 0);
});

test("Fallback occurs safely when AI service is unavailable on invalid port", async () => {
  const originalUrl = process.env.AI_SERVICE_URL;
  try {
    process.env.AI_SERVICE_URL = "http://127.0.0.1:9999"; // port with no listener

    const result = await rankJourneys({
      journeys: samplePricedJourneys,
      preference: "cheapest"
    });

    assert.equal(result.success, true);
    assert.equal(result.rankingProvider, "express-fallback");
    assert.equal(result.aiRankingUsed, false);
    assert.ok(result.fallbackReason);
    assert.equal(result.routes.length, 3);
    assert.ok(result.routes[0].score >= result.routes[1].score);
    assert.ok(result.routes[1].score >= result.routes[2].score);
  } finally {
    if (originalUrl !== undefined) {
      process.env.AI_SERVICE_URL = originalUrl;
    } else {
      delete process.env.AI_SERVICE_URL;
    }
  }
});
