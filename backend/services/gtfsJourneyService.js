
const { getConnectionIndex } = require("./gtfsConnectionIndex");

const DEFAULT_MIN_TRANSFER_SECONDS = 300;
const MAX_EXPANDED = 30000;

function findGtfsJourneys({
  originStopId,
  destinationStopId,
  travelDate,
  departureAfterSeconds = 0,
  maxTransfers = 3,
  maxResults = 5,
  minTransferSeconds = DEFAULT_MIN_TRANSFER_SECONDS
}) {
  if (
    typeof originStopId !== "string" ||
    !originStopId.trim() ||
    typeof destinationStopId !== "string" ||
    !destinationStopId.trim()
  ) {
    throw new Error("Valid origin and destination stop IDs are required.");
  }

  if (
    !Number.isInteger(departureAfterSeconds) ||
    departureAfterSeconds < 0 ||
    departureAfterSeconds > 172800
  ) {
    throw new Error("Departure time must be between 0 and 172800 seconds.");
  }

  if (
    !Number.isInteger(maxTransfers) ||
    maxTransfers < 0 ||
    maxTransfers > 10
  ) {
    throw new Error("maxTransfers must be an integer between 0 and 10.");
  }

  if (
    !Number.isInteger(maxResults) ||
    maxResults < 1 ||
    maxResults > 20
  ) {
    throw new Error("maxResults must be an integer between 1 and 20.");
  }

  if (
    !Number.isInteger(minTransferSeconds) ||
    minTransferSeconds < 0 ||
    minTransferSeconds > 3600
  ) {
    throw new Error("minTransferSeconds must be between 0 and 3600.");
  }

  const index = getConnectionIndex(travelDate);
  const adjacency = index.byDepartureStop;

  if (originStopId === destinationStopId) {
    return {
      success: true,
      dataType: "static_gtfs_schedule",
      routes: [{
        originStopId,
        destinationStopId,
        departureTime: null,
        arrivalTime: null,
        durationMinutes: 0,
        transfers: 0,
        fare: 0,
        segments: [],
        dataType: "static_gtfs_schedule"
      }],
      candidatesEvaluated: 1,
      searchLimitReached: false,
      message: "Origin and destination are the same."
    };
  }

  const queue = [{
    stopId: originStopId,
    arrivalSeconds: departureAfterSeconds,
    firstDepartureSeconds: null,
    segments: [],
    visitedStops: new Set([originStopId]),
    transfers: 0
  }];

  const results = [];
  let expanded = 0;

  while (queue.length > 0 && expanded < MAX_EXPANDED) {
    // Earliest arrival first.
    queue.sort((a, b) =>
      a.arrivalSeconds - b.arrivalSeconds ||
      a.transfers - b.transfers
    );

    const current = queue.shift();
    expanded++;

    if (current.stopId === destinationStopId) {
      const firstDeparture = current.firstDepartureSeconds;

      // Look up verified fare if all segments belong to CMRL and have published fare rules
      let fare = null;
      const isAllCmrl =
        current.segments.length > 0 &&
        current.segments.every(s => s.source === "cmrl");

      if (isAllCmrl && index.datasets && index.datasets.cmrl) {
        const cmrl = index.datasets.cmrl;
        const originStop = cmrl.stopsById.get(originStopId);
        const destStop = cmrl.stopsById.get(destinationStopId);

        if (
          originStop &&
          destStop &&
          originStop.zone_id &&
          destStop.zone_id &&
          cmrl.farePriceByRuleKey
        ) {
          const rulePrice = cmrl.farePriceByRuleKey.get(
            `${originStop.zone_id}>${destStop.zone_id}`
          );
          if (rulePrice !== undefined) {
            fare = Number(rulePrice);
          }
        }
      }

      results.push({
        originStopId,
        destinationStopId,
        departureTime: firstDeparture === null
          ? null
          : formatGtfsTime(firstDeparture),
        arrivalTime: formatGtfsTime(current.arrivalSeconds),
        durationMinutes: firstDeparture === null
          ? 0
          : Math.ceil(
              (current.arrivalSeconds - firstDeparture) / 60
            ),
        transfers: current.transfers,
        fare,
        segments: current.segments,
        dataType: "static_gtfs_schedule"
      });

      if (results.length >= maxResults) {
        break;
      }

      continue;
    }

    const connections = adjacency.get(current.stopId) || [];

    for (const connection of connections) {
      if (connection.departureSeconds < current.arrivalSeconds) {
        continue;
      }

      if (current.visitedStops.has(connection.toStopId)) {
        continue;
      }

      const previousSegment =
        current.segments[current.segments.length - 1];

      const sameTrip =
        previousSegment &&
        previousSegment.tripId === connection.tripId;

      const isTransfer = Boolean(previousSegment && !sameTrip);

      if (
        isTransfer &&
        connection.departureSeconds - current.arrivalSeconds <
          minTransferSeconds
      ) {
        continue;
      }

      const transfers = current.transfers + (isTransfer ? 1 : 0);

      if (transfers > maxTransfers) {
        continue;
      }

      const nextVisited = new Set(current.visitedStops);
      nextVisited.add(connection.toStopId);

      queue.push({
        stopId: connection.toStopId,
        arrivalSeconds: connection.arrivalSeconds,
        firstDepartureSeconds:
          current.firstDepartureSeconds === null
            ? connection.departureSeconds
            : current.firstDepartureSeconds,
        segments: [...current.segments, connection],
        visitedStops: nextVisited,
        transfers
      });
    }
  }

  results.sort((a, b) =>
    a.durationMinutes - b.durationMinutes ||
    a.transfers - b.transfers ||
    (a.fare ?? Infinity) - (b.fare ?? Infinity)
  );

  return {
    success: true,
    dataType: "static_gtfs_schedule",
    routes: results,
    candidatesEvaluated: expanded,
    searchLimitReached: queue.length > 0 && expanded >= MAX_EXPANDED,
    message: results.length
      ? "Scheduled journeys found."
      : "No scheduled journey was found for these stop IDs and travel date."
  };
}

function formatGtfsTime(seconds) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;

  return [
    String(hours).padStart(2, "0"),
    String(minutes).padStart(2, "0"),
    String(remainingSeconds).padStart(2, "0")
  ].join(":");
}

module.exports = { findGtfsJourneys };
