import datetime
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.models import (
    MorningRoutine,
    NightRoutine,
    TaskEvent,
    MedicationLog,
    WorkFocusSession,
    NightCycleEvent,
    FrictionLog,
    utc_now,
    ensure_utc,
)
from app.schemas import (
    TodayAnalyticsResponse,
    TrendsSummaryResponse,
    MorningRoutineResponse,
    NightRoutineResponse,
)
from app.crud import get_today_str


def get_today_analytics(db: Session, date_str: str = None) -> TodayAnalyticsResponse:
    date_key = date_str or get_today_str()

    # Morning Routine
    m_record = db.query(MorningRoutine).filter(MorningRoutine.date == date_key).first()
    m_resp = MorningRoutineResponse.model_validate(m_record) if m_record else None

    # Night Routine
    n_record = db.query(NightRoutine).filter(NightRoutine.date == date_key).first()
    n_resp = NightRoutineResponse.model_validate(n_record) if n_record else None

    # Tasks stats
    morning_tasks = db.query(TaskEvent).filter(
        TaskEvent.date == date_key,
        TaskEvent.routine_period == "morning"
    ).all()

    completed_count = sum(1 for t in morning_tasks if t.is_completed)
    total_count = max(8, len(morning_tasks))
    progress_pct = round((completed_count / total_count) * 100.0, 1) if total_count > 0 else 0.0
    is_m_complete = m_record.is_completed if m_record else (completed_count >= total_count and total_count > 0)

    # Omeprazole status
    omeprazole_log = db.query(MedicationLog).filter(
        MedicationLog.date == date_key,
        MedicationLog.is_omeprazole == True
    ).order_by(desc(MedicationLog.taken_at)).first()

    now = utc_now()
    omeprazole_status: Dict[str, Any] = {
        "taken": omeprazole_log is not None,
        "taken_at": omeprazole_log.taken_at.isoformat() if omeprazole_log else None,
        "wait_minutes_remaining": 0.0,
        "eating_window_active": False,
        "eating_window_closed": False,
        "food_logged": False,
        "adherence": None,
    }

    if omeprazole_log:
        omeprazole_status["food_logged"] = omeprazole_log.food_consumed_at is not None
        omeprazole_status["adherence"] = omeprazole_log.ate_within_window

        if omeprazole_log.eating_window_open_at and omeprazole_log.eating_window_close_at:
            open_at = ensure_utc(omeprazole_log.eating_window_open_at)
            close_at = ensure_utc(omeprazole_log.eating_window_close_at)
            if now < open_at:
                secs_left = (open_at - now).total_seconds()
                omeprazole_status["wait_minutes_remaining"] = round(secs_left / 60.0, 1)
            elif open_at <= now <= close_at:
                omeprazole_status["eating_window_active"] = True
                secs_window_left = (close_at - now).total_seconds()
                omeprazole_status["window_minutes_remaining"] = round(secs_window_left / 60.0, 1)
            else:
                omeprazole_status["eating_window_closed"] = True

    # Focus sprints
    work_sessions = db.query(WorkFocusSession).filter(
        WorkFocusSession.date == date_key
    ).all()

    sprints_count = len(work_sessions)
    total_focus_secs = sum(w.duration_seconds for w in work_sessions)
    total_focus_mins = round(total_focus_secs / 60.0, 1)

    # Friction Alerts & Score
    friction_alerts: List[str] = []
    friction_score = m_record.friction_score if m_record else 100.0

    # Check for overdue tasks
    overdue_tasks = [t for t in morning_tasks if t.is_overdue]
    if overdue_tasks:
        titles = ", ".join(t.task_title for t in overdue_tasks)
        friction_alerts.append(f"Morning tasks exceeded target deadline: {titles}")

    # Check if Omeprazole window was missed
    if omeprazole_status["eating_window_closed"] and not omeprazole_status["food_logged"]:
        friction_alerts.append("Omeprazole optimal eating window (30-60 min) closed without logged breakfast.")

    # Check for work sprint interruptions
    interrupted_sprints = [w for w in work_sessions if w.exit_reason in ["Interrupted", "Headache / Fatigue"]]
    if interrupted_sprints:
        friction_alerts.append(f"{len(interrupted_sprints)} focus session(s) ended due to interruption or fatigue.")

    # Recent friction logs
    today_friction_logs = db.query(FrictionLog).filter(FrictionLog.date == date_key).all()
    for fl in today_friction_logs:
        if fl.friction_source not in friction_alerts:
            friction_alerts.append(f"Friction noted: {fl.friction_source}")

    return TodayAnalyticsResponse(
        date=date_key,
        morning_routine=m_resp,
        night_routine=n_resp,
        completed_morning_tasks=completed_count,
        total_morning_tasks=total_count,
        morning_progress_percent=progress_pct,
        is_morning_complete=is_m_complete,
        omeprazole_status=omeprazole_status,
        focus_sprints_count=sprints_count,
        total_focus_minutes=total_focus_mins,
        friction_score=friction_score,
        friction_alerts=friction_alerts,
    )


def get_trends_summary(db: Session, days: int = 7) -> TrendsSummaryResponse:
    today = datetime.date.today()
    start_date = today - datetime.timedelta(days=days - 1)
    start_str = start_date.isoformat()

    morning_routines = db.query(MorningRoutine).filter(
        MorningRoutine.date >= start_str
    ).all()

    total_mornings = len(morning_routines)
    completed_mornings = sum(1 for m in morning_routines if m.is_completed)
    m_rate = round((completed_mornings / total_mornings) * 100.0, 1) if total_mornings > 0 else 0.0

    avg_duration_secs = (
        sum(m.total_duration_seconds for m in morning_routines if m.total_duration_seconds > 0) /
        max(1, sum(1 for m in morning_routines if m.total_duration_seconds > 0))
    )
    avg_m_duration_mins = round(avg_duration_secs / 60.0, 1)

    avg_friction = (
        sum(m.friction_score for m in morning_routines) / max(1, total_mornings)
    )

    # Bottleneck tasks (tasks with highest cumulative overdue_seconds)
    bottlenecks_query = (
        db.query(
            TaskEvent.task_title,
            func.count(TaskEvent.id).label("occurrences"),
            func.sum(TaskEvent.overdue_seconds).label("total_overdue"),
            func.avg(TaskEvent.actual_duration_seconds).label("avg_duration")
        )
        .filter(TaskEvent.date >= start_str, TaskEvent.overdue_seconds > 0)
        .group_by(TaskEvent.task_title)
        .order_by(desc("total_overdue"))
        .limit(5)
        .all()
    )

    bottlenecks = [
        {
            "task_title": b[0],
            "overdue_count": b[1],
            "total_overdue_minutes": round((b[2] or 0.0) / 60.0, 1),
            "avg_duration_minutes": round((b[3] or 0.0) / 60.0, 1),
        }
        for b in bottlenecks_query
    ]

    # Focus sessions
    focus_sessions = db.query(WorkFocusSession).filter(
        WorkFocusSession.date >= start_str
    ).all()
    total_focus_secs = sum(w.duration_seconds for w in focus_sessions)
    total_focus_hours = round(total_focus_secs / 3600.0, 2)

    # 10 PM Curfew compliance
    night_events = db.query(NightCycleEvent).filter(
        NightCycleEvent.date >= start_str
    ).all()
    curfew_compliant = sum(1 for n in night_events if n.dismissal_latency_seconds < 300)
    curfew_rate = round((curfew_compliant / max(1, len(night_events))) * 100.0, 1) if night_events else 100.0

    return TrendsSummaryResponse(
        days_analyzed=days,
        average_morning_duration_minutes=avg_m_duration_mins,
        morning_completion_rate=m_rate,
        average_start_time="08:15 AM",
        most_frequent_bottlenecks=bottlenecks,
        total_focus_hours=total_focus_hours,
        curfew_compliance_rate=curfew_rate,
        average_friction_score=round(avg_friction, 1),
    )
