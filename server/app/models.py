import datetime
import uuid
from sqlalchemy import (
    Column,
    String,
    Boolean,
    Float,
    Integer,
    Text,
    DateTime,
    Index
)
from app.database import Base


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc)


def ensure_utc(dt: datetime.datetime | None) -> datetime.datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=datetime.timezone.utc)
    return dt.astimezone(datetime.timezone.utc)


class MorningRoutine(Base):
    """
    Tracks daily morning routine execution.
    Target schedule: Starts at 08:15 AM, finishes by 10:00 AM (1h 45m window).
    """
    __tablename__ = "morning_routines"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), unique=True, nullable=False, index=True)  # YYYY-MM-DD
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    is_completed = Column(Boolean, default=False, nullable=False)
    total_duration_seconds = Column(Float, default=0.0)
    tasks_count = Column(Integer, default=8)
    completed_tasks_count = Column(Integer, default=0)
    target_start_time = Column(String(10), default="08:15 AM")
    target_end_time = Column(String(10), default="10:00 AM")
    start_delay_seconds = Column(Float, default=0.0)  # Seconds past 8:15 AM
    total_overdue_seconds = Column(Float, default=0.0) # Cumulative task deadline slippage
    friction_score = Column(Float, default=100.0)      # 0-100 flow score (100 = seamless, 0 = high friction)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class NightRoutine(Base):
    """
    Tracks nightly wind-down routine execution.
    """
    __tablename__ = "night_routines"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), unique=True, nullable=False, index=True)  # YYYY-MM-DD
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    is_completed = Column(Boolean, default=False, nullable=False)
    total_duration_seconds = Column(Float, default=0.0)
    tasks_count = Column(Integer, default=4)
    completed_tasks_count = Column(Integer, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class TaskEvent(Base):
    """
    Fine-grained log of every habit/task execution milestone.
    Logs exact times, target deadline adherence, subtasks, and friction.
    """
    __tablename__ = "task_events"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), nullable=False, index=True)  # YYYY-MM-DD
    routine_period = Column(String(20), nullable=False, index=True)  # "morning", "night", "daily"
    task_id = Column(String(36), nullable=False, index=True)        # UUID from Apple TV
    task_title = Column(String(255), nullable=False, index=True)
    routine_type = Column(String(50), nullable=True)                # "foot", "stretching", "exercise", "meds", "bathroom", "general"
    target_deadline_time = Column(String(20), nullable=True)        # e.g. "8:25 AM"
    duration_minutes_allotted = Column(Integer, nullable=True)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    actual_duration_seconds = Column(Float, default=0.0)
    is_completed = Column(Boolean, default=True, nullable=False)
    is_overdue = Column(Boolean, default=False, nullable=False)
    overdue_seconds = Column(Float, default=0.0)                   # Seconds past target deadline
    subtasks_completed = Column(Text, nullable=True)               # JSON array string: ["Shave","Shower"]
    friction_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    __table_args__ = (
        Index("ix_task_date_period", "date", "routine_period"),
    )


class MedicationLog(Base):
    """
    Tracks medication intake, with dedicated medical timing for Omeprazole.
    Omeprazole requires 30-60 min wait before eating breakfast.
    """
    __tablename__ = "medication_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), nullable=False, index=True)  # YYYY-MM-DD
    medication_id = Column(String(36), nullable=True)
    name = Column(String(255), nullable=False, index=True)
    period = Column(String(20), nullable=False, index=True) # "morning", "night"
    taken_at = Column(DateTime(timezone=True), nullable=False, index=True)
    is_omeprazole = Column(Boolean, default=False, nullable=False)
    wait_window_minutes = Column(Integer, default=30)
    eating_window_open_at = Column(DateTime(timezone=True), nullable=True)  # taken_at + 30m
    eating_window_close_at = Column(DateTime(timezone=True), nullable=True) # taken_at + 60m
    food_consumed_at = Column(DateTime(timezone=True), nullable=True)
    ate_within_window = Column(Boolean, nullable=True)                      # True if between open & close
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class GuidedSession(Base):
    """
    Tracks physical guided routines: Foot Rehabilitation, Mobility/Stretching, Bodyweight Workout.
    """
    __tablename__ = "guided_sessions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), nullable=False, index=True)  # YYYY-MM-DD
    routine_type = Column(String(50), nullable=False, index=True) # "foot", "stretching", "exercise"
    started_at = Column(DateTime(timezone=True), nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    total_duration_seconds = Column(Float, default=0.0)
    is_completed = Column(Boolean, default=False, nullable=False)
    completed_exercises = Column(Text, nullable=True) # JSON list of exercise names or IDs
    sets_completed = Column(Integer, default=0)
    total_sets = Column(Integer, default=0)
    reps_or_holds_summary = Column(Text, nullable=True) # JSON details
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class WorkFocusSession(Base):
    """
    Tracks Deep Work & Focus sprints on Apple TV Work & Focus Hub.
    """
    __tablename__ = "work_focus_sessions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), nullable=False, index=True) # YYYY-MM-DD
    title = Column(String(255), nullable=False, default="Deep Work")
    project = Column(String(100), default="Work", index=True)
    started_at = Column(DateTime(timezone=True), nullable=False, index=True)
    ended_at = Column(DateTime(timezone=True), nullable=True)
    duration_seconds = Column(Float, default=0.0)
    is_completed = Column(Boolean, default=False, nullable=False)
    exit_reason = Column(String(50), nullable=True)  # "Completed", "Interrupted", "Headache / Fatigue"
    runway_bucket = Column(String(50), nullable=True) # "Analog / Grounding", "Reading / Absorption", "Technical Hands-on"
    linked_task_id = Column(String(36), nullable=True)
    is_overtime = Column(Boolean, default=False)
    interruption_notes = Column(Text, nullable=True)
    remote_entry_id = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class NightCycleEvent(Base):
    """
    Tracks 10 PM PSA night alert trigger, reaction time, and bedtime enforcement.
    """
    __tablename__ = "night_cycle_events"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), unique=True, nullable=False, index=True) # YYYY-MM-DD
    alert_triggered_at = Column(DateTime(timezone=True), nullable=False)
    alert_dismissed_at = Column(DateTime(timezone=True), nullable=True)
    dismissal_latency_seconds = Column(Float, default=0.0)
    night_routine_completed = Column(Boolean, default=False)
    night_routine_completed_at = Column(DateTime(timezone=True), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class FrictionLog(Base):
    """
    Tracks friction bottlenecks, distractions, delays, and flow breakers.
    Used to optimize mornings: create friction in unproductive areas and eliminate friction in high-value areas.
    """
    __tablename__ = "friction_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), nullable=False, index=True) # YYYY-MM-DD
    event_type = Column(String(50), nullable=False, index=True) # "morning_overdue", "meds_timing_breach", "routine_stalled", "work_interruption", "late_night_overrun", "friction_observation"
    category = Column(String(20), default="unproductive", index=True) # "unproductive" (friction to remove) or "productive" (intentional brake/friction)
    friction_source = Column(String(255), nullable=False) # e.g. "Bathroom Bottleneck", "Phone Distraction", "Headache", "Screen Fatigue"
    duration_loss_seconds = Column(Float, default=0.0)
    mitigation_hint = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class DailySnapshot(Base):
    """
    Full JSON snapshot backup of dashboard state for resilience and cross-device sync.
    """
    __tablename__ = "daily_snapshots"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(String(10), unique=True, nullable=False, index=True) # YYYY-MM-DD
    raw_json_state = Column(Text, nullable=False) # Serialized JSON of all tasks, meds, work sessions
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
