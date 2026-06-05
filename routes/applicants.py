from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import JobApplicant
from schemas import JobApplicantCreate, JobApplicantUpdate, JobApplicantResponse
from datetime import datetime
from typing import Optional

router = APIRouter()

VALID_STATUSES = {"new", "reviewing", "interviewed", "accepted", "rejected"}


@router.get("", response_model=list[JobApplicantResponse])
def get_applicants(
    status: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(JobApplicant)
    if status:
        query = query.filter(JobApplicant.status == status)
    return query.order_by(JobApplicant.created_at.desc()).all()


@router.get("/{applicant_id}", response_model=JobApplicantResponse)
def get_applicant(applicant_id: int, db: Session = Depends(get_db)):
    applicant = db.query(JobApplicant).filter(JobApplicant.id == applicant_id).first()
    if not applicant:
        raise HTTPException(status_code=404, detail="المتقدم غير موجود")
    return applicant


@router.post("", response_model=JobApplicantResponse)
def create_applicant(applicant: JobApplicantCreate, db: Session = Depends(get_db)):
    db_applicant = JobApplicant(
        **applicant.model_dump(),
        created_at=datetime.now(),
        applied_at=applicant.applied_at or datetime.now(),
    )
    db.add(db_applicant)
    db.commit()
    db.refresh(db_applicant)
    return db_applicant


@router.patch("/{applicant_id}", response_model=JobApplicantResponse)
def update_applicant(
    applicant_id: int,
    update: JobApplicantUpdate,
    db: Session = Depends(get_db),
):
    applicant = db.query(JobApplicant).filter(JobApplicant.id == applicant_id).first()
    if not applicant:
        raise HTTPException(status_code=404, detail="المتقدم غير موجود")

    if update.status and update.status not in VALID_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"الحالة غير صالحة. الحالات المسموح بها: {', '.join(VALID_STATUSES)}",
        )

    update_data = update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(applicant, key, value)

    db.commit()
    db.refresh(applicant)
    return applicant


@router.delete("/{applicant_id}")
def delete_applicant(applicant_id: int, db: Session = Depends(get_db)):
    applicant = db.query(JobApplicant).filter(JobApplicant.id == applicant_id).first()
    if not applicant:
        raise HTTPException(status_code=404, detail="المتقدم غير موجود")

    db.delete(applicant)
    db.commit()
    return {"message": "تم حذف طلب التوظيف بنجاح"}
