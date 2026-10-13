from __future__ import annotations

from typing import Any, Literal
from fastapi import FastAPI
from pydantic import BaseModel, ConfigDict, Field, StrictBool, StrictInt, StrictStr, field_validator, model_validator

from app.services.route_scorer import PREFERENCE_WEIGHTS, exclusion_reason, score_routes

Preference = Literal["balanced", "cheapest", "fastest", "fewest_transfers"]


class RouteCandidate(BaseModel):
    model_config = ConfigDict(extra="allow")

    route_id: StrictStr = Field(min_length=1, max_length=160)
    travel_time_minutes: float = Field(ge=0, allow_inf_nan=False, strict=True)
    fare: float = Field(ge=0, allow_inf_nan=False, strict=True)
    transfers: StrictInt = Field(ge=0)
    expected_delay_minutes: float | None = Field(default=None, ge=0, allow_inf_nan=False, strict=True)
    reliability: float | None = Field(default=None, ge=0, le=1, allow_inf_nan=False, strict=True, description="Optional normalized reliability in [0,1], only when measured")
    disruption_severity: float | None = Field(default=None, ge=0, le=1, allow_inf_nan=False, strict=True, description="Optional reported disruption severity in [0,1]")
    cancelled: StrictBool = False
    is_available: StrictBool = True

    @field_validator("route_id")
    @classmethod
    def normalize_route_id(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("route_id cannot be blank")
        return value


class RouteRankingRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    routes: list[RouteCandidate] = Field(max_length=500)
    preference: Preference = "balanced"
    max_fare: float | None = Field(default=None, ge=0, allow_inf_nan=False, strict=True)
    max_transfers: StrictInt | None = Field(default=None, ge=0)

    @model_validator(mode="after")
    def validate_unique_ids(self):
        ids = [route.route_id.strip() for route in self.routes]
        if len(ids) != len(set(ids)):
            raise ValueError("route_id values must be unique within routes")
        return self


app = FastAPI(
    title="Safar AI Service",
    description="Deterministic route ranking for backend-generated transit journeys",
    version="0.2.0",
)


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "safar-ai-service", "ranking_mode": "deterministic"}


@app.get("/ranking-info")
def ranking_info():
    return {"preferences": list(PREFERENCE_WEIGHTS), "score_range": [0, 100],
            "score_semantics": "relative candidate-set score; not a probability",
            "hard_constraints": ["max_fare", "max_transfers", "cancelled", "is_available"]}


@app.post("/rank-routes")
def rank_routes(request: RouteRankingRequest) -> dict[str, Any]:
    candidates = [route.model_dump() for route in request.routes]
    excluded = []
    eligible = []
    for route in candidates:
        reason = exclusion_reason(route, request.max_fare, request.max_transfers)
        if reason:
            excluded.append({"route_id": route["route_id"], "reason": reason})
        else:
            eligible.append(route)

    ranked = score_routes(eligible, request.preference)
    return {
        # Keep all legacy response fields.
        "preference": request.preference,
        "input_count": len(candidates),
        "eligible_count": len(eligible),
        "excluded_count": len(excluded),
        "routes": ranked,
        # Additive fields for richer UI and operational visibility.
        "excluded": excluded,
        "result_status": ("no_candidates_supplied" if not candidates else "no_eligible_routes" if not eligible else "ranked"),
        "metadata": {
            "ranking_mode": "deterministic_weighted_scoring",
            "score_range": [0, 100],
            "score_semantics": "relative to eligible candidates in this request; not a probability",
            "hard_constraints_enforced": True,
            "live_data_verified_by_ai_service": False,
            "explanation_source": "scoring features and fields supplied by backend",
        },
    }
