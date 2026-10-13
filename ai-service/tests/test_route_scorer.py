
import pytest
from pydantic import ValidationError

from app.main import RouteCandidate, RouteRankingRequest, rank_routes
from app.services.route_scorer import filter_routes, score_routes


@pytest.fixture
def routes():
    return [
        {
            "route_id": "A",
            "travel_time_minutes": 70,
            "fare": 30,
            "transfers": 2,
        },
        {
            "route_id": "B",
            "travel_time_minutes": 55,
            "fare": 45,
            "transfers": 1,
        },
        {
            "route_id": "C",
            "travel_time_minutes": 40,
            "fare": 70,
            "transfers": 0,
        },
    ]


@pytest.fixture
def candidate_routes():
    return [
        RouteCandidate(
            route_id="A",
            travel_time_minutes=70,
            fare=30,
            transfers=2,
        ),
        RouteCandidate(
            route_id="B",
            travel_time_minutes=55,
            fare=45,
            transfers=1,
        ),
        RouteCandidate(
            route_id="C",
            travel_time_minutes=40,
            fare=70,
            transfers=0,
        ),
    ]


def test_fastest_preference(routes):
    result = score_routes(routes, "fastest")
    assert result[0]["route_id"] == "C"


def test_cheapest_preference(routes):
    result = score_routes(routes, "cheapest")
    assert result[0]["route_id"] == "A"


def test_fewest_transfers_preference(routes):
    result = score_routes(routes, "fewest_transfers")
    assert result[0]["route_id"] == "C"


def test_empty_routes():
    assert score_routes([]) == []


def test_unknown_preference(routes):
    with pytest.raises(ValueError):
        score_routes(routes, "luxury")


def test_negative_fare_is_rejected(routes):
    routes[0]["fare"] = -10

    with pytest.raises(ValueError):
        score_routes(routes)


def test_scores_are_between_zero_and_one_hundred(routes):
    result = score_routes(routes)

    assert all(0 <= route["score"] <= 100 for route in result)
    assert result == sorted(
        result, key=lambda route: (-route["score"], route["route_id"])
    )


# --- Tests for filter_routes ---


def test_filter_routes_exceeding_fare_limit(routes):
    filtered = filter_routes(routes, max_fare=50)
    route_ids = [route["route_id"] for route in filtered]

    assert route_ids == ["A", "B"]
    assert all(route["fare"] <= 50 for route in filtered)


def test_filter_routes_exceeding_transfer_limit(routes):
    filtered = filter_routes(routes, max_transfers=1)
    route_ids = [route["route_id"] for route in filtered]

    assert route_ids == ["B", "C"]
    assert all(route["transfers"] <= 1 for route in filtered)


def test_filter_routes_exactly_at_limits(routes):
    filtered = filter_routes(routes, max_fare=45, max_transfers=1)

    assert len(filtered) == 1
    assert filtered[0]["route_id"] == "B"
    assert filtered[0]["fare"] == 45
    assert filtered[0]["transfers"] == 1


def test_filter_routes_no_eligible_routes(routes):
    filtered = filter_routes(routes, max_fare=20)

    assert filtered == []


def test_filter_routes_without_constraints(routes):
    filtered = filter_routes(routes)

    assert len(filtered) == len(routes)
    assert [r["route_id"] for r in filtered] == ["A", "B", "C"]


def test_filter_routes_negative_constraints_rejected(routes):
    with pytest.raises(ValueError):
        filter_routes(routes, max_fare=-5)

    with pytest.raises(ValueError):
        filter_routes(routes, max_transfers=-1)


# --- Tests for rank-routes endpoint ---


def test_rank_routes_exceeding_fare_limit(candidate_routes):
    request = RouteRankingRequest(
        routes=candidate_routes,
        preference="cheapest",
        max_fare=50.0,
    )
    response = rank_routes(request)

    assert response["preference"] == "cheapest"
    assert response["input_count"] == 3
    assert response["eligible_count"] == 2
    assert response["excluded_count"] == 1
    assert [r["route_id"] for r in response["routes"]] == ["A", "B"]


def test_rank_routes_exceeding_transfer_limit(candidate_routes):
    request = RouteRankingRequest(
        routes=candidate_routes,
        preference="fastest",
        max_transfers=1,
    )
    response = rank_routes(request)

    assert response["preference"] == "fastest"
    assert response["input_count"] == 3
    assert response["eligible_count"] == 2
    assert response["excluded_count"] == 1
    assert [r["route_id"] for r in response["routes"]] == ["C", "B"]


def test_rank_routes_exactly_at_limits(candidate_routes):
    request = RouteRankingRequest(
        routes=candidate_routes,
        preference="balanced",
        max_fare=45.0,
        max_transfers=1,
    )
    response = rank_routes(request)

    assert response["preference"] == "balanced"
    assert response["input_count"] == 3
    assert response["eligible_count"] == 1
    assert response["excluded_count"] == 2
    assert len(response["routes"]) == 1
    assert response["routes"][0]["route_id"] == "B"


def test_rank_routes_no_eligible_routes(candidate_routes):
    request = RouteRankingRequest(
        routes=candidate_routes,
        preference="balanced",
        max_fare=20.0,
    )
    response = rank_routes(request)

    assert response["preference"] == "balanced"
    assert response["input_count"] == 3
    assert response["eligible_count"] == 0
    assert response["excluded_count"] == 3
    assert response["routes"] == []


def test_rank_routes_without_constraints(candidate_routes):
    request = RouteRankingRequest(
        routes=candidate_routes,
        preference="balanced",
    )
    response = rank_routes(request)

    assert response["preference"] == "balanced"
    assert response["input_count"] == 3
    assert response["eligible_count"] == 3
    assert response["excluded_count"] == 0
    assert len(response["routes"]) == 3


def test_rank_routes_negative_constraints_rejected(candidate_routes):
    with pytest.raises(ValidationError):
        RouteRankingRequest(routes=candidate_routes, max_fare=-10.0)

    with pytest.raises(ValidationError):
        RouteRankingRequest(routes=candidate_routes, max_transfers=-1)
