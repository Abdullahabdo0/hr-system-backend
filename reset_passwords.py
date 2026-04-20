from database import SessionLocal
from models import User
import bcrypt

db = SessionLocal()

# Reset admin password
admin = db.query(User).filter(User.username == 'admin').first()
if admin:
    password_bytes = 'admin'.encode('utf-8')
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
    admin.password = hashed_password
    db.commit()
    print('Admin password reset to: admin')
else:
    print('Admin user not found')

# Reset omar password
omar = db.query(User).filter(User.username == 'omar').first()
if omar:
    password_bytes = 'omar'.encode('utf-8')
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
    omar.password = hashed_password
    db.commit()
    print('Omar password reset to: omar')
else:
    print('Omar user not found')

db.close()
