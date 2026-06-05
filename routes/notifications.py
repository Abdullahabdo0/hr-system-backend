from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import Notification
from schemas import NotificationCreate, NotificationResponse
from datetime import datetime
from typing import Optional

router = APIRouter()


@router.get("", response_model=list[NotificationResponse])
def get_notifications(
    target_user_id: Optional[int] = Query(default=None),
    unread_only: bool = Query(default=False),
    db: Session = Depends(get_db),
):
    query = db.query(Notification)
    if target_user_id is not None:
        # Return global notifications (no target) OR targeted to this user
        from sqlalchemy import or_
        query = query.filter(
            or_(
                Notification.target_user_id == target_user_id,
                Notification.target_user_id == None,
            )
        )
    if unread_only:
        query = query.filter(Notification.is_read == False)
    return query.order_by(Notification.created_at.desc()).limit(50).all()


@router.get("/{notif_id}", response_model=NotificationResponse)
def get_notification(notif_id: int, db: Session = Depends(get_db)):
    notif = db.query(Notification).filter(Notification.id == notif_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="الإشعار غير موجود")
    return notif


@router.post("", response_model=NotificationResponse)
def create_notification(notif: NotificationCreate, db: Session = Depends(get_db)):
    db_notif = Notification(
        **notif.model_dump(),
        created_at=datetime.now(),
    )
    db.add(db_notif)
    db.commit()
    db.refresh(db_notif)
    return db_notif


@router.patch("/{notif_id}/read")
def mark_as_read(notif_id: int, db: Session = Depends(get_db)):
    notif = db.query(Notification).filter(Notification.id == notif_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="الإشعار غير موجود")

    notif.is_read = True
    db.commit()
    return {"message": "تم تعليم الإشعار كمقروء"}


@router.patch("/mark-all-read")
def mark_all_read(
    target_user_id: Optional[int] = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(Notification).filter(Notification.is_read == False)
    if target_user_id is not None:
        from sqlalchemy import or_
        query = query.filter(
            or_(
                Notification.target_user_id == target_user_id,
                Notification.target_user_id == None,
            )
        )
    updated = query.update({"is_read": True}, synchronize_session=False)
    db.commit()
    return {"message": f"تم تعليم {updated} إشعار كمقروء"}


@router.delete("/{notif_id}")
def delete_notification(notif_id: int, db: Session = Depends(get_db)):
    notif = db.query(Notification).filter(Notification.id == notif_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="الإشعار غير موجود")

    db.delete(notif)
    db.commit()
    return {"message": "تم حذف الإشعار بنجاح"}
