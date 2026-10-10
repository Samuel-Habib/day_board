from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, Base
from app.routers import (
    routines,
    tasks,
    medications,
    guided,
    work,
    friction,
    sync,
    analytics,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize SQLite schema and tables
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Stupid DashBoard Persistence API",
    description="High-performance ambient persistence & behavioral friction engine for Apple TV Stupid DashBoard.",
    version="1.0.0",
    lifespan=lifespan,
)

# Enable CORS for all local dashboard clients & web interfaces
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(routines.router)
app.include_router(tasks.router)
app.include_router(medications.router)
app.include_router(guided.router)
app.include_router(work.router)
app.include_router(friction.router)
app.include_router(sync.router)
app.include_router(analytics.router)


@app.get("/health", tags=["System"])
def health():
    return {
        "status": "healthy",
        "service": "dayboard-persistence-api",
        "environment": settings.ENVIRONMENT,
        "database": settings.DATABASE_PATH,
    }


@app.get("/", tags=["System"])
def root():
    return {
        "service": "Stupid DashBoard Persistence API",
        "version": "1.0.0",
        "docs_url": "/docs",
        "health_url": "/health",
        "endpoints": {
            "morning_routine": "/api/routines/morning",
            "night_routine": "/api/routines/night",
            "task_events": "/api/tasks/event",
            "medications": "/api/medications/log",
            "omeprazole_status": "/api/medications/omeprazole-status",
            "guided_sessions": "/api/guided/session",
            "work_sessions": "/api/work/session",
            "friction_logs": "/api/friction/log",
            "bulk_sync": "/api/sync/state",
            "today_analytics": "/api/analytics/today",
            "trends": "/api/analytics/trends",
        }
    }
