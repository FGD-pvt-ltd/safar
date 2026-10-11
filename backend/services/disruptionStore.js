
const disruptions = new Map();

function listDisruptions() {
  return Array.from(disruptions.values());
}

function setDisruption(connectionId, details = {}) {
  const status = details.status || "delayed";
  const delayMinutes = Number(details.delayMinutes ?? 10);

  if (!["delayed", "cancelled"].includes(status)) {
    throw new Error("Status must be delayed or cancelled.");
  }

  if (
    status === "delayed" &&
    (!Number.isFinite(delayMinutes) ||
      delayMinutes < 1 ||
      delayMinutes > 240)
  ) {
    throw new Error("Delay must be between 1 and 240 minutes.");
  }

  const disruption = {
    connectionId,
    status,
    delayMinutes: status === "delayed" ? delayMinutes : 0,
    reason: details.reason || "Simulated disruption",
    source: "simulated",
    updatedAt: new Date().toISOString()
  };

  disruptions.set(connectionId, disruption);
  return disruption;
}

function clearDisruption(connectionId) {
  return disruptions.delete(connectionId);
}

function clearAllDisruptions() {
  disruptions.clear();
}

module.exports = {
  listDisruptions,
  setDisruption,
  clearDisruption,
  clearAllDisruptions
};
