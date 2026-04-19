from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import AuditLog
from schemas import AuditLogCreate, AuditLogResponse
from datetime import datetime

router = APIRouter()

@router.get("", response_model=list[AuditLogResponse])
def get_audit_logs(db: Session = Depends(get_db)):
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(100).all()

@router.get("/{log_id}", response_model=AuditLogResponse)
def get_audit_log(log_id: int, db: Session = Depends(get_db)):
    log = db.query(AuditLog).filter(AuditLog.id == log_id).first()
    if not log:
        raise HTTPException(status_code=404, detail="سجل النشاط غير موجود")
    return log

@router.post("", response_model=AuditLogResponse)
def create_audit_log(log: AuditLogCreate, db: Session = Depends(get_db)):
    db_log = AuditLog(
        **log.dict(),
        created_at=datetime.now()
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log
