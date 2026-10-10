import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict


# ------------------ Task Events ------------------
class TaskEventCreate(BaseModel):
    task_id: str
    task_title: str
    routine_period: str = "morning"  # "morning", "night", "daily"
    date: Optional[str] = None       # YYYY-MM-DD (defaults to today)
    routine_type: Optional[str] = None
    target_deadline_time: Optional[str] = None
    duration_minutes_allotted: Optional[int] = None
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    actual_duration_seconds: float = 0.0
    is_completed: bool = True
    is_overdue: bool = False
    overdue_seconds: float = 0.0
    subtasks_completed: Optional[List[str]] = None
    friction_notes: Optional[str] = None


class TaskEventResponse(BaseModel):
    id: str
    date: str
    routine_period: str
    task_id: str
    task_title: str
    routine_type: Optional[str] = None
    target_deadline_time: Optional[str] = None
    duration_minutes_allotted: Optional[int] = None
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    actual_duration_seconds: float
    is_completed: bool
    is_overdue: bool
    overdue_seconds: float
    subtasks_completed: Optional[str] = None
    friction_notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Morning Routines ------------------
class MorningRoutineUpdate(BaseModel):
    date: Optional[str] = None
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    is_completed: Optional[bool] = None
    total_duration_seconds: Optional[float] = None
    tasks_count: Optional[int] = None
    completed_tasks_count: Optional[int] = None
    start_delay_seconds: Optional[float] = None
    total_overdue_seconds: Optional[float] = None
    notes: Optional[str] = None


class MorningRoutineResponse(BaseModel):
    id: str
    date: str
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    is_completed: bool
    total_duration_seconds: float
    tasks_count: int
    completed_tasks_count: int
    target_start_time: str
    target_end_time: str
    start_delay_seconds: float
    total_overdue_seconds: float
    friction_score: float
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Night Routines ------------------
class NightRoutineUpdate(BaseModel):
    date: Optional[str] = None
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    is_completed: Optional[bool] = None
    total_duration_seconds: Optional[float] = None
    tasks_count: Optional[int] = None
    completed_tasks_count: Optional[int] = None
    notes: Optional[str] = None


class NightRoutineResponse(BaseModel):
    id: str
    date: str
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    is_completed: bool
    total_duration_seconds: float
    tasks_count: int
    completed_tasks_count: int
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Medications ------------------
class MedicationLogCreate(BaseModel):
    name: str
    period: str = "morning"
    date: Optional[str] = None
    medication_id: Optional[str] = None
    taken_at: Optional[datetime.datetime] = None
    is_omeprazole: bool = False
    notes: Optional[str] = None


class EatingEventCreate(BaseModel):
    date: Optional[str] = None
    food_consumed_at: Optional[datetime.datetime] = None
    notes: Optional[str] = None


class MedicationLogResponse(BaseModel):
    id: str
    date: str
    medication_id: Optional[str] = None
    name: str
    period: str
    taken_at: datetime.datetime
    is_omeprazole: bool
    wait_window_minutes: int
    eating_window_open_at: Optional[datetime.datetime] = None
    eating_window_close_at: Optional[datetime.datetime] = None
    food_consumed_at: Optional[datetime.datetime] = None
    ate_within_window: Optional[bool] = None
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Guided Physical Routines ------------------
class GuidedSessionCreate(BaseModel):
    routine_type: str  # "foot", "stretching", "exercise"
    date: Optional[str] = None
    started_at: Optional[datetime.datetime] = None
    completed_at: Optional[datetime.datetime] = None
    total_duration_seconds: float = 0.0
    is_completed: bool = True
    completed_exercises: Optional[List[str]] = None
    sets_completed: int = 0
    total_sets: int = 0
    reps_or_holds_summary: Optional[Any] = None
    notes: Optional[str] = None


class GuidedSessionResponse(BaseModel):
    id: str
    date: str
    routine_type: str
    started_at: datetime.datetime
    completed_at: Optional[datetime.datetime] = None
    total_duration_seconds: float
    is_completed: bool
    completed_exercises: Optional[str] = None
    sets_completed: int
    total_sets: int
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Work Focus Hub ------------------
class WorkSessionCreate(BaseModel):
    id: Optional[str] = None
    title: str = "Deep Work"
    project: str = "Work"
    date: Optional[str] = None
    started_at: Optional[datetime.datetime] = None
    ended_at: Optional[datetime.datetime] = None
    duration_seconds: float = 0.0
    is_completed: bool = True
    exit_reason: Optional[str] = "Completed"
    runway_bucket: Optional[str] = "Technical Hands-on"
    linked_task_id: Optional[str] = None
    is_overtime: bool = False
    interruption_notes: Optional[str] = None
    remote_entry_id: Optional[int] = None


class WorkSessionResponse(BaseModel):
    id: str
    date: str
    title: str
    project: str
    started_at: datetime.datetime
    ended_at: Optional[datetime.datetime] = None
    duration_seconds: float
    is_completed: bool
    exit_reason: Optional[str] = None
    runway_bucket: Optional[str] = None
    linked_task_id: Optional[str] = None
    is_overtime: bool
    interruption_notes: Optional[str] = None
    remote_entry_id: Optional[int] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Night Cycle Event (10 PM Alert) ------------------
class NightCycleEventCreate(BaseModel):
    date: Optional[str] = None
    alert_triggered_at: Optional[datetime.datetime] = None
    alert_dismissed_at: Optional[datetime.datetime] = None
    dismissal_latency_seconds: float = 0.0
    night_routine_completed: bool = False
    notes: Optional[str] = None


class NightCycleResponse(BaseModel):
    id: str
    date: str
    alert_triggered_at: datetime.datetime
    alert_dismissed_at: Optional[datetime.datetime] = None
    dismissal_latency_seconds: float
    night_routine_completed: bool
    night_routine_completed_at: Optional[datetime.datetime] = None
    notes: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# ------------------ Friction Logs ------------------
class FrictionLogCreate(BaseModel):
    event_type: str
    category: str = "unproductive"  # "unproductive" or "productive"
    friction_source: str
    date: Optional[str] = None
    duration_loss_seconds: float = 0.0
    mitigation_hint: Optional[str] = None
    notes: Optional[str] = None


class FrictionLogResponse(BaseModel):
    id: str
    date: str
    event_type: str
    category: str
    friction_source: str
    duration_loss_seconds: float
    mitigation_hint: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------ Bulk Synchronization ------------------
class BulkSyncPayload(BaseModel):
    date: Optional[str] = None
    morning_tasks: Optional[List[dict]] = None
    night_tasks: Optional[List[dict]] = None
    daily_tasks: Optional[List[dict]] = None
    medications: Optional[List[dict]] = None
    work_sessions: Optional[List[dict]] = None
    foot_sessions: Optional[List[dict]] = None
    stretching_sessions: Optional[List[dict]] = None
    bodyweight_sessions: Optional[List[dict]] = None
    routine_sessions: Optional[List[dict]] = None
    client_version: Optional[str] = "StupidDashBoard-tvOS-26.2"


class BulkSyncResponse(BaseModel):
    status: str
    date: str
    synced_items: dict
    message: str


# ------------------ Analytics & Insights ------------------
class TodayAnalyticsResponse(BaseModel):
    date: str
    morning_routine: Optional[MorningRoutineResponse] = None
    night_routine: Optional[NightRoutineResponse] = None
    completed_morning_tasks: int
    total_morning_tasks: int
    morning_progress_percent: float
    is_morning_complete: bool
    omeprazole_status: dict
    focus_sprints_count: int
    total_focus_minutes: float
    friction_score: float
    friction_alerts: List[str]


class TrendsSummaryResponse(BaseModel):
    days_analyzed: int
    average_morning_duration_minutes: float
    morning_completion_rate: float
    average_start_time: str
    most_frequent_bottlenecks: List[dict]
    total_focus_hours: float
    curfew_compliance_rate: float
    average_friction_score: float
