from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    role = Column(String, default='employee')
    employee_id = Column(Integer, ForeignKey('employees.id'), nullable=True)


class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone = Column(String)
    position = Column(String)
    department = Column(String)
    location = Column(String)
    national_id = Column(String)
    qualification = Column(String)
    address = Column(Text)
    hire_date = Column(DateTime)
    salary = Column(Float)
    status = Column(String, default='active')
    profile_picture_url = Column(Text, nullable=True)


class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey('employees.id'), nullable=False)
    date = Column(DateTime, nullable=False)
    check_in_time = Column(DateTime)
    check_out_time = Column(DateTime)
    total_hours = Column(Float)
    status = Column(String, default='present')
    notes = Column(Text)


class Leave(Base):
    __tablename__ = "leaves"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey('employees.id'), nullable=False)
    leave_type = Column(String, nullable=False)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    reason = Column(Text)
    status = Column(String, default='pending')
    created_at = Column(DateTime)
    approved_at = Column(DateTime)
    approved_by = Column(Integer, ForeignKey('users.id'))


class SalaryPayment(Base):
    __tablename__ = "salary_payments"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey('employees.id'), nullable=False)
    amount = Column(Float, nullable=False)
    payment_date = Column(DateTime, nullable=False)
    payment_type = Column(String, default='salary')
    notes = Column(Text)
    created_at = Column(DateTime)


class PerformanceReview(Base):
    __tablename__ = "performance_reviews"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey('employees.id'), nullable=False)
    reviewer_id = Column(Integer, ForeignKey('users.id'))
    review_date = Column(DateTime, nullable=False)
    rating = Column(Integer)
    comments = Column(Text)
    created_at = Column(DateTime)


class AuditLog(Base):
    __tablename__ = "audit_log"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    action = Column(String, nullable=False)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer)
    old_values = Column(Text)
    new_values = Column(Text)
    created_at = Column(DateTime)


class JobApplicant(Base):
    __tablename__ = "job_applicants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    position = Column(String, nullable=False)
    email = Column(String)
    phone = Column(String)
    status = Column(String, default='new')   # new | reviewing | interviewed | accepted | rejected
    notes = Column(Text)
    applied_at = Column(DateTime)
    created_at = Column(DateTime)


class Communication(Base):
    __tablename__ = "communications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    sender = Column(String)
    receiver = Column(String)
    content = Column(Text)
    type = Column(String, default='message')   # message | purchase_request | transfer
    status = Column(String, default='pending') # pending | replied | closed
    created_at = Column(DateTime)


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text)
    type = Column(String, default='system')   # system | event | alert
    is_read = Column(Boolean, default=False)
    target_user_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    created_at = Column(DateTime)
