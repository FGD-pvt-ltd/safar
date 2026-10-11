
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

app.listen(PORT, () => {
    console.log(`SAFAR backend running at http://localhost:${PORT}`);
});
