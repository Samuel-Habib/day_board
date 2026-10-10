import json
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import BulkSyncPayload, BulkSyncResponse
from app.crud import process_bulk_sync, get_today_str
from app.models import DailySnapshot

router = APIRouter(prefix="/api/sync", tags=["Sync"])


@router.post("/state", response_model=BulkSyncResponse)
def sync_dashboard_state(
    payload: BulkSyncPayload,
    db: Session = Depends(get_db)
):
    """
    Bulk synchronize dashboard state from Apple TV to the database server.
    Safely reconciles morning tasks, night tasks, medications, guided sessions,
    and work focus sprints in a single call. Also creates a full JSON snapshot backup.
    """
    date_key = payload.date or get_today_str()
    counts = process_bulk_sync(db, payload)

    return BulkSyncResponse(
        status="success",
        date=date_key,
        synced_items=counts,
        message=f"Successfully persisted state for {date_key}: {counts['morning_tasks']} morning tasks, {counts['medications']} meds, {counts['work_sessions']} work sessions."
    )


@router.get("/snapshot")
def get_snapshot(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Retrieve the full raw JSON state snapshot for a given date.
    """
    date_key = date or get_today_str()
    snapshot = db.query(DailySnapshot).filter(DailySnapshot.date == date_key).first()
    if snapshot:
        try:
            return json.loads(snapshot.raw_json_state)
        except Exception:
            return {"raw": snapshot.raw_json_state}
    return {"message": f"No snapshot found for {date_key}"}
