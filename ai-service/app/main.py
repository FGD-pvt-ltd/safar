from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.services.route_scorer import filter_routes, score_routes

app = FastAPI(
    title="Safar AI Service",
    description="AI/ML route recommendation and ranking service",
    version="0.1.0",
)


class RouteCandidate(BaseModel):
    route_id: str
    travel_time_minutes: float = Field(ge=0)
    fare: float = Field(ge=0)
    transfers: int = Field(ge=0)


class RouteRankingRequest(BaseModel):
    routes: list[RouteCandidate]
    preference: str = "balanced"
    max_fare: float | None = Field(default=None, ge=0)
    max_transfers: int | None = Field(default=None, ge=0)


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "safar-ai-service"}


@app.post("/rank-routes")
def rank_routes(request: RouteRankingRequest):
    try:
        routes = [route.model_dump() for route in request.routes]
        eligible_routes = filter_routes(
            routes,
            max_fare=request.max_fare,
            max_transfers=request.max_transfers,
        )
        ranked_routes = score_routes(eligible_routes, request.preference)
        return {
            "preference": request.preference,
            "input_count": len(routes),
            "eligible_count": len(eligible_routes),
            "excluded_count": len(routes) - len(eligible_routes),
            "routes": ranked_routes,
        }
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))
