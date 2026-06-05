from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from database import engine, Base, SessionLocal
from models import User
from sqlalchemy import inspect, text
import bcrypt
from routes import (
    employees,
    attendance,
    leaves,
    salary,
    performance,
    audit,
    auth,
    applicants,
    communications,
    notifications,
)

# ── Create all tables ────────────────────────────────────────────────────────
Base.metadata.create_all(bind=engine)


def ensure_extra_columns():
    """Add any columns that may be missing from older DB schemas."""
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    # --- employees table ---
    if "employees" in tables:
        existing_cols = {c["name"] for c in inspector.get_columns("employees")}
        employee_extra = {
            "location": "ALTER TABLE employees ADD COLUMN location VARCHAR",
            "national_id": "ALTER TABLE employees ADD COLUMN national_id VARCHAR",
            "qualification": "ALTER TABLE employees ADD COLUMN qualification VARCHAR",
            "address": "ALTER TABLE employees ADD COLUMN address TEXT",
            "profile_picture_url": "ALTER TABLE employees ADD COLUMN profile_picture_url TEXT",
        }
        with engine.begin() as conn:
            for col, stmt in employee_extra.items():
                if col not in existing_cols:
                    conn.execute(text(stmt))

    # --- attendance table ---
    if "attendance" in tables:
        existing_cols = {c["name"] for c in inspector.get_columns("attendance")}
        attendance_extra = {
            "notes": "ALTER TABLE attendance ADD COLUMN notes TEXT",
        }
        with engine.begin() as conn:
            for col, stmt in attendance_extra.items():
                if col not in existing_cols:
                    conn.execute(text(stmt))


ensure_extra_columns()


def create_default_admin():
    db = SessionLocal()
    try:
        existing_admin = db.query(User).filter(User.username == "admin").first()
        if not existing_admin:
            password_bytes = "admin".encode("utf-8")
            salt = bcrypt.gensalt()
            hashed_password = bcrypt.hashpw(password_bytes, salt).decode("utf-8")
            admin_user = User(
                username="admin",
                password=hashed_password,
                role="admin",
            )
            db.add(admin_user)
            db.commit()
            print("✅ Default admin user created: username=admin, password=admin")
    except Exception as e:
        print(f"❌ Error creating default admin user: {e}")
        db.rollback()
    finally:
        db.close()


create_default_admin()

# ── Application ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="HR System API",
    version="2.0.0",
    description="نظام إدارة الموارد البشرية - Human Resources Management API",
)

# ── Static files (uploads) ───────────────────────────────────────────────────
UPLOAD_DIR = "/tmp/uploads" if os.getenv("VERCEL") else "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ── CORS ──────────────────────────────────────────────────────────────────────
# In production restrict origins to your actual frontend domain
ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "*",  # fallback: allow all (fine for dev / internal apps)
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth.router,            prefix="/api/auth",           tags=["auth"])
app.include_router(employees.router,       prefix="/api/employees",      tags=["employees"])
app.include_router(attendance.router,      prefix="/api/attendance",     tags=["attendance"])
app.include_router(leaves.router,          prefix="/api/leaves",         tags=["leaves"])
app.include_router(salary.router,          prefix="/api/salary",         tags=["salary"])
app.include_router(performance.router,     prefix="/api/performance",    tags=["performance"])
app.include_router(audit.router,           prefix="/api/audit",          tags=["audit"])
app.include_router(applicants.router,      prefix="/api/applicants",     tags=["applicants"])
app.include_router(communications.router,  prefix="/api/communications", tags=["communications"])
app.include_router(notifications.router,   prefix="/api/notifications",  tags=["notifications"])

# ── Static files mount (AFTER routers so /api/employees routes take priority) ─
app.mount("/api/employees/image", StaticFiles(directory=UPLOAD_DIR), name="profile_images")


# ── Health endpoints ──────────────────────────────────────────────────────────
@app.get("/", tags=["health"])
def read_root():
    return {"message": "HR System API is running", "version": "2.0.0"}


@app.get("/health", tags=["health"])
def health_check():
    try:
        # Quick DB ping
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": str(e)}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8004))
    uvicorn.run(app, host="0.0.0.0", port=port)
