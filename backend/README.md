# HR System Backend API

نظام إدارة الموارد البشرية - Backend API باستخدام FastAPI

## التثبيت

1. إنشاء بيئة افتراضية:
```bash
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac
```

2. تثبيت المتطلبات:
```bash
pip install -r requirements.txt
```

3. إنشاء ملف `.env`:
```bash
cp .env.example .env
```

4. تعديل `DATABASE_URL` في ملف `.env` ليتوافق مع إعدادات قاعدة بيانات PostgreSQL الخاصة بك.

## التشغيل

```bash
python main.py
```

أو استخدام uvicorn:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### المصادقة (Authentication)
- `POST /api/auth/login` - تسجيل الدخول
- `POST /api/auth/register` - تسجيل مستخدم جديد

### الموظفين (Employees)
- `GET /api/employees` - الحصول على جميع الموظفين
- `GET /api/employees/{employee_id}` - الحصول على موظف محدد
- `POST /api/employees` - إضافة موظف جديد
- `PUT /api/employees/{employee_id}` - تحديث بيانات موظف
- `DELETE /api/employees/{employee_id}` - حذف موظف

### الحضور (Attendance)
- `GET /api/attendance` - الحصول على جميع سجلات الحضور
- `GET /api/attendance/{attendance_id}` - الحصول على سجل حضور محدد
- `POST /api/attendance/check-in` - تسجيل الدخول
- `POST /api/attendance/check-out` - تسجيل الخروج
- `DELETE /api/attendance/{attendance_id}` - حذف سجل حضور

### الإجازات (Leaves)
- `GET /api/leases` - الحصول على جميع طلبات الإجازة
- `GET /api/leaves/{leave_id}` - الحصول على طلب إجازة محدد
- `POST /api/leaves` - إنشاء طلب إجازة جديد
- `PUT /api/leaves/{leave_id}/approve` - الموافقة على طلب الإجازة
- `PUT /api/leaves/{leave_id}/reject` - رفض طلب الإجازة
- `DELETE /api/leaves/{leave_id}` - حذف طلب إجازة

### الرواتب (Salary)
- `GET /api/salary` - الحصول على جميع دفعات الرواتب
- `GET /api/salary/{payment_id}` - الحصول على دفعة راتب محددة
- `POST /api/salary` - إضافة دفعة راتب جديدة
- `DELETE /api/salary/{payment_id}` - حذف دفعة راتب

### تقييم الأداء (Performance)
- `GET /api/performance` - الحصول على جميع تقييمات الأداء
- `GET /api/performance/{review_id}` - الحصول على تقييم أداء محدد
- `POST /api/performance` - إنشاء تقييم أداء جديد
- `DELETE /api/performance/{review_id}` - حذف تقييم أداء

### سجل الأنشطة (Audit Log)
- `GET /api/audit` - الحصول على جميع سجلات الأنشطة
- `GET /api/audit/{log_id}` - الحصول على سجل نشاط محدد
- `POST /api/audit` - إنشاء سجل نشاط جديد

## التوثيق التفاعلي

بعد تشغيل الخادم، يمكنك الوصول إلى التوثيق التفاعلي على:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
