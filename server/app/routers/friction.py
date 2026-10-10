from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from app.database import get_db
from app.schemas import FrictionLogCreate, FrictionLogResponse
from app.crud import record_friction_log, get_friction_logs, get_today_str
from app.models import FrictionLog

router = APIRouter(prefix="/api/friction", tags=["Friction & Flow"])


@router.post("/log", response_model=FrictionLogResponse)
def log_friction(
    payload: FrictionLogCreate,
    db: Session = Depends(get_db)
):
    """
    Log a friction event or observation.
    Classify as productive (healthy intentional resistance) or unproductive (distraction, cognitive stall, friction to eliminate).
    """
    return record_friction_log(db, payload)


@router.get("/logs", response_model=List[FrictionLogResponse])
def list_friction_logs(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    category: Optional[str] = Query(None, description="Filter by: unproductive or productive"),
    db: Session = Depends(get_db)
):
    """
    List friction logs filtered by date and category.
    """
    query = db.query(FrictionLog)
    if date:
        query = query.filter(FrictionLog.date == date)
    if category:
        query = query.filter(FrictionLog.category == category)
    return query.order_by(FrictionLog.created_at.desc()).all()


@router.get("/bottlenecks")
def get_top_bottlenecks(
    days: int = Query(14, ge=1, le=90),
    db: Session = Depends(get_db)
):
    """
    Retrieve top recurring friction sources and bottlenecks over the specified lookback window.
    """
    results = (
        db.query(
            FrictionLog.friction_source,
            FrictionLog.category,
            func.count(FrictionLog.id).label("count"),
            func.sum(FrictionLog.duration_loss_seconds).label("total_loss_secs")
        )
        .group_by(FrictionLog.friction_source, FrictionLog.category)
        .order_by(desc("count"))
        .limit(10)
        .all()
    )

    return [
        {
            "friction_source": r[0],
            "category": r[1],
            "frequency": r[2],
            "total_time_lost_minutes": round((r[3] or 0.0) / 60.0, 1),
        }
        for r in results
    ]
