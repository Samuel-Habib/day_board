import pytest
import datetime
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield


client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "dayboard-persistence-api"


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "endpoints" in data
    assert data["endpoints"]["morning_routine"] == "/api/routines/morning"


def test_morning_routine_flow():
    today_str = datetime.date.today().isoformat()
    # 1. Start morning routine
    res = client.post(
        "/api/routines/morning",
        json={
            "date": today_str,
            "tasks_count": 8,
            "completed_tasks_count": 1,
            "start_delay_seconds": 120.0,
            "notes": "Testing morning initialization",
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["date"] == today_str
    assert data["tasks_count"] == 8
    assert data["completed_tasks_count"] == 1
    assert data["friction_score"] <= 100.0


def test_task_event_and_overdue_tracking():
    today_str = datetime.date.today().isoformat()
    task_id = "test-task-123"

    res = client.post(
        "/api/tasks/event",
        json={
            "date": today_str,
            "task_id": task_id,
            "task_title": "Bathroom",
            "routine_period": "morning",
            "routine_type": "bathroom",
            "target_deadline_time": "9:30 AM",
            "duration_minutes_allotted": 25,
            "actual_duration_seconds": 1800.0, # 30 min (5 min overdue)
            "is_completed": True,
            "is_overdue": True,
            "overdue_seconds": 300.0,
            "subtasks_completed": ["Shave", "Shower", "Cleanse", "Sunscreen"],
            "friction_notes": "Took longer due to shaving",
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["task_id"] == task_id
    assert data["task_title"] == "Bathroom"
    assert data["is_overdue"] is True
    assert data["overdue_seconds"] == 300.0


def test_medications_and_omeprazole_window():
    today_str = datetime.date.today().isoformat()
    now = datetime.datetime.now(datetime.timezone.utc)

    # 1. Log Omeprazole
    res = client.post(
        "/api/medications/log",
        json={
            "date": today_str,
            "name": "Omeprazole (Prilosec)",
            "period": "morning",
            "is_omeprazole": True,
            "taken_at": now.isoformat(),
            "notes": "Empty stomach morning dose",
        },
    )
    assert res.status_code == 200
    med_data = res.json()
    assert med_data["is_omeprazole"] is True
    assert med_data["eating_window_open_at"] is not None

    # 2. Check live status
    status_res = client.get(f"/api/medications/omeprazole-status?date={today_str}")
    assert status_res.status_code == 200
    status_data = status_res.json()
    assert status_data["status"] in ["waiting", "window_open", "window_closed"]

    # 3. Log Breakfast eating event
    eat_time = now + datetime.timedelta(minutes=35)
    eat_res = client.post(
        "/api/medications/eating-event",
        json={
            "date": today_str,
            "food_consumed_at": eat_time.isoformat(),
            "notes": "Eggs & toast",
        },
    )
    assert eat_res.status_code == 200
    eat_data = eat_res.json()
    assert eat_data["ate_within_window"] is True


def test_guided_session():
    today_str = datetime.date.today().isoformat()
    res = client.post(
        "/api/guided/session",
        json={
            "date": today_str,
            "routine_type": "foot",
            "total_duration_seconds": 320.0,
            "is_completed": True,
            "completed_exercises": ["Plantar Fascia Stretch", "Straight-Knee Calf", "Calf Raises"],
            "sets_completed": 2,
            "total_sets": 2,
            "notes": "Full foot rehabilitation protocol completed",
        },
    )
    assert res.status_code == 200
    assert res.json()["routine_type"] == "foot"
    assert res.json()["is_completed"] is True


def test_work_focus_session():
    today_str = datetime.date.today().isoformat()
    res = client.post(
        "/api/work/session",
        json={
            "date": today_str,
            "title": "Embedded Firmware Sprint",
            "project": "Work",
            "duration_seconds": 2700.0, # 45 mins
            "is_completed": True,
            "exit_reason": "Completed",
            "runway_bucket": "Technical Hands-on",
            "is_overtime": False,
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["title"] == "Embedded Firmware Sprint"
    assert data["duration_seconds"] == 2700.0


def test_bulk_sync_and_analytics():
    today_str = datetime.date.today().isoformat()
    payload = {
        "date": today_str,
        "morning_tasks": [
            {"id": "task-1", "title": "Teeth & Prep", "isCompleted": True, "targetDeadlineTime": "8:25 AM"},
            {"id": "task-2", "title": "Meds", "isCompleted": True, "targetDeadlineTime": "8:30 AM"},
            {"id": "task-3", "title": "Stretch", "isCompleted": True, "targetDeadlineTime": "8:40 AM"},
        ],
        "medications": [
            {"id": "med-1", "name": "Vitamin D3", "period": "morning", "isCompleted": True}
        ],
        "work_sessions": [
            {"id": "work-1", "title": "Architecture Review", "project": "Design", "exitReason": "Completed"}
        ]
    }

    sync_res = client.post("/api/sync/state", json=payload)
    assert sync_res.status_code == 200
    assert sync_res.json()["status"] == "success"

    # Query today's analytics
    analytics_res = client.get(f"/api/analytics/today?date={today_str}")
    assert analytics_res.status_code == 200
    a_data = analytics_res.json()
    assert a_data["date"] == today_str
    assert a_data["completed_morning_tasks"] >= 3
    assert "friction_score" in a_data
