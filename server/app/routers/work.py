from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import WorkSessionCreate, WorkSessionResponse
from app.crud import record_work_session, get_work_sessions, get_today_str
from app.models import WorkFocusSession

router = APIRouter(prefix="/api/work", tags=["Work & Focus"])


@router.post("/session", response_model=WorkSessionResponse)
def log_work_session(
    payload: WorkSessionCreate,
    db: Session = Depends(get_db)
):
    """
    Log or update a Work & Focus sprint.
    Persists sprint title, project, duration, runway bucket, exit reason, and interruption details.
    """
    return record_work_session(db, payload)


@router.get("/sessions", response_model=List[WorkSessionResponse])
def list_work_sessions(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format (defaults to today)"),
    db: Session = Depends(get_db)
):
    """
    List focus sprints for a given date.
    """
    date_key = date or get_today_str()
    return get_work_sessions(db, date_str=date_key)


@router.get("/today-summary")
def get_today_work_summary(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format (defaults to today)"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Aggregated focus statistics for today:
    Total focus time, sprint count, longest sprint, and breakdown by runway bucket.
    """
    date_key = date or get_today_str()
    sessions = db.query(WorkFocusSession).filter(WorkFocusSession.date == date_key).all()

    total_secs = sum(s.duration_seconds for s in sessions)
    total_mins = round(total_secs / 60.0, 1)
    longest_secs = max([s.duration_seconds for s in sessions], default=0.0)

    bucket_breakdown: Dict[str, float] = {}
    for s in sessions:
        bucket = s.runway_bucket or "Unassigned"
        bucket_breakdown[bucket] = bucket_breakdown.get(bucket, 0.0) + (s.duration_seconds / 60.0)

    for k in bucket_breakdown:
        bucket_breakdown[k] = round(bucket_breakdown[k], 1)

    interrupted_count = sum(1 for s in sessions if s.exit_reason in ["Interrupted", "Headache / Fatigue"])

    return {
        "date": date_key,
        "total_focus_minutes": total_mins,
        "total_focus_hours": round(total_mins / 60.0, 2),
        "sprints_completed": len(sessions),
        "longest_sprint_minutes": round(longest_secs / 60.0, 1),
        "interrupted_sprints": interrupted_count,
        "runway_bucket_minutes": bucket_breakdown,
    }
