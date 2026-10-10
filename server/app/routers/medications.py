from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.schemas import MedicationLogCreate, MedicationLogResponse, EatingEventCreate
from app.crud import (
    record_medication,
    record_eating_event,
    get_medication_logs,
    get_today_str,
)
from app.models import MedicationLog, utc_now, ensure_utc

router = APIRouter(prefix="/api/medications", tags=["Medications"])


@router.post("/log", response_model=MedicationLogResponse)
def log_medication(
    payload: MedicationLogCreate,
    db: Session = Depends(get_db)
):
    """
    Log medication intake. Automatically initializes the 30-minute Omeprazole countdown
    and 30-60 min eating window.
    """
    return record_medication(db, payload)


@router.post("/eating-event", response_model=Optional[MedicationLogResponse])
def log_eating_event(
    payload: EatingEventCreate,
    db: Session = Depends(get_db)
):
    """
    Log when food/breakfast was consumed. Validates Omeprazole timing compliance:
    Checks if eating occurred within the optimal 30–60 min window and flags timing friction if breached.
    """
    return record_eating_event(db, payload)


@router.get("/logs", response_model=List[MedicationLogResponse])
def list_medications(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db)
):
    """
    List all medication logs for a given date.
    """
    date_key = date or get_today_str()
    return get_medication_logs(db, date_str=date_key)


@router.get("/omeprazole-status")
def get_omeprazole_status(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Get live status of Omeprazole medication timing for today:
    Returns remaining wait seconds, whether eating window is active, or if window passed.
    """
    date_key = date or get_today_str()
    log = (
        db.query(MedicationLog)
        .filter(MedicationLog.date == date_key, MedicationLog.is_omeprazole == True)
        .order_by(desc(MedicationLog.taken_at))
        .first()
    )

    if not log:
        return {
            "status": "not_taken",
            "message": "Omeprazole not yet logged today.",
            "taken_at": None,
            "wait_seconds_remaining": 0,
            "eating_window_open": False,
            "eating_window_closed": False,
            "food_consumed": False,
        }

    now = utc_now()
    food_consumed = log.food_consumed_at is not None

    if log.eating_window_open_at and log.eating_window_close_at:
        open_at = ensure_utc(log.eating_window_open_at)
        close_at = ensure_utc(log.eating_window_close_at)
        if now < open_at:
            secs_left = max(0, int((open_at - now).total_seconds()))
            return {
                "status": "waiting",
                "message": f"Waiting to eat: {secs_left // 60}m {secs_left % 60}s remaining before optimal food intake.",
                "taken_at": log.taken_at.isoformat(),
                "eating_window_opens_at": open_at.isoformat(),
                "eating_window_closes_at": close_at.isoformat(),
                "wait_seconds_remaining": secs_left,
                "eating_window_open": False,
                "eating_window_closed": False,
                "food_consumed": food_consumed,
            }
        elif open_at <= now <= close_at:
            secs_window_left = max(0, int((close_at - now).total_seconds()))
            return {
                "status": "window_open",
                "message": f"Optimal eating window is OPEN. Window closes in {secs_window_left // 60}m {secs_window_left % 60}s.",
                "taken_at": log.taken_at.isoformat(),
                "eating_window_opens_at": open_at.isoformat(),
                "eating_window_closes_at": close_at.isoformat(),
                "wait_seconds_remaining": 0,
                "window_seconds_remaining": secs_window_left,
                "eating_window_open": True,
                "eating_window_closed": False,
                "food_consumed": food_consumed,
            }
        else:
            return {
                "status": "window_closed",
                "message": "Optimal 30-60 minute eating window has closed.",
                "taken_at": log.taken_at.isoformat(),
                "eating_window_opens_at": log.eating_window_open_at.isoformat(),
                "eating_window_closes_at": log.eating_window_close_at.isoformat(),
                "wait_seconds_remaining": 0,
                "eating_window_open": False,
                "eating_window_closed": True,
                "food_consumed": food_consumed,
                "ate_within_window": log.ate_within_window,
            }

    return {
        "status": "taken",
        "taken_at": log.taken_at.isoformat(),
        "food_consumed": food_consumed,
    }
