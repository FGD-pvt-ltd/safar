"""Deterministic, constraint-aware ranking for backend-generated journeys."""
from __future__ import annotations

from typing import Any

PREFERENCE_WEIGHTS: dict[str, dict[str, float]] = {
    "balanced": {"time": 0.50, "fare": 0.30, "transfers": 0.20},
    "cheapest": {"time": 0.20, "fare": 0.60, "transfers": 0.20},
    "fastest": {"time": 0.70, "fare": 0.15, "transfers": 0.15},
    "fewest_transfers": {"time": 0.20, "fare": 0.20, "transfers": 0.60},
}
OPTIONAL_WEIGHTS = {"reliability": 0.10, "disruption": 0.05}


def _number(route: dict[str, Any], field: str) -> float:
    value = route.get(field)
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{field} must be numeric")
    if value < 0:
        raise ValueError(f"{field} cannot be negative")
    return float(value)


def exclusion_reason(route: dict[str, Any], max_fare: float | None, max_transfers: int | None) -> str | None:
    if route.get("is_available") is False:
        return "Journey marked unavailable by the route-discovery backend"
    if route.get("cancelled") is True:
        return "Journey or a required connection is cancelled"
    if max_fare is not None and _number(route, "fare") > max_fare:
        return f"Fare {route['fare']} exceeds max_fare {max_fare}"
    if max_transfers is not None and route["transfers"] > max_transfers:
        return f"Transfers {route['transfers']} exceeds max_transfers {max_transfers}"
    return None


def filter_routes(routes: list[dict[str, Any]], max_fare: float | None = None,
                  max_transfers: int | None = None) -> list[dict[str, Any]]:
    """Return only candidates that pass hard constraints; never relax limits."""
    if max_fare is not None and (isinstance(max_fare, bool) or max_fare < 0):
        raise ValueError("max_fare cannot be negative")
    if max_transfers is not None and (isinstance(max_transfers, bool) or max_transfers < 0):
        raise ValueError("max_transfers cannot be negative")
    eligible = []
    for route in routes:
        if exclusion_reason(route, max_fare, max_transfers) is None:
            eligible.append(route)
    return eligible


def _normalise_cost(value: float, minimum: float, maximum: float) -> float:
    if maximum == minimum:
        return 0.0
    return (value - minimum) / (maximum - minimum)


def score_routes(routes: list[dict[str, Any]], preference: str = "balanced") -> list[dict[str, Any]]:
    """Score 0–100 relative to supplied eligible candidates; scores aren't probabilities."""
    if preference not in PREFERENCE_WEIGHTS:
        raise ValueError(f"Unknown preference: {preference}")
    if not routes:
        return []

    # Keep the old required fields, and validate here too for direct service callers.
    prepared: list[dict[str, Any]] = []
    for original in routes:
        route = dict(original)
        for field in ("travel_time_minutes", "fare", "transfers"):
            _number(route, field)
        if not isinstance(route.get("route_id"), str) or not route["route_id"].strip():
            raise ValueError("route_id must be a non-empty string")
        if not isinstance(route["transfers"], int) or isinstance(route["transfers"], bool):
            raise ValueError("transfers must be an integer")
        if "expected_delay_minutes" in route and route["expected_delay_minutes"] is not None:
            _number(route, "expected_delay_minutes")
        if "reliability" in route and route["reliability"] is not None:
            reliability = route["reliability"]
            if isinstance(reliability, bool) or not isinstance(reliability, (int, float)) or not 0 <= reliability <= 1:
                raise ValueError("reliability must be between 0 and 1")
        if "disruption_severity" in route and route["disruption_severity"] is not None:
            severity = route["disruption_severity"]
            if isinstance(severity, bool) or not isinstance(severity, (int, float)) or not 0 <= severity <= 1:
                raise ValueError("disruption_severity must be between 0 and 1")
        prepared.append(route)

    has_reliability = any(r.get("reliability") is not None for r in prepared)
    has_disruption = any(r.get("disruption_severity") is not None for r in prepared)
    base_weights = dict(PREFERENCE_WEIGHTS[preference])
    active_optional = {}
    if has_reliability:
        active_optional["reliability"] = OPTIONAL_WEIGHTS["reliability"]
    if has_disruption:
        active_optional["disruption"] = OPTIONAL_WEIGHTS["disruption"]
    base_scale = 1.0 - sum(active_optional.values())
    weights = {k: v * base_scale for k, v in base_weights.items()}
    weights.update(active_optional)

    metric_values: dict[str, list[float]] = {
        "time": [float(r["travel_time_minutes"]) + float(r.get("expected_delay_minutes") or 0) for r in prepared],
        "fare": [float(r["fare"]) for r in prepared],
        "transfers": [float(r["transfers"]) for r in prepared],
    }
    if has_reliability:
        # Missing reliability is unknown, not perfect: assign neutral cost 0.5.
        metric_values["reliability"] = [1.0 - float(r["reliability"]) if r.get("reliability") is not None else 0.5 for r in prepared]
    if has_disruption:
        metric_values["disruption"] = [float(r["disruption_severity"]) if r.get("disruption_severity") is not None else 0.5 for r in prepared]

    bounds = {name: (min(values), max(values)) for name, values in metric_values.items()}
    results = []
    for route in prepared:
        effective = {
            "time": float(route["travel_time_minutes"]) + float(route.get("expected_delay_minutes") or 0),
            "fare": float(route["fare"]),
            "transfers": float(route["transfers"]),
        }
        if has_reliability:
            effective["reliability"] = 1.0 - float(route["reliability"]) if route.get("reliability") is not None else 0.5
        if has_disruption:
            effective["disruption"] = float(route["disruption_severity"]) if route.get("disruption_severity") is not None else 0.5
        costs = {m: _normalise_cost(v, *bounds[m]) for m, v in effective.items()}
        score = round(max(0.0, min(100.0, (1.0 - sum(weights[m] * costs[m] for m in weights)) * 100)), 2)
        contributions = sorted(((m, weights[m] * costs[m]) for m in weights), key=lambda item: (-item[1], item[0]))
        reasons = []
        explainable_metrics = ["time", "fare", "transfers"]
        if route.get("reliability") is not None:
            explainable_metrics.append("reliability")
        if route.get("disruption_severity") is not None:
            explainable_metrics.append("disruption")
        best_metric = min(explainable_metrics, key=lambda m: (costs[m], m))
        labels = {"time": "lower expected journey time", "fare": "lower fare", "transfers": "fewer transfers", "reliability": "higher reported reliability", "disruption": "lower reported disruption severity"}
        reasons.append(f"Ranks well for {labels[best_metric]}.")
        if route.get("expected_delay_minutes") is not None and route["expected_delay_minutes"] > 0:
            reasons.append(f"Includes {route['expected_delay_minutes']} minutes of reported expected delay.")
        if route.get("disruption_severity") is not None and route["disruption_severity"] > 0:
            reasons.append("A reported disruption penalty is included.")
        if route.get("reliability") is None and has_reliability:
            reasons.append("Reliability is unavailable for this candidate; a neutral penalty was used.")
        results.append({**route, "score": score, "preference": preference, "reasons": reasons,
                        "score_components": {m: round(weights[m] * costs[m] * 100, 2) for m in weights}})

    results.sort(key=lambda r: (-r["score"], str(r["route_id"])))
    for rank, route in enumerate(results, start=1):
        route["rank"] = rank
    return results
