
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

const app = express();
const PORT = process.env.PORT || 5000;

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
      "recommendation explanations"
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

function readJourneyInput(body = {}) {
  return {
    originId: body.originId || body.originStopId,
    destinationId: body.destinationId || body.destinationStopId,
    preference: body.preference || "balanced",
    maxFare: body.maxFare ?? body.budget
  };
}

app.post("/api/journeys/search", (req, res) => {
  const input = readJourneyInput(req.body);

  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  try {
    const result = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      listDisruptions(),
      {
        preference: input.preference,
        maxFare: input.maxFare
      }
    );

    return res.json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.post("/api/journeys/alternatives", (req, res) => {
  const input = readJourneyInput(req.body);

  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  try {
    const result = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      listDisruptions(),
      {
        preference: input.preference,
        maxFare: input.maxFare
      }
    );

    return res.json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.post("/api/recovery/recommendations", (req, res) => {
  const input = readJourneyInput(req.body);

  if (!input.originId || !input.destinationId) {
    return res.status(400).json({
      success: false,
      message: "originId and destinationId are required."
    });
  }

  try {
    const disruptions = listDisruptions();

    const baseline = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      [],
      {
        preference: input.preference,
        maxFare: input.maxFare
      }
    );

    const recommendation = findAlternativeJourneys(
      input.originId,
      input.destinationId,
      disruptions,
      {
        preference: input.preference,
        maxFare: input.maxFare
      }
    );

    return res.json({
      success: true,
      baseline,
      recommendation,
      activeDisruptions: disruptions.length,
      dataNotice:
        "All routes, fares and durations are simulated development data."
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

app.listen(PORT, () => {
  console.log(`SAFAR server running at http://localhost:${PORT}`);
});
