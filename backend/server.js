
const express = require("express");

const app = express();
const PORT = 5000;

// Allow the server to read JSON request bodies
app.use(express.json());

// First SAFAR API endpoint
app.get("/", (req, res) => {
    res.json({
        project: "SAFAR",
        message: "SAFAR backend is running!",
        status: "success"
    });
});

// Health-check endpoint
app.get("/api/health", (req, res) => {
    res.json({
        status: "healthy",
        service: "SAFAR backend"
    });
});


const { findFastestJourney } = require("./services/journeyService");

app.post("/api/journeys/search", (req, res) => {
  try {
    const { originStopId, destinationStopId } = req.body || {};

    if (
      typeof originStopId !== "string" ||
      typeof destinationStopId !== "string" ||
      !originStopId.trim() ||
      !destinationStopId.trim()
    ) {
      return res.status(400).json({
        success: false,
        message: "originStopId and destinationStopId are required."
      });
    }

    const journey = findFastestJourney(
      originStopId.trim().toUpperCase(),
      destinationStopId.trim().toUpperCase()
    );

    if (!journey) {
      return res.status(404).json({
        success: false,
        message: "No journey found between these stops."
      });
    }

    return res.status(200).json({
      success: true,
      data: journey
    });
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message:
        error.statusCode === 400
          ? error.message
          : "Unable to calculate journey."
    });
  }
});


app.listen(PORT, () => {
    console.log(`SAFAR backend running at http://localhost:${PORT}`);
});
