from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

# User Schemas
class UserBase(BaseModel):
    username: str
    role: str = 'employee'

class UserCreate(UserBase):
    password: str
    employee_id: Optional[int] = None

class UserResponse(UserBase):
    id: int
    employee_id: Optional[int] = None

    class Config:
        from_attributes = True

# Employee Schemas
class EmployeeBase(BaseModel):
    name: str
    email: EmailStr
    phone: Optional[str] = None
    position: Optional[str] = None
    department: Optional[str] = None
    hire_date: Optional[datetime] = None
    salary: Optional[float] = None
    status: str = 'active'

class EmployeeCreate(EmployeeBase):
    pass

class EmployeeUpdate(EmployeeBase):
    pass

class EmployeeResponse(EmployeeBase):
    id: int

    class Config:
        from_attributes = True

# Attendance Schemas
class AttendanceBase(BaseModel):
    employee_id: int
    date: datetime
    status: str = 'present'

class AttendanceCreate(AttendanceBase):
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    total_hours: Optional[float] = None

class AttendanceResponse(AttendanceBase):
    id: int
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    total_hours: Optional[float] = None

    class Config:
        from_attributes = True

# Leave Schemas
class LeaveBase(BaseModel):
    employee_id: int
    leave_type: str
    start_date: datetime
    end_date: datetime
    reason: Optional[str] = None
    status: str = 'pending'

class LeaveCreate(LeaveBase):
    pass

class LeaveResponse(LeaveBase):
    id: int
    created_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by: Optional[int] = None

    class Config:
        from_attributes = True

# Salary Payment Schemas
class SalaryPaymentBase(BaseModel):
    employee_id: int
    amount: float
    payment_date: datetime
    payment_type: str = 'salary'
    notes: Optional[str] = None

class SalaryPaymentCreate(SalaryPaymentBase):
    pass

class SalaryPaymentResponse(SalaryPaymentBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Performance Review Schemas
class PerformanceReviewBase(BaseModel):
    employee_id: int
    review_date: datetime
    rating: int
    comments: Optional[str] = None

class PerformanceReviewCreate(PerformanceReviewBase):
    reviewer_id: Optional[int] = None

class PerformanceReviewResponse(PerformanceReviewBase):
    id: int
    reviewer_id: Optional[int] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Audit Log Schemas
class AuditLogBase(BaseModel):
    user_id: Optional[int] = None
    action: str
    entity_type: str
    entity_id: Optional[int] = None
    old_values: Optional[str] = None
    new_values: Optional[str] = None

class AuditLogCreate(AuditLogBase):
    pass

class AuditLogResponse(AuditLogBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
