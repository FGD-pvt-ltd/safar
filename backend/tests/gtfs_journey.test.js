const test = require("node:test");
const assert = require("node:assert/strict");

const { findGtfsJourneys } = require("../services/gtfsJourneyService");
const { getScheduledConnections, serviceRunsOnDate } = require("../services/gtfsScheduleService");
const { getGtfsSummary } = require("../services/gtfsImporter");

test("GTFS Datasets summary loads successfully", () => {
  const summary = getGtfsSummary();
  assert.ok(summary.cmrl, "CMRL dataset should be loaded");
  assert.ok(summary.mtc, "MTC dataset should be loaded");
  assert.ok(summary.suburbanRail, "Suburban Rail dataset should be loaded");
  assert.equal(summary.cmrl.valid, true);
  assert.equal(summary.suburbanRail.valid, true);
  assert.ok(summary.cmrl.fareRules > 0, "CMRL should have fare rules");
});

test("Service calendar validity: rejects expired services and accepts active services", () => {
  // CMRL calendar ended in 2021
  const cmrlConn2021 = getScheduledConnections("2021-06-01");
  const cmrlCount2021 = cmrlConn2021.connections.filter(c => c.source === "cmrl").length;
  assert.ok(cmrlCount2021 > 0, "CMRL should have active connections in 2021");

  const cmrlConn2026 = getScheduledConnections("2026-10-13");
  const cmrlCount2026 = cmrlConn2026.connections.filter(c => c.source === "cmrl").length;
  assert.equal(cmrlCount2026, 0, "CMRL calendar expired in 2021, should have 0 active connections in 2026");

  // Suburban rail calendar is active in 2025/2026
  const srrConn2025 = getScheduledConnections("2025-10-13");
  const srrCount2025 = srrConn2025.connections.filter(c => c.source === "suburbanRail").length;
  assert.ok(srrCount2025 > 0, "Suburban rail should be active in 2025");
});

test("Direct CMRL journey resolves with verified fare from GTFS fare rules", () => {
  // 201_1: Central Metro, 216_1: Alandur Metro (2021 calendar)
  const result = findGtfsJourneys({
    originStopId: "201_1",
    destinationStopId: "216_1",
    travelDate: "2021-06-01",
    departureAfterSeconds: 21600, // 06:00:00
    maxTransfers: 1,
    maxResults: 3
  });

  assert.equal(result.success, true);
  assert.ok(result.routes.length > 0, "Should find at least one journey between Central and Alandur");

  const journey = result.routes[0];
  assert.equal(journey.originStopId, "201_1");
  assert.equal(journey.destinationStopId, "216_1");
  assert.ok(journey.durationMinutes > 0);
  assert.ok(journey.arrivalTime > journey.departureTime || journey.arrivalTime.length > 0);
  // Central Metro (SCC) to Alandur (SAL) fare rule is F4 = ₹40
  assert.equal(journey.fare, 40, "CMRL Central to Alandur fare should be ₹40 from fare_rules.txt");
});

test("GTFS journey between identical stops returns zero duration and zero fare", () => {
  const result = findGtfsJourneys({
    originStopId: "201_1",
    destinationStopId: "201_1",
    travelDate: "2021-06-01"
  });

  assert.equal(result.success, true);
  assert.equal(result.routes.length, 1);
  assert.equal(result.routes[0].durationMinutes, 0);
  assert.equal(result.routes[0].fare, 0);
  assert.equal(result.routes[0].transfers, 0);
});

test("Enforces maximum transfers constraint in GTFS journey search", () => {
  const zeroTransfers = findGtfsJourneys({
    originStopId: "201_1",
    destinationStopId: "216_1",
    travelDate: "2021-06-01",
    departureAfterSeconds: 21600,
    maxTransfers: 0
  });

  assert.equal(zeroTransfers.success, true);
  for (const route of zeroTransfers.routes) {
    assert.equal(route.transfers, 0, "All returned routes must have 0 transfers");
  }
});

test("Rejects invalid travel date formats", () => {
  assert.throws(
    () => findGtfsJourneys({ originStopId: "A", destinationStopId: "B", travelDate: "invalid-date" }),
    /Travel date must use YYYY-MM-DD format/
  );
});
