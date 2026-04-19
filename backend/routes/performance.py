from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import PerformanceReview
from schemas import PerformanceReviewCreate, PerformanceReviewResponse
from datetime import datetime

router = APIRouter()

@router.get("", response_model=list[PerformanceReviewResponse])
def get_performance_reviews(employee_id: int = None, db: Session = Depends(get_db)):
    query = db.query(PerformanceReview)
    if employee_id:
        query = query.filter(PerformanceReview.employee_id == employee_id)
    return query.all()

@router.get("/{review_id}", response_model=PerformanceReviewResponse)
def get_performance_review(review_id: int, db: Session = Depends(get_db)):
    review = db.query(PerformanceReview).filter(PerformanceReview.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="تقييم الأداء غير موجود")
    return review

@router.post("", response_model=PerformanceReviewResponse)
def create_performance_review(review: PerformanceReviewCreate, db: Session = Depends(get_db)):
    db_review = PerformanceReview(
        **review.dict(),
        created_at=datetime.now()
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

@router.delete("/{review_id}")
def delete_performance_review(review_id: int, db: Session = Depends(get_db)):
    review = db.query(PerformanceReview).filter(PerformanceReview.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="تقييم الأداء غير موجود")
    
    db.delete(review)
    db.commit()
    return {"message": "تم حذف تقييم الأداء بنجاح"}
