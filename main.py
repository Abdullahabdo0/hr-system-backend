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
    auth
)

# Create tables
Base.metadata.create_all(bind=engine)

def ensure_employee_columns():
    inspector = inspect(engine)
    columns = {column["name"] for column in inspector.get_columns("employees")}
    required_columns = {
        "location": "ALTER TABLE employees ADD COLUMN location VARCHAR",
        "national_id": "ALTER TABLE employees ADD COLUMN national_id VARCHAR",
        "qualification": "ALTER TABLE employees ADD COLUMN qualification VARCHAR",
        "address": "ALTER TABLE employees ADD COLUMN address TEXT",
        "profile_picture_url": "ALTER TABLE employees ADD COLUMN profile_picture_url TEXT",
    }

    with engine.begin() as connection:
        for column_name, statement in required_columns.items():
            if column_name not in columns:
                connection.execute(text(statement))

ensure_employee_columns()

def create_default_admin():
    db = SessionLocal()
    try:
        existing_admin = db.query(User).filter(User.username == "admin").first()
        if not existing_admin:
            password_bytes = "admin".encode('utf-8')
            salt = bcrypt.gensalt()
            hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
            admin_user = User(
                username="admin",
                password=hashed_password,
                role="admin"
            )
            db.add(admin_user)
            db.commit()
            print("Default admin user created: username=admin, password=admin")
    except Exception as e:
        print(f"Error creating default admin user: {e}")
        db.rollback()
    finally:
        db.close()

create_default_admin()

app = FastAPI(title="HR System API", version="1.0.0")

# Create uploads directory if not exists
if not os.path.exists("uploads"):
    os.makedirs("uploads")

# Mount static files
app.mount("/api/employees/image", StaticFiles(directory="uploads"), name="profile_images")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(employees.router, prefix="/api/employees", tags=["employees"])
app.include_router(attendance.router, prefix="/api/attendance", tags=["attendance"])
app.include_router(leaves.router, prefix="/api/leaves", tags=["leaves"])
app.include_router(salary.router, prefix="/api/salary", tags=["salary"])
app.include_router(performance.router, prefix="/api/performance", tags=["performance"])
app.include_router(audit.router, prefix="/api/audit", tags=["audit"])
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])

@app.get("/")
def read_root():
    return {"message": "HR System API is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
