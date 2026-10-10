import json
import datetime
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.models import (
    MorningRoutine,
    NightRoutine,
    TaskEvent,
    MedicationLog,
    GuidedSession,
    WorkFocusSession,
    NightCycleEvent,
    FrictionLog,
    DailySnapshot,
    utc_now,
    ensure_utc,
)
from app.schemas import (
    TaskEventCreate,
    MorningRoutineUpdate,
    NightRoutineUpdate,
    MedicationLogCreate,
    EatingEventCreate,
    GuidedSessionCreate,
    WorkSessionCreate,
    NightCycleEventCreate,
    FrictionLogCreate,
    BulkSyncPayload,
)


def get_today_str() -> str:
    return datetime.date.today().isoformat()


# ---------------- Morning Routines ----------------
def get_or_create_morning_routine(db: Session, date_str: Optional[str] = None) -> MorningRoutine:
    date_key = date_str or get_today_str()
    record = db.query(MorningRoutine).filter(MorningRoutine.date == date_key).first()
    if not record:
        record = MorningRoutine(
            date=date_key,
            started_at=utc_now(),
            tasks_count=8,
            completed_tasks_count=0,
            friction_score=100.0,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
    return record


def update_morning_routine(db: Session, update: MorningRoutineUpdate) -> MorningRoutine:
    date_key = update.date or get_today_str()
    record = get_or_create_morning_routine(db, date_key)

    if update.started_at:
        record.started_at = update.started_at
    if update.completed_at:
        record.completed_at = update.completed_at
    if update.is_completed is not None:
        record.is_completed = update.is_completed
    if update.total_duration_seconds is not None:
        record.total_duration_seconds = update.total_duration_seconds
    if update.tasks_count is not None:
        record.tasks_count = update.tasks_count
    if update.completed_tasks_count is not None:
        record.completed_tasks_count = update.completed_tasks_count
    if update.start_delay_seconds is not None:
        record.start_delay_seconds = update.start_delay_seconds
    if update.total_overdue_seconds is not None:
        record.total_overdue_seconds = update.total_overdue_seconds
    if update.notes is not None:
        record.notes = update.notes

    # Recompute friction score
    # Baseline: 100
    # Deductions: start delay (>5m = -10, >15m = -25), overdue seconds (-1 pt per 2 mins overdue), incomplete (-10 per missing task)
    friction = 100.0
    if record.start_delay_seconds > 300:
        friction -= min(30.0, (record.start_delay_seconds / 60.0) * 1.5)
    if record.total_overdue_seconds > 0:
        friction -= min(40.0, (record.total_overdue_seconds / 120.0))
    if record.tasks_count > 0:
        missing = max(0, record.tasks_count - record.completed_tasks_count)
        if record.is_completed is False and missing > 0:
            friction -= min(30.0, missing * 5.0)
    record.friction_score = max(0.0, min(100.0, round(friction, 1)))

    db.commit()
    db.refresh(record)
    return record


# ---------------- Night Routines ----------------
def get_or_create_night_routine(db: Session, date_str: Optional[str] = None) -> NightRoutine:
    date_key = date_str or get_today_str()
    record = db.query(NightRoutine).filter(NightRoutine.date == date_key).first()
    if not record:
        record = NightRoutine(
            date=date_key,
            tasks_count=4,
            completed_tasks_count=0,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
    return record


def update_night_routine(db: Session, update: NightRoutineUpdate) -> NightRoutine:
    date_key = update.date or get_today_str()
    record = get_or_create_night_routine(db, date_key)

    if update.started_at:
        record.started_at = update.started_at
    if update.completed_at:
        record.completed_at = update.completed_at
    if update.is_completed is not None:
        record.is_completed = update.is_completed
    if update.total_duration_seconds is not None:
        record.total_duration_seconds = update.total_duration_seconds
    if update.tasks_count is not None:
        record.tasks_count = update.tasks_count
    if update.completed_tasks_count is not None:
        record.completed_tasks_count = update.completed_tasks_count
    if update.notes is not None:
        record.notes = update.notes

    db.commit()
    db.refresh(record)
    return record


# ---------------- Task Events ----------------
def record_task_event(db: Session, event: TaskEventCreate) -> TaskEvent:
    date_key = event.date or get_today_str()
    completed_time = event.completed_at or utc_now()

    subtasks_str = json.dumps(event.subtasks_completed) if event.subtasks_completed else None

    # Check existing event for this task on this day
    existing = db.query(TaskEvent).filter(
        TaskEvent.date == date_key,
        TaskEvent.task_id == event.task_id
    ).first()

    if existing:
        existing.task_title = event.task_title
        existing.routine_period = event.routine_period
        existing.routine_type = event.routine_type
        existing.target_deadline_time = event.target_deadline_time
        existing.duration_minutes_allotted = event.duration_minutes_allotted
        if event.started_at:
            existing.started_at = event.started_at
        existing.completed_at = completed_time
        existing.actual_duration_seconds = event.actual_duration_seconds
        existing.is_completed = event.is_completed
        existing.is_overdue = event.is_overdue
        existing.overdue_seconds = event.overdue_seconds
        existing.subtasks_completed = subtasks_str
        if event.friction_notes:
            existing.friction_notes = event.friction_notes
        db.commit()
        db.refresh(existing)
        task_record = existing
    else:
        task_record = TaskEvent(
            date=date_key,
            routine_period=event.routine_period,
            task_id=event.task_id,
            task_title=event.task_title,
            routine_type=event.routine_type,
            target_deadline_time=event.target_deadline_time,
            duration_minutes_allotted=event.duration_minutes_allotted,
            started_at=event.started_at,
            completed_at=completed_time,
            actual_duration_seconds=event.actual_duration_seconds,
            is_completed=event.is_completed,
            is_overdue=event.is_overdue,
            overdue_seconds=event.overdue_seconds,
            subtasks_completed=subtasks_str,
            friction_notes=event.friction_notes,
        )
        db.add(task_record)
        db.commit()
        db.refresh(task_record)

    # Automatically update the parent routine counters
    if event.routine_period == "morning":
        m_routine = get_or_create_morning_routine(db, date_key)
        completed_count = db.query(TaskEvent).filter(
            TaskEvent.date == date_key,
            TaskEvent.routine_period == "morning",
            TaskEvent.is_completed == True
        ).count()
        m_routine.completed_tasks_count = completed_count
        
        # Calculate sum of overdue seconds
        sum_overdue = db.query(func.sum(TaskEvent.overdue_seconds)).filter(
            TaskEvent.date == date_key,
            TaskEvent.routine_period == "morning"
        ).scalar() or 0.0
        m_routine.total_overdue_seconds = sum_overdue

        if m_routine.tasks_count > 0 and completed_count >= m_routine.tasks_count:
            m_routine.is_completed = True
            m_routine.completed_at = completed_time
            if m_routine.started_at:
                m_routine.total_duration_seconds = max(0.0, (completed_time - m_routine.started_at).total_seconds())

        db.commit()

    return task_record


def get_task_events(db: Session, date_str: Optional[str] = None, period: Optional[str] = None) -> List[TaskEvent]:
    query = db.query(TaskEvent)
    if date_str:
        query = query.filter(TaskEvent.date == date_str)
    if period:
        query = query.filter(TaskEvent.routine_period == period)
    return query.order_by(TaskEvent.completed_at.asc()).all()


# ---------------- Medications ----------------
def record_medication(db: Session, med: MedicationLogCreate) -> MedicationLog:
    date_key = med.date or get_today_str()
    taken = med.taken_at or utc_now()

    eating_open = None
    eating_close = None
    if med.is_omeprazole or "omeprazole" in med.name.lower() or "prilosec" in med.name.lower():
        eating_open = taken + datetime.timedelta(minutes=30)
        eating_close = taken + datetime.timedelta(minutes=60)

    record = MedicationLog(
        date=date_key,
        medication_id=med.medication_id,
        name=med.name,
        period=med.period,
        taken_at=taken,
        is_omeprazole=med.is_omeprazole or "omeprazole" in med.name.lower(),
        wait_window_minutes=30,
        eating_window_open_at=eating_open,
        eating_window_close_at=eating_close,
        notes=med.notes,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def record_eating_event(db: Session, event: EatingEventCreate) -> Optional[MedicationLog]:
    date_key = event.date or get_today_str()
    consumed_at = ensure_utc(event.food_consumed_at or utc_now())

    # Find the most recent Omeprazole intake for today
    omeprazole_log = db.query(MedicationLog).filter(
        MedicationLog.date == date_key,
        MedicationLog.is_omeprazole == True
    ).order_by(desc(MedicationLog.taken_at)).first()

    if omeprazole_log:
        omeprazole_log.food_consumed_at = consumed_at
        if omeprazole_log.eating_window_open_at and omeprazole_log.eating_window_close_at:
            open_at = ensure_utc(omeprazole_log.eating_window_open_at)
            close_at = ensure_utc(omeprazole_log.eating_window_close_at)
            ate_in_window = (open_at <= consumed_at <= close_at)
            omeprazole_log.ate_within_window = ate_in_window
            if not ate_in_window:
                # Log a friction event!
                diff_open = (consumed_at - open_at).total_seconds()
                reason = "Ate too early (< 30 min wait)" if diff_open < 0 else "Ate too late (> 60 min after dose)"
                f_log = FrictionLog(
                    date=date_key,
                    event_type="meds_timing_breach",
                    category="unproductive",
                    friction_source="Omeprazole Timing Window Missed",
                    duration_loss_seconds=abs(diff_open),
                    mitigation_hint="Wait at least 30m but no more than 60m after Omeprazole for optimal gastric absorption.",
                    notes=f"Food consumed at {consumed_at.isoformat()}. Reason: {reason}"
                )
                db.add(f_log)
        db.commit()
        db.refresh(omeprazole_log)
    return omeprazole_log


def get_medication_logs(db: Session, date_str: Optional[str] = None) -> List[MedicationLog]:
    query = db.query(MedicationLog)
    if date_str:
        query = query.filter(MedicationLog.date == date_str)
    return query.order_by(MedicationLog.taken_at.asc()).all()


# ---------------- Guided Physical Routines ----------------
def record_guided_session(db: Session, session_data: GuidedSessionCreate) -> GuidedSession:
    date_key = session_data.date or get_today_str()
    started = session_data.started_at or utc_now()
    completed = session_data.completed_at

    exercises_str = json.dumps(session_data.completed_exercises) if session_data.completed_exercises else None
    summary_str = json.dumps(session_data.reps_or_holds_summary) if session_data.reps_or_holds_summary else None

    duration = session_data.total_duration_seconds
    if duration <= 0 and completed and started:
        duration = max(0.0, (completed - started).total_seconds())

    record = GuidedSession(
        date=date_key,
        routine_type=session_data.routine_type,
        started_at=started,
        completed_at=completed,
        total_duration_seconds=duration,
        is_completed=session_data.is_completed,
        completed_exercises=exercises_str,
        sets_completed=session_data.sets_completed,
        total_sets=session_data.total_sets,
        reps_or_holds_summary=summary_str,
        notes=session_data.notes,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


# ---------------- Work Focus Sessions ----------------
def record_work_session(db: Session, work: WorkSessionCreate) -> WorkFocusSession:
    date_key = work.date or get_today_str()
    started = work.started_at or utc_now()
    ended = work.ended_at

    duration = work.duration_seconds
    if duration <= 0 and ended and started:
        duration = max(0.0, (ended - started).total_seconds())

    record_id = work.id or None

    existing = None
    if record_id:
        existing = db.query(WorkFocusSession).filter(WorkFocusSession.id == record_id).first()

    if existing:
        existing.title = work.title
        existing.project = work.project
        existing.started_at = started
        existing.ended_at = ended
        existing.duration_seconds = duration
        existing.is_completed = work.is_completed
        existing.exit_reason = work.exit_reason
        existing.runway_bucket = work.runway_bucket
        existing.linked_task_id = work.linked_task_id
        existing.is_overtime = work.is_overtime
        existing.interruption_notes = work.interruption_notes
        existing.remote_entry_id = work.remote_entry_id
        db.commit()
        db.refresh(existing)
        session_record = existing
    else:
        session_record = WorkFocusSession(
            date=date_key,
            title=work.title,
            project=work.project,
            started_at=started,
            ended_at=ended,
            duration_seconds=duration,
            is_completed=work.is_completed,
            exit_reason=work.exit_reason,
            runway_bucket=work.runway_bucket,
            linked_task_id=work.linked_task_id,
            is_overtime=work.is_overtime,
            interruption_notes=work.interruption_notes,
            remote_entry_id=work.remote_entry_id,
        )
        if record_id:
            session_record.id = record_id
        db.add(session_record)
        db.commit()
        db.refresh(session_record)

    # If sprint was interrupted or stopped due to fatigue, record friction log!
    if work.exit_reason in ["Interrupted", "Headache / Fatigue"]:
        f_log = FrictionLog(
            date=date_key,
            event_type="work_interruption",
            category="unproductive",
            friction_source=f"Sprint Interrupted: {work.exit_reason}",
            duration_loss_seconds=0.0,
            notes=work.interruption_notes or f"Session '{work.title}' ended prematurely due to {work.exit_reason}"
        )
        db.add(f_log)
        db.commit()

    return session_record


def get_work_sessions(db: Session, date_str: Optional[str] = None) -> List[WorkFocusSession]:
    query = db.query(WorkFocusSession)
    if date_str:
        query = query.filter(WorkFocusSession.date == date_str)
    return query.order_by(WorkFocusSession.started_at.desc()).all()


# ---------------- Night Cycle Event ----------------
def record_night_cycle(db: Session, event: NightCycleEventCreate) -> NightCycleEvent:
    date_key = event.date or get_today_str()
    triggered = event.alert_triggered_at or utc_now()
    dismissed = event.alert_dismissed_at

    latency = event.dismissal_latency_seconds
    if latency <= 0 and dismissed and triggered:
        latency = max(0.0, (dismissed - triggered).total_seconds())

    existing = db.query(NightCycleEvent).filter(NightCycleEvent.date == date_key).first()
    if existing:
        if dismissed:
            existing.alert_dismissed_at = dismissed
            existing.dismissal_latency_seconds = latency
        if event.night_routine_completed:
            existing.night_routine_completed = event.night_routine_completed
            existing.night_routine_completed_at = utc_now()
        if event.notes:
            existing.notes = event.notes
        db.commit()
        db.refresh(existing)
        return existing

    record = NightCycleEvent(
        date=date_key,
        alert_triggered_at=triggered,
        alert_dismissed_at=dismissed,
        dismissal_latency_seconds=latency,
        night_routine_completed=event.night_routine_completed,
        notes=event.notes,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


# ---------------- Friction Logs ----------------
def record_friction_log(db: Session, log: FrictionLogCreate) -> FrictionLog:
    date_key = log.date or get_today_str()
    record = FrictionLog(
        date=date_key,
        event_type=log.event_type,
        category=log.category,
        friction_source=log.friction_source,
        duration_loss_seconds=log.duration_loss_seconds,
        mitigation_hint=log.mitigation_hint,
        notes=log.notes,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_friction_logs(db: Session, date_str: Optional[str] = None) -> List[FrictionLog]:
    query = db.query(FrictionLog)
    if date_str:
        query = query.filter(FrictionLog.date == date_str)
    return query.order_by(FrictionLog.created_at.desc()).all()


# ---------------- Bulk State Synchronization ----------------
def process_bulk_sync(db: Session, payload: BulkSyncPayload) -> Dict[str, Any]:
    date_key = payload.date or get_today_str()
    counts = {
        "morning_tasks": 0,
        "night_tasks": 0,
        "medications": 0,
        "work_sessions": 0,
        "guided_sessions": 0,
    }

    # Backup raw snapshot
    raw_json = json.dumps(payload.model_dump(), default=str)
    snapshot = db.query(DailySnapshot).filter(DailySnapshot.date == date_key).first()
    if snapshot:
        snapshot.raw_json_state = raw_json
    else:
        snapshot = DailySnapshot(date=date_key, raw_json_state=raw_json)
        db.add(snapshot)
    db.commit()

    # Reconcile morning tasks
    if payload.morning_tasks:
        for t in payload.morning_tasks:
            task_id = str(t.get("id", ""))
            title = t.get("title", "Untitled Task")
            is_comp = bool(t.get("isCompleted", False))
            target_deadline = t.get("targetDeadlineTime")
            subtasks = t.get("subtasks")
            duration_allotted = t.get("durationMinutes")

            record_task_event(
                db,
                TaskEventCreate(
                    task_id=task_id,
                    task_title=title,
                    routine_period="morning",
                    date=date_key,
                    is_completed=is_comp,
                    target_deadline_time=target_deadline,
                    duration_minutes_allotted=duration_allotted,
                    subtasks_completed=subtasks if isinstance(subtasks, list) else None,
                ),
            )
            counts["morning_tasks"] += 1

    # Reconcile night tasks
    if payload.night_tasks:
        for t in payload.night_tasks:
            task_id = str(t.get("id", ""))
            title = t.get("title", "Untitled Task")
            is_comp = bool(t.get("isCompleted", False))

            record_task_event(
                db,
                TaskEventCreate(
                    task_id=task_id,
                    task_title=title,
                    routine_period="night",
                    date=date_key,
                    is_completed=is_comp,
                ),
            )
            counts["night_tasks"] += 1

    # Reconcile medications
    if payload.medications:
        for m in payload.medications:
            is_comp = bool(m.get("isCompleted", False))
            if is_comp:
                name = m.get("name", "Medication")
                period = m.get("period", "morning").lower()
                is_ome = bool(m.get("isOmeprazole", False))
                record_medication(
                    db,
                    MedicationLogCreate(
                        name=name,
                        period=period,
                        date=date_key,
                        medication_id=str(m.get("id", "")),
                        is_omeprazole=is_ome,
                        notes=m.get("notes"),
                    ),
                )
                counts["medications"] += 1

    # Reconcile work sessions
    if payload.work_sessions:
        for w in payload.work_sessions:
            sess_id = str(w.get("id", ""))
            title = w.get("title", "Work Sprint")
            project = w.get("project", "Work")
            exit_reason = w.get("exitReason")
            runway = w.get("runwayBucket")
            record_work_session(
                db,
                WorkSessionCreate(
                    id=sess_id,
                    title=title,
                    project=project,
                    date=date_key,
                    exit_reason=exit_reason,
                    runway_bucket=runway,
                ),
            )
            counts["work_sessions"] += 1

    return counts
