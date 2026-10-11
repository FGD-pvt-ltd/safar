
const express = require("express");
const path = require("path");

const { stops, connections } = require("./data/network");

const {
  listDisruptions,
  setDisruption,
  clearDisruption,
  clearAllDisruptions
} = require("./services/disruptionStore");

const { findFastestJourney } = require("./services/journeyService");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "SAFAR backend is running.",
    timestamp: new Date().toISOString()
  });
});

app.get("/api/stops", (req, res) => {
  const query = String(req.query.search || "").trim().toLowerCase();

  const result = query
    ? stops.filter(stop =>
        stop.name.toLowerCase().includes(query) ||
        stop.id.toLowerCase().includes(query)
      )
    : stops;

  res.json({ success: true, count: result.length, stops: result });
});

app.get("/api/connections", (req, res) => {
  res.json({
    success: true,
    count: connections.length,
    connections
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

    res.status(201).json({ success: true, disruption });
  } catch (error) {
    res.status(400).json({
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

app.post("/api/journeys/search", (req, res) => {
  const { originId, destinationId } = req.body || {};

  if (!originId || !destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  try {
    const journey = findFastestJourney(
      originId,
      destinationId,
      listDisruptions()
    );

    res.json({ success: true, journey });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.post("/api/recovery/recommendations", (req, res) => {
  const { originId, destinationId } = req.body || {};

  if (!originId || !destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  try {
    const baseline = findFastestJourney(originId, destinationId, []);
    const current = findFastestJourney(
      originId,
      destinationId,
      listDisruptions()
    );

    const timeSaved =
      baseline.reachable !== false && current.reachable !== false
        ? baseline.durationMinutes - current.durationMinutes
        : null;

    res.json({
      success: true,
      baseline,
      recommendation: current,
      comparison: {
        baselineMinutes: baseline.durationMinutes ?? null,
        recommendedMinutes: current.durationMinutes ?? null,
        timeDifferenceMinutes:
          baseline.reachable !== false && current.reachable !== false
            ? current.durationMinutes - baseline.durationMinutes
            : null,
        message:
          current.reachable === false
            ? "No route is available in the current sample network."
            : listDisruptions().length
              ? "Route recalculated using current simulated disruptions."
              : "No active disruptions. Showing the fastest sample route."
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, () => {
  console.log(`SAFAR server running at http://localhost:${PORT}`);
});
