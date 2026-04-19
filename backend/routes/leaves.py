from fastapi import APIRouter, Depends, HTTPException, Form
from sqlalchemy.orm import Session
from database import get_db
from models import Leave
from schemas import LeaveCreate, LeaveResponse
from datetime import datetime

router = APIRouter()

@router.get("", response_model=list[LeaveResponse])
def get_leaves(employee_id: int = None, db: Session = Depends(get_db)):
    query = db.query(Leave)
    if employee_id:
        query = query.filter(Leave.employee_id == employee_id)
    return query.all()

@router.get("/{leave_id}", response_model=LeaveResponse)
def get_leave(leave_id: int, db: Session = Depends(get_db)):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="طلب الإجازة غير موجود")
    return leave

@router.post("", response_model=LeaveResponse)
def create_leave(leave: LeaveCreate, db: Session = Depends(get_db)):
    db_leave = Leave(
        **leave.dict(),
        created_at=datetime.now()
    )
    db.add(db_leave)
    db.commit()
    db.refresh(db_leave)
    return db_leave

@router.put("/{leave_id}/approve")
def approve_leave(leave_id: int, approved_by: int = Form(...), db: Session = Depends(get_db)):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="طلب الإجازة غير موجود")
    
    leave.status = 'approved'
    leave.approved_at = datetime.now()
    leave.approved_by = approved_by
    
    db.commit()
    db.refresh(leave)
    return leave

@router.put("/{leave_id}/reject")
def reject_leave(leave_id: int, db: Session = Depends(get_db)):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="طلب الإجازة غير موجود")
    
    leave.status = 'rejected'
    
    db.commit()
    db.refresh(leave)
    return leave

@router.delete("/{leave_id}")
def delete_leave(leave_id: int, db: Session = Depends(get_db)):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="طلب الإجازة غير موجود")
    
    db.delete(leave)
    db.commit()
    return {"message": "تم حذف طلب الإجازة بنجاح"}
