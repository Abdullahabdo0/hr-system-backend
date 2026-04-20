from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import SalaryPayment
from schemas import SalaryPaymentCreate, SalaryPaymentResponse
from datetime import datetime

router = APIRouter()

@router.get("", response_model=list[SalaryPaymentResponse])
def get_salary_payments(employee_id: int = None, db: Session = Depends(get_db)):
    query = db.query(SalaryPayment)
    if employee_id:
        query = query.filter(SalaryPayment.employee_id == employee_id)
    return query.all()

@router.get("/{payment_id}", response_model=SalaryPaymentResponse)
def get_salary_payment(payment_id: int, db: Session = Depends(get_db)):
    payment = db.query(SalaryPayment).filter(SalaryPayment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="دفعة الراتب غير موجودة")
    return payment

@router.post("", response_model=SalaryPaymentResponse)
def create_salary_payment(payment: SalaryPaymentCreate, db: Session = Depends(get_db)):
    db_payment = SalaryPayment(
        **payment.dict(),
        created_at=datetime.now()
    )
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    return db_payment

@router.delete("/{payment_id}")
def delete_salary_payment(payment_id: int, db: Session = Depends(get_db)):
    payment = db.query(SalaryPayment).filter(SalaryPayment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="دفعة الراتب غير موجودة")
    
    db.delete(payment)
    db.commit()
    return {"message": "تم حذف دفعة الراتب بنجاح"}
