from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Employee, Attendance, Leave, SalaryPayment, PerformanceReview, User
from schemas import EmployeeCreate, EmployeeUpdate, EmployeeResponse
from datetime import datetime

router = APIRouter()

@router.get("", response_model=list[EmployeeResponse])
def get_employees(db: Session = Depends(get_db)):
    return db.query(Employee).all()

@router.get("/{employee_id}", response_model=EmployeeResponse)
def get_employee(employee_id: int, db: Session = Depends(get_db)):
    employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not employee:
        raise HTTPException(status_code=404, detail="الموظف غير موجود")
    return employee

@router.post("", response_model=EmployeeResponse)
def create_employee(employee: EmployeeCreate, db: Session = Depends(get_db)):
    db_employee = Employee(**employee.dict())
    db.add(db_employee)
    db.commit()
    db.refresh(db_employee)
    return db_employee

@router.put("/{employee_id}", response_model=EmployeeResponse)
def update_employee(employee_id: int, employee: EmployeeUpdate, db: Session = Depends(get_db)):
    db_employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not db_employee:
        raise HTTPException(status_code=404, detail="الموظف غير موجود")
    
    for key, value in employee.dict().items():
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
        
        # Delete related records
        db.query(Attendance).filter(Attendance.employee_id == employee_id).delete()
        db.query(Leave).filter(Leave.employee_id == employee_id).delete()
        db.query(SalaryPayment).filter(SalaryPayment.employee_id == employee_id).delete()
        db.query(PerformanceReview).filter(PerformanceReview.employee_id == employee_id).delete()
        db.query(User).filter(User.employee_id == employee_id).delete()
        
        db.delete(db_employee)
        db.commit()
        return {"message": "تم حذف الموظف بنجاح"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في الحذف: {str(e)}")
