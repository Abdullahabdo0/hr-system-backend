from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from sqlalchemy.orm import Session
from database import get_db
from models import Employee, Attendance, Leave, SalaryPayment, PerformanceReview, User
from schemas import EmployeeCreate, EmployeeUpdate, EmployeeResponse
from datetime import datetime
import os
import shutil

router = APIRouter()


@router.get("", response_model=list[EmployeeResponse])
def get_employees(db: Session = Depends(get_db)):
    return db.query(Employee).all()


@router.post("", response_model=EmployeeResponse)
def create_employee(employee: EmployeeCreate, db: Session = Depends(get_db)):
    # Check duplicate email
    existing = db.query(Employee).filter(Employee.email == employee.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="البريد الإلكتروني مستخدم بالفعل")
    db_employee = Employee(**employee.model_dump())
    db.add(db_employee)
    db.commit()
    db.refresh(db_employee)
    return db_employee


@router.post("/upload-image/{employee_id}")
async def upload_image(
    employee_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    db_employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not db_employee:
        raise HTTPException(status_code=404, detail="الموظف غير موجود")

    # Validate file type
    allowed_extensions = {"jpg", "jpeg", "png", "gif", "webp"}
    file_extension = (file.filename or "").split(".")[-1].lower()
    if file_extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="نوع الملف غير مسموح به")

    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)

    file_name = f"profile_{employee_id}.{file_extension}"
    file_path = os.path.join(upload_dir, file_name)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    db_employee.profile_picture_url = f"/api/employees/image/{file_name}"
    db.commit()

    return {"url": db_employee.profile_picture_url}


@router.get("/{employee_id}", response_model=EmployeeResponse)
def get_employee(employee_id: int, db: Session = Depends(get_db)):
    employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not employee:
        raise HTTPException(status_code=404, detail="الموظف غير موجود")
    return employee


@router.put("/{employee_id}", response_model=EmployeeResponse)
def update_employee(
    employee_id: int, employee: EmployeeUpdate, db: Session = Depends(get_db)
):
    db_employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not db_employee:
        raise HTTPException(status_code=404, detail="الموظف غير موجود")

    # Only update fields that were explicitly sent (exclude_unset=True)
    update_data = employee.model_dump(exclude_unset=True)

    # Check email uniqueness if being changed
    if "email" in update_data and update_data["email"] != db_employee.email:
        existing = (
            db.query(Employee)
            .filter(Employee.email == update_data["email"], Employee.id != employee_id)
            .first()
        )
        if existing:
            raise HTTPException(status_code=400, detail="البريد الإلكتروني مستخدم بالفعل")

    for key, value in update_data.items():
        setattr(db_employee, key, value)

    db.commit()
    db.refresh(db_employee)
    return db_employee


@router.delete("/{employee_id}")
def delete_employee(employee_id: int, db: Session = Depends(get_db)):
    try:
        db_employee = db.query(Employee).filter(Employee.id == employee_id).first()
        if not db_employee:
            raise HTTPException(status_code=404, detail="الموظف غير موجود")

        db.query(Attendance).filter(Attendance.employee_id == employee_id).delete()
        db.query(Leave).filter(Leave.employee_id == employee_id).delete()
        db.query(SalaryPayment).filter(SalaryPayment.employee_id == employee_id).delete()
        db.query(PerformanceReview).filter(PerformanceReview.employee_id == employee_id).delete()
        db.query(User).filter(User.employee_id == employee_id).delete()

        db.delete(db_employee)
        db.commit()
        return {"message": "تم حذف الموظف بنجاح"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في الحذف: {str(e)}")
