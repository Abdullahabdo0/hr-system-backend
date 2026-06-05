from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import Communication
from schemas import CommunicationCreate, CommunicationResponse
from datetime import datetime
from typing import Optional

router = APIRouter()


@router.get("", response_model=list[CommunicationResponse])
def get_communications(
    type: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(Communication)
    if type:
        query = query.filter(Communication.type == type)
    if status:
        query = query.filter(Communication.status == status)
    return query.order_by(Communication.created_at.desc()).all()


@router.get("/{comm_id}", response_model=CommunicationResponse)
def get_communication(comm_id: int, db: Session = Depends(get_db)):
    comm = db.query(Communication).filter(Communication.id == comm_id).first()
    if not comm:
        raise HTTPException(status_code=404, detail="الاتصال غير موجود")
    return comm


@router.post("", response_model=CommunicationResponse)
def create_communication(comm: CommunicationCreate, db: Session = Depends(get_db)):
    db_comm = Communication(
        **comm.model_dump(),
        created_at=datetime.now(),
    )
    db.add(db_comm)
    db.commit()
    db.refresh(db_comm)
    return db_comm


@router.patch("/{comm_id}/status")
def update_communication_status(
    comm_id: int,
    status: str = Query(...),
    db: Session = Depends(get_db),
):
    valid_statuses = {"pending", "replied", "closed"}
    if status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"الحالة غير صالحة: {status}")

    comm = db.query(Communication).filter(Communication.id == comm_id).first()
    if not comm:
        raise HTTPException(status_code=404, detail="الاتصال غير موجود")

    comm.status = status
    db.commit()
    db.refresh(comm)
    return comm


@router.delete("/{comm_id}")
def delete_communication(comm_id: int, db: Session = Depends(get_db)):
    comm = db.query(Communication).filter(Communication.id == comm_id).first()
    if not comm:
        raise HTTPException(status_code=404, detail="الاتصال غير موجود")

    db.delete(comm)
    db.commit()
    return {"message": "تم حذف الاتصال بنجاح"}
