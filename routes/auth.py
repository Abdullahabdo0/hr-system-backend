from fastapi import APIRouter, Depends, HTTPException, status, Form, Query
from sqlalchemy.orm import Session
import bcrypt
from database import get_db
from models import User, Employee
from schemas import UserCreate, UserResponse
from datetime import datetime
from typing import Optional

router = APIRouter()


def get_password_hash(password: str) -> str:
    password_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    plain_password_bytes = plain_password.encode("utf-8")
    hashed_password_bytes = hashed_password.encode("utf-8")
    return bcrypt.checkpw(plain_password_bytes, hashed_password_bytes)


@router.post("/login")
def login(
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.username == username).first()
    if not user or not verify_password(password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة",
        )
    return {
        "id": user.id,
        "username": user.username,
        "role": user.role,
        "employee_id": user.employee_id,
    }


@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="اسم المستخدم موجود بالفعل")

    # Validate employee_id if provided
    if user.employee_id is not None:
        employee = db.query(Employee).filter(Employee.id == user.employee_id).first()
        if not employee:
            raise HTTPException(status_code=404, detail="الموظف المحدد غير موجود")

    hashed_password = get_password_hash(user.password)
    db_user = User(
        username=user.username,
        password=hashed_password,
        role=user.role,
        employee_id=user.employee_id,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@router.get("/users", response_model=list[UserResponse])
def get_users(db: Session = Depends(get_db)):
    return db.query(User).all()


@router.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    if user.username == "admin":
        raise HTTPException(status_code=400, detail="لا يمكن حذف حساب المدير الرئيسي")
    db.delete(user)
    db.commit()
    return {"message": "تم حذف المستخدم بنجاح"}


@router.put("/users/{user_id}/password")
def change_password(
    user_id: int,
    new_password: str = Form(...),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    if len(new_password) < 4:
        raise HTTPException(status_code=400, detail="كلمة المرور يجب أن تكون 4 أحرف على الأقل")
    user.password = get_password_hash(new_password)
    db.commit()
    return {"message": "تم تغيير كلمة المرور بنجاح"}
