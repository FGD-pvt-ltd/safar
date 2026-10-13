const test = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");

const app = require("../server");
const { setDisruption, clearAllDisruptions } = require("../services/disruptionStore");

let server;
let baseUrl;

test.before(async () => {
  await new Promise((resolve) => {
    server = http.createServer(app);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      baseUrl = `http://127.0.0.1:${address.port}`;
      resolve();
    });
  });
});

test.after(async () => {
  clearAllDisruptions();
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("GET /api/health returns health status and features", async () => {
  const res = await fetch(`${baseUrl}/api/health`);
  assert.equal(res.status, 200);

  const data = await res.json();
  assert.equal(data.success, true);
  assert.ok(Array.isArray(data.features));
  assert.ok(data.features.includes("fastapi route ranking"));
  assert.ok(data.features.includes("gtfs timetable search"));
});

test("GET /api/gtfs/summary returns loaded GTFS dataset counts", async () => {
  const res = await fetch(`${baseUrl}/api/gtfs/summary`);
  assert.equal(res.status, 200);

  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.dataType, "static_gtfs_schedule");
  assert.ok(data.datasets.cmrl);
  assert.ok(data.datasets.mtc);
  assert.ok(data.datasets.suburbanRail);
  assert.ok(data.datasets.cmrl.stops > 0);
  assert.ok(data.dataNotice);
});

test("GET /api/gtfs/stops searches stops by name", async () => {
  const res = await fetch(`${baseUrl}/api/gtfs/stops?search=central`);
  assert.equal(res.status, 200);

  const data = await res.json();
  assert.equal(data.success, true);
  assert.ok(data.count > 0);
  assert.ok(data.stops.length > 0);
  assert.ok(data.stops.some(s => s.stopName.toLowerCase().includes("central")));
});

test("POST /api/journeys/search with simulated network ranks via live FastAPI service", async () => {
  const res = await fetch(`${baseUrl}/api/journeys/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      originId: "TAMBARAM",
      destinationId: "CENTRAL",
      preference: "balanced"
    })
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.rankingProvider, "fastapi");
  assert.equal(data.aiRankingUsed, true);
  assert.ok(data.routes.length > 0);

  const firstRoute = data.routes[0];
  assert.equal(firstRoute.rank, 1);
  assert.equal(typeof firstRoute.score, "number");
  assert.ok(Array.isArray(firstRoute.reasons));
  assert.ok(Array.isArray(firstRoute.segments));
  assert.ok(firstRoute.origin);
  assert.ok(firstRoute.destination);
  assert.ok(data.dataNotice);
});

test("POST /api/journeys/search supports all four preferences with FastAPI ranking", async () => {
  const preferences = ["balanced", "cheapest", "fastest", "fewest_transfers"];
  for (const pref of preferences) {
    const res = await fetch(`${baseUrl}/api/journeys/search`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        originId: "TAMBARAM",
        destinationId: "CENTRAL",
        preference: pref
      })
    });

    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.equal(data.preference, pref);
    assert.equal(data.rankingProvider, "fastapi");
    assert.equal(data.aiRankingUsed, true);
    assert.ok(data.routes.length > 0);
  }
});

test("POST /api/journeys/search handles disruption delay and reports delay reasons", async () => {
  try {
    // Set 15-minute delay on connection C1 (TAMBARAM -> GUINDY bus)
    setDisruption("C1", {
      status: "delayed",
      delayMinutes: 15,
      reason: "Road construction near Guindy"
    });

    const res = await fetch(`${baseUrl}/api/journeys/search`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        originId: "TAMBARAM",
        destinationId: "CENTRAL",
        preference: "fastest"
      })
    });

    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.equal(data.rankingProvider, "fastapi");

    // Any route utilizing C1 should reflect delay in reasons without double counting
    const delayedRoute = data.routes.find(r =>
      r.segments && r.segments.some(s => s.connectionId === "C1")
    );
    if (delayedRoute) {
      assert.ok(delayedRoute.reasons.some(reason => reason.includes("delay")));
    }
  } finally {
    clearAllDisruptions();
  }
});

test("POST /api/journeys/search enforces hard budget limit (budgetExceeded = true)", async () => {
  const res = await fetch(`${baseUrl}/api/journeys/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      originId: "TAMBARAM",
      destinationId: "CENTRAL",
      maxFare: 5 // Cheapest route in simulated network is ₹15
    })
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.budgetExceeded, true);
  assert.equal(data.routes.length, 0);
  assert.ok(data.message.includes("₹5"));
});

test("POST /api/journeys/search falls back cleanly to Express ranking when AI service is unavailable", async () => {
  const originalUrl = process.env.AI_SERVICE_URL;
  try {
    process.env.AI_SERVICE_URL = "http://127.0.0.1:9999"; // port with no listener

    const res = await fetch(`${baseUrl}/api/journeys/search`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        originId: "TAMBARAM",
        destinationId: "CENTRAL",
        preference: "fastest"
      })
    });

    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.equal(data.rankingProvider, "express-fallback");
    assert.equal(data.aiRankingUsed, false);
    assert.ok(data.fallbackReason);
    assert.ok(data.routes.length > 0);
    assert.equal(data.routes[0].rank, 1);
  } finally {
    if (originalUrl !== undefined) {
      process.env.AI_SERVICE_URL = originalUrl;
    } else {
      delete process.env.AI_SERVICE_URL;
    }
  }
});

test("POST /api/gtfs/journeys/search finds CMRL schedule journey, resolves ₹40 fare, and ranks via AI", async () => {
  const res = await fetch(`${baseUrl}/api/gtfs/journeys/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      originStopId: "201_1", // Chennai Central Metro
      destinationStopId: "216_1", // Alandur Metro
      travelDate: "2021-06-01",
      departureTime: "08:00:00",
      preference: "fastest"
    })
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.dataType, "static_gtfs_schedule");
  assert.ok(data.routes.length > 0);

  const top = data.routes[0];
  assert.equal(top.fare, 40, "Direct CMRL Central-to-Alandur journey must have verified ₹40 fare");
  assert.equal(data.rankingProvider, "fastapi");
  assert.equal(data.aiRankingUsed, true);
  assert.equal(typeof top.score, "number");
  assert.ok(Array.isArray(top.reasons));
});

test("POST /api/journeys/search with useGtfs flag searches GTFS schedules", async () => {
  const res = await fetch(`${baseUrl}/api/journeys/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      originId: "201_1",
      destinationId: "216_1",
      travelDate: "2021-06-01",
      useGtfs: true
    })
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.dataType, "static_gtfs_schedule");
  assert.ok(data.routes.length > 0);
});
