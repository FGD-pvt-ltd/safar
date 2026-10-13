# SAFAR AI route-ranking contract

## Responsibility boundary

The Express backend owns origin/destination resolution, graph search, timetable/fare derivation, GTFS parsing, transfer counting, cancellations, and the candidate journey set. FastAPI ranks only the candidates supplied to it. It must never synthesize a stop, leg, fare, timetable, or connection.

## Request: `POST /rank-routes`

Legacy required fields remain unchanged:

```json
{
  "routes": [
    {"route_id":"metro_17", "travel_time_minutes":28.0, "fare":40.0, "transfers":1}
  ],
  "preference":"balanced",
  "max_fare":80.0,
  "max_transfers":2
}
```

`preference` is one of `balanced`, `cheapest`, `fastest`, `fewest_transfers`. Fare/time must be finite, non-negative numbers; transfers must be a non-negative integer. IDs must be unique in a request. Up to 500 candidates per request are accepted.

Optional additive fields per route:
- `expected_delay_minutes`: non-negative delay estimate, only when backed by a feed or explicit simulation.
- `reliability`: measured normalized value from 0 to 1. Do not invent it from schedule-only data.
- `disruption_severity`: supplied normalized severity 0 to 1, with provenance managed by backend.
- `cancelled` or `is_available:false`: hard-exclude candidate.
- Other backend fields such as `legs`, `agency`, `departure_time`, `arrival_time`, `source`, and `data_timestamp` are accepted and preserved.

`max_fare` and `max_transfers` are hard inclusive limits; the AI never relaxes them. If no candidate passes, `routes` is empty and `excluded` explains why. Invalid request data returns FastAPI 422 with validation detail.

## Response

Legacy fields `preference`, `input_count`, `eligible_count`, `excluded_count`, and `routes` remain. Additions: `excluded` records with `route_id`/`reason`, response `metadata`, and per-route `rank`, `score`, `reasons`, and `score_components`. Score is a deterministic 0–100 comparison against this request's eligible candidates; it is not a probability and scores should not be compared across different candidate sets.

## Optional metrics

Reported delay is added to travel time. Reliability and disruption severity only affect ranking when at least one candidate supplies that metric; missing values receive a neutral normalized penalty rather than being treated as perfect. These values are only as trustworthy as the backend's source and timestamp.

## Backend fallback

Node should set a short request timeout. If FastAPI times out, returns non-2xx, or cannot be reached, backend must return the original feasible candidates in deterministic baseline order (or its existing ranking), with explicit fields such as `ranking_source:"backend_fallback"`, `ai_ranking_available:false`, and a user-safe reason. The fallback must apply the same fare/transfer/cancellation constraints; never return a candidate rejected by the user's hard limits. Do not label fallback results as AI-ranked.

## Integration test payload

```json
{
  "routes": [
    {"route_id":"metro_fast", "travel_time_minutes":24.0, "fare":50.0, "transfers":1, "source":"static_gtfs", "data_timestamp":"2026-10-13T12:00:00Z"},
    {"route_id":"bus_cheap", "travel_time_minutes":48.0, "fare":20.0, "transfers":0, "source":"static_gtfs"},
    {"route_id":"delayed_combo", "travel_time_minutes":28.0, "expected_delay_minutes":15.0, "fare":35.0, "transfers":1, "reliability":0.6, "disruption_severity":0.7, "source":"backend_disruption_feed"}
  ],
  "preference":"balanced",
  "max_fare":60.0,
  "max_transfers":2
}
```

## Chennai source-status policy (checked 2026-10-13)

- **Static schedules:** CUMTA's Transit Data Chennai portal advertises downloadable static GTFS datasets for MTC, Metro, and suburban rail. Validate each downloaded archive's `feed_info.txt`/calendar range and source timestamp before calling it current. [CUMTA portal](https://opendata.cumta.org/).
- **MTC schedule:** MTC's official site publishes bus timing and route information, with pages showing schedule update dates; the site also advertises live-tracking functionality. That establishes an official user-facing feature, **not a verified public developer API or an accessible GTFS-Realtime feed**. [MTC official site](https://mtcbus.tn.gov.in/Home).
- **CMRL schedule:** CMRL publishes an official timetable and official journey planner. This does not prove a public GTFS-Realtime vehicle-position or trip-update endpoint. [CMRL timetable](https://wcag.chennaimetrorail.org/time-table/) · [CMRL journey planner](https://travelplanner.chennaimetrorail.org/).
- **Suburban rail:** CUMTA lists suburban rail static data; no publicly documented official live vehicle-position/GTFS-Realtime endpoint was verified in this audit.
- **Live arrivals, positions, alerts/cancellations:** treat as unavailable unless backend has a documented source URL, successful recent fetch, parse success, and timestamp/freshness check. Do not infer live data from static GTFS. Label manually entered or synthetic disruption records as `simulated`/`manual` and do not blend them silently with official live status.

No paid API or LLM is required by this service.
