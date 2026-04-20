from database import SessionLocal
from models import User, Employee

db = SessionLocal()

print('Users:')
users = db.query(User).all()
for u in users:
    print(f'  {u.username} - {u.role} - emp_id: {u.employee_id}')

print('\nEmployees:')
employees = db.query(Employee).all()
for e in employees:
    print(f'  {e.name} - {e.id} - email: {e.email}')

db.close()
