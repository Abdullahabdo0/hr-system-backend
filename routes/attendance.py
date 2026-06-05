from fastapi import APIRouter, Depends, HTTPException, Form, Query
from sqlalchemy.orm import Session
from database import get_db
from models import Attendance
from schemas import AttendanceCreate, AttendanceResponse
from datetime import datetime
from typing import Optional

router = APIRouter()


@router.get("", response_model=list[AttendanceResponse])
def get_attendance(
    employee_id: Optional[int] = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(Attendance)
    if employee_id is not None:
        query = query.filter(Attendance.employee_id == employee_id)
    return query.order_by(Attendance.date.desc()).all()


@router.get("/{attendance_id}", response_model=AttendanceResponse)
def get_attendance_record(attendance_id: int, db: Session = Depends(get_db)):
    attendance = db.query(Attendance).filter(Attendance.id == attendance_id).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="سجل الحضور غير موجود")
    return attendance


@router.post("", response_model=AttendanceResponse)
def create_attendance(attendance: AttendanceCreate, db: Session = Depends(get_db)):
    db_attendance = Attendance(**attendance.model_dump())
    db.add(db_attendance)
    db.commit()
    db.refresh(db_attendance)
    return db_attendance


@router.post("/check-in")
def check_in(employee_id: str = Form(...), db: Session = Depends(get_db)):
    employee_id_int = int(employee_id)
    now = datetime.now()
    today = datetime(now.year, now.month, now.day)

    existing = db.query(Attendance).filter(
        Attendance.employee_id == employee_id_int,
        Attendance.date == today,
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="تم تسجيل الدخول بالفعل اليوم")

    attendance = Attendance(
        employee_id=employee_id_int,
        date=today,
        check_in_time=now,
        status="present",
    )
    db.add(attendance)
    db.commit()
    db.refresh(attendance)
    return attendance


@router.post("/check-out")
def check_out(employee_id: str = Form(...), db: Session = Depends(get_db)):
    employee_id_int = int(employee_id)
    now = datetime.now()
    today = datetime(now.year, now.month, now.day)

    attendance = db.query(Attendance).filter(
        Attendance.employee_id == employee_id_int,
        Attendance.date == today,
    ).first()

    if not attendance:
        raise HTTPException(status_code=400, detail="لم يتم تسجيل الدخول اليوم")

    if attendance.check_out_time:
        raise HTTPException(status_code=400, detail="تم تسجيل الخروج بالفعل")

    attendance.check_out_time = now
    if attendance.check_in_time:
        total_hours = (now - attendance.check_in_time).total_seconds() / 3600
        attendance.total_hours = round(total_hours, 2)

    db.commit()
    db.refresh(attendance)
    return attendance


@router.delete("/{attendance_id}")
def delete_attendance(attendance_id: int, db: Session = Depends(get_db)):
    attendance = db.query(Attendance).filter(Attendance.id == attendance_id).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="سجل الحضور غير موجود")

    db.delete(attendance)
    db.commit()
    return {"message": "تم حذف سجل الحضور بنجاح"}
