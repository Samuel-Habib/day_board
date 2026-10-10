from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import TaskEventCreate, TaskEventResponse
from app.crud import record_task_event, get_task_events, get_today_str
from app.models import TaskEvent

router = APIRouter(prefix="/api/tasks", tags=["Tasks"])


@router.post("/event", response_model=TaskEventResponse)
def log_task_event(
    payload: TaskEventCreate,
    db: Session = Depends(get_db)
):
    """
    Record or update an individual task milestone event.
    Logs completion timestamp, actual duration, target deadline adherence, overdue slippage, and subtasks.
    """
    return record_task_event(db, payload)


@router.get("/events", response_model=List[TaskEventResponse])
def list_task_events(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format (defaults to today)"),
    period: Optional[str] = Query(None, description="Routine period: morning, night, daily"),
    db: Session = Depends(get_db)
):
    """
    List task execution events filtered by date and period.
    """
    date_key = date or get_today_str()
    return get_task_events(db, date_str=date_key, period=period)


@router.get("/history/{task_id}", response_model=List[TaskEventResponse])
def get_task_history(
    task_id: str,
    limit: int = Query(30, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """
    Get execution history for a specific task over recent days.
    """
    return (
        db.query(TaskEvent)
        .filter(TaskEvent.task_id == task_id)
        .order_by(TaskEvent.date.desc())
        .limit(limit)
        .all()
    )
