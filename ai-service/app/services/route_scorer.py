
from typing import Any


PREFERENCE_WEIGHTS = {
    "balanced": {
        "time": 0.50,
        "fare": 0.30,
        "transfers": 0.20,
    },
    "cheapest": {
        "time": 0.20,
        "fare": 0.60,
        "transfers": 0.20,
    },
    "fastest": {
        "time": 0.70,
        "fare": 0.15,
        "transfers": 0.15,
    },
    "fewest_transfers": {
        "time": 0.20,
        "fare": 0.20,
        "transfers": 0.60,
    },
}


def filter_routes(
    routes: list[dict[str, Any]],
    max_fare: float | None = None,
    max_transfers: int | None = None,
) -> list[dict[str, Any]]:
    """Filter candidate routes by optional maximum fare and transfer constraints."""
    if max_fare is not None and max_fare < 0:
        raise ValueError("max_fare cannot be negative")

    if max_transfers is not None and max_transfers < 0:
        raise ValueError("max_transfers cannot be negative")

    eligible_routes = []
    for route in routes:
        if max_fare is not None and route["fare"] > max_fare:
            continue

        if max_transfers is not None and route["transfers"] > max_transfers:
            continue

        eligible_routes.append(route)

    return eligible_routes


def score_routes(
    routes: list[dict[str, Any]],
    preference: str = "balanced",
) -> list[dict[str, Any]]:
    """Score and rank candidate routes from 0 to 100."""

    if preference not in PREFERENCE_WEIGHTS:
        raise ValueError(f"Unknown preference: {preference}")

    if not routes:
        return []

    metrics = {
        "time": "travel_time_minutes",
        "fare": "fare",
        "transfers": "transfers",
    }

    # Validate route data before scoring.
    for route in routes:
        for metric in metrics.values():
            if metric not in route:
                raise ValueError(f"Missing route field: {metric}")

            value = route[metric]

            if isinstance(value, bool) or not isinstance(value, (int, float)):
                raise ValueError(f"{metric} must be numeric")

            if value < 0:
                raise ValueError(f"{metric} cannot be negative")

    # Find the minimum and maximum for each metric.
    bounds = {}
    for metric, field in metrics.items():
        values = [route[field] for route in routes]
        bounds[metric] = (min(values), max(values))

    weights = PREFERENCE_WEIGHTS[preference]
    results = []

    for route in routes:
        total_cost = 0.0

        for metric, field in metrics.items():
            minimum, maximum = bounds[metric]

            if maximum == minimum:
                normalized_cost = 0.0
            else:
                normalized_cost = (
                    (route[field] - minimum) / (maximum - minimum)
                )

            total_cost += weights[metric] * normalized_cost

        score = round((1 - total_cost) * 100, 2)

        results.append({
            **route,
            "score": score,
            "preference": preference,
        })

    # Highest score first; route ID breaks ties consistently.
    results.sort(
        key=lambda route: (
            -route["score"],
            str(route.get("route_id", "")),
        )
    )

    return results
