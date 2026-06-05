from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import AuditLog
from schemas import AuditLogCreate, AuditLogResponse
from datetime import datetime
from typing import Optional

router = APIRouter()


@router.get("", response_model=list[AuditLogResponse])
def get_audit_logs(
    limit: int = Query(default=100, le=500),
    entity_type: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(AuditLog)
    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)
    return query.order_by(AuditLog.created_at.desc()).limit(limit).all()


@router.get("/{log_id}", response_model=AuditLogResponse)
def get_audit_log(log_id: int, db: Session = Depends(get_db)):
    log = db.query(AuditLog).filter(AuditLog.id == log_id).first()
    if not log:
        raise HTTPException(status_code=404, detail="سجل النشاط غير موجود")
    return log


@router.post("", response_model=AuditLogResponse)
def create_audit_log(log: AuditLogCreate, db: Session = Depends(get_db)):
    db_log = AuditLog(
        **log.model_dump(),
        created_at=datetime.now(),
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log
