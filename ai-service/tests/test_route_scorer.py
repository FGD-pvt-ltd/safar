import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from app.main import RouteCandidate, RouteRankingRequest, app, rank_routes
from app.services.route_scorer import filter_routes, score_routes

client = TestClient(app)

@pytest.fixture
def routes():
    return [
        {"route_id": "A", "travel_time_minutes": 70.0, "fare": 30.0, "transfers": 2},
        {"route_id": "B", "travel_time_minutes": 55.0, "fare": 45.0, "transfers": 1},
        {"route_id": "C", "travel_time_minutes": 40.0, "fare": 70.0, "transfers": 0},
    ]

@pytest.mark.parametrize("preference,expected", [
    ("fastest", "C"), ("cheapest", "A"),
    ("fewest_transfers", "C"), ("balanced", "C"),
])
def test_preferences(preference, expected, routes):
    assert score_routes(routes, preference)[0]["route_id"] == expected

def test_empty_candidates():
    response = client.post("/rank-routes", json={"routes": []})
    assert response.status_code == 200
    body = response.json()
    assert body["routes"] == [] and body["excluded"] == []

def test_strict_constraints_and_exclusion_reasons(routes):
    body = client.post("/rank-routes", json={"routes": routes, "max_fare": 45, "max_transfers": 1}).json()
    assert [r["route_id"] for r in body["routes"]] == ["B"]
    assert body["excluded_count"] == 2
    assert all(r["fare"] <= 45 and r["transfers"] <= 1 for r in body["routes"])
    assert len(body["excluded"]) == 2

def test_no_eligible_routes(routes):
    body = client.post("/rank-routes", json={"routes": routes, "max_fare": 1}).json()
    assert body["eligible_count"] == 0 and body["routes"] == []

def test_preference_invalid_is_422(routes):
    response = client.post("/rank-routes", json={"routes": routes, "preference": "luxury"})
    assert response.status_code == 422

def test_duplicate_ids_are_rejected(routes):
    duplicate = [routes[0], {**routes[1], "route_id": "A"}]
    response = client.post("/rank-routes", json={"routes": duplicate})
    assert response.status_code == 422
    assert "unique" in response.text

def test_malformed_and_invalid_values_are_rejected():
    assert client.post("/rank-routes", json={"routes": "not-a-list"}).status_code == 422
    bad = {"routes": [{"route_id": "x", "travel_time_minutes": -1, "fare": 1, "transfers": 0}]}
    assert client.post("/rank-routes", json=bad).status_code == 422
    with pytest.raises(ValidationError):
        RouteCandidate(route_id="x", travel_time_minutes=float("nan"), fare=1.0, transfers=0)

def test_integer_transfers_required():
    bad = {"routes": [{"route_id": "x", "travel_time_minutes": 1.0, "fare": 1.0, "transfers": 1.5}]}
    assert client.post("/rank-routes", json=bad).status_code == 422

def test_unavailable_and_cancelled_candidates_excluded():
    body = client.post("/rank-routes", json={"routes": [
        {"route_id": "ok", "travel_time_minutes": 10.0, "fare": 10.0, "transfers": 0},
        {"route_id": "cancelled", "travel_time_minutes": 5.0, "fare": 5.0, "transfers": 0, "cancelled": True},
        {"route_id": "unavailable", "travel_time_minutes": 5.0, "fare": 5.0, "transfers": 0, "is_available": False},
    ]}).json()
    assert [r["route_id"] for r in body["routes"]] == ["ok"]
    assert body["excluded_count"] == 2

def test_delay_reliability_disruption_change_score_and_explanation():
    routes = [
        {"route_id": "nominal", "travel_time_minutes": 20.0, "fare": 30.0, "transfers": 0, "expected_delay_minutes": 0.0, "reliability": 0.95, "disruption_severity": 0.0},
        {"route_id": "delayed", "travel_time_minutes": 10.0, "fare": 30.0, "transfers": 0, "expected_delay_minutes": 30.0, "reliability": 0.4, "disruption_severity": 0.8},
    ]
    ranked = score_routes(routes, "fastest")
    assert ranked[0]["route_id"] == "nominal"
    assert ranked[0]["rank"] == 1
    assert ranked[0]["reasons"]
    assert ranked[0]["score_components"]

def test_stable_ranks_and_ids(routes):
    first = score_routes(routes, "balanced")
    second = score_routes(list(reversed(routes)), "balanced")
    assert [(x["route_id"], x["score"], x["rank"]) for x in first] == [(x["route_id"], x["score"], x["rank"]) for x in second]

def test_legacy_response_fields_retained(routes):
    body = rank_routes(RouteRankingRequest(routes=routes))
    assert {"preference", "input_count", "eligible_count", "excluded_count", "routes"}.issubset(body)

def test_health_and_ranking_info():
    assert client.get("/health").json()["status"] == "ok"
    info = client.get("/ranking-info").json()
    assert set(info["preferences"]) == {"balanced", "cheapest", "fastest", "fewest_transfers"}

def test_hard_constraints_validation():
    with pytest.raises(ValidationError):
        RouteRankingRequest(routes=[], max_fare=-1)
    with pytest.raises(ValidationError):
        RouteRankingRequest(routes=[], max_transfers=-1)


def test_explanation_does_not_claim_unknown_disruption_is_low():
    ranked = score_routes([
        {"route_id": "unknown", "travel_time_minutes": 20.0, "fare": 10.0, "transfers": 0},
        {"route_id": "known", "travel_time_minutes": 30.0, "fare": 20.0, "transfers": 1, "disruption_severity": 0.8},
    ])
    unknown = next(r for r in ranked if r["route_id"] == "unknown")
    assert not any("disruption severity" in reason for reason in unknown["reasons"])
