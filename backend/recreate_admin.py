from database import SessionLocal
from models import User
import bcrypt

db = SessionLocal()

# Delete existing admin
admin = db.query(User).filter(User.username == 'admin').first()
if admin:
    db.delete(admin)
    db.commit()
    print('Admin user deleted')

# Create new admin with bcrypt
password_bytes = 'admin'.encode('utf-8')
salt = bcrypt.gensalt()
hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
admin_user = User(
    username='admin',
    password=hashed_password,
    role='admin'
)
db.add(admin_user)
db.commit()
print('Admin user created with password: admin')

db.close()
