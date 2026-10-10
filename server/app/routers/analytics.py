from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import TodayAnalyticsResponse, TrendsSummaryResponse
from app.analytics import get_today_analytics, get_trends_summary

router = APIRouter(prefix="/api/analytics", tags=["Analytics & Insights"])


@router.get("/today", response_model=TodayAnalyticsResponse)
def today_analytics(
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format (defaults to today)"),
    db: Session = Depends(get_db)
):
    """
    Real-time intelligence on today's execution:
    - Morning routine completion percentage & deadline status
    - Live Omeprazole countdown and 30-60m eating window status
    - Total focus sprint minutes and sprint count
    - Friction alerts (overdue tasks, missed medical windows, fatigue interruptions)
    - Friction flow score (0-100)
    """
    return get_today_analytics(db, date_str=date)


@router.get("/trends", response_model=TrendsSummaryResponse)
def trends_analytics(
    days: int = Query(7, ge=1, le=90, description="Number of days to analyze"),
    db: Session = Depends(get_db)
):
    """
    Multi-day trend metrics:
    - Average morning routine duration
    - Morning routine completion percentage
    - Top recurring friction bottleneck tasks
    - Total focus hours
    - 10 PM curfew compliance rate
    - Average daily friction score
    """
    return get_trends_summary(db, days=days)
