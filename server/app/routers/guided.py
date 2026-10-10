from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import GuidedSessionCreate, GuidedSessionResponse
from app.crud import record_guided_session, get_today_str
from app.models import GuidedSession

router = APIRouter(prefix="/api/guided", tags=["Guided Protocols"])


@router.post("/session", response_model=GuidedSessionResponse)
def log_guided_session(
    payload: GuidedSessionCreate,
    db: Session = Depends(get_db)
):
    """
    Log a guided rehabilitation or exercise session:
    Foot Rehab, Mobility/Stretching, or Bodyweight Workout.
    """
    return record_guided_session(db, payload)


@router.get("/sessions", response_model=List[GuidedSessionResponse])
def list_guided_sessions(
    routine_type: Optional[str] = Query(None, description="Routine type: foot, stretching, exercise"),
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db)
):
    """
    List guided protocol sessions filtered by routine type and date.
    """
    query = db.query(GuidedSession)
    if date:
        query = query.filter(GuidedSession.date == date)
    if routine_type:
        query = query.filter(GuidedSession.routine_type == routine_type)
    return query.order_by(GuidedSession.started_at.desc()).all()


@router.get("/today-status")
def get_today_guided_status(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Summary of which guided protocols (Foot, Stretch, Calisthenics) are completed today.
    """
    date_key = date or get_today_str()
    sessions = db.query(GuidedSession).filter(GuidedSession.date == date_key).all()

    completed_types = {s.routine_type for s in sessions if s.is_completed}

    return {
        "date": date_key,
        "foot_completed": "foot" in completed_types,
        "stretching_completed": "stretching" in completed_types,
        "exercise_completed": "exercise" in completed_types,
        "total_sessions": len(sessions),
    }
