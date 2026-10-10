from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import (
    MorningRoutineUpdate,
    MorningRoutineResponse,
    NightRoutineUpdate,
    NightRoutineResponse,
    NightCycleEventCreate,
    NightCycleResponse,
)
from app.crud import (
    get_or_create_morning_routine,
    update_morning_routine,
    get_or_create_night_routine,
    update_night_routine,
    record_night_cycle,
    get_today_str,
)
from app.models import NightCycleEvent

router = APIRouter(prefix="/api/routines", tags=["Routines"])


@router.post("/morning", response_model=MorningRoutineResponse)
def update_morning(
    payload: MorningRoutineUpdate,
    db: Session = Depends(get_db)
):
    """
    Log or update today's morning routine progress, timestamps, and completion.
    """
    record = update_morning_routine(db, payload)
    return record


@router.get("/morning", response_model=MorningRoutineResponse)
def get_morning(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format (defaults to today)"),
    db: Session = Depends(get_db)
):
    """
    Fetch the morning routine record for a given date.
    """
    return get_or_create_morning_routine(db, date)


@router.post("/night", response_model=NightRoutineResponse)
def update_night(
    payload: NightRoutineUpdate,
    db: Session = Depends(get_db)
):
    """
    Log or update today's night routine progress and completion.
    """
    record = update_night_routine(db, payload)
    return record


@router.get("/night", response_model=NightRoutineResponse)
def get_night(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format (defaults to today)"),
    db: Session = Depends(get_db)
):
    """
    Fetch the night routine record for a given date.
    """
    return get_or_create_night_routine(db, date)


@router.post("/night/10pm-alert", response_model=NightCycleResponse)
def log_10pm_alert(
    payload: NightCycleEventCreate,
    db: Session = Depends(get_db)
):
    """
    Log 10 PM alert takeover trigger, dismissal timestamp, and reaction latency.
    """
    return record_night_cycle(db, payload)


@router.get("/night/10pm-alert", response_model=Optional[NightCycleResponse])
def get_10pm_alert(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db)
):
    """
    Get 10 PM alert log for a given date.
    """
    date_key = date or get_today_str()
    record = db.query(NightCycleEvent).filter(NightCycleEvent.date == date_key).first()
    return record
