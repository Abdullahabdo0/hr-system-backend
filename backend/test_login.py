from database import SessionLocal
from models import User
import bcrypt

db = SessionLocal()

# Test admin user
admin = db.query(User).filter(User.username == 'admin').first()
if admin:
    print(f"Admin user found:")
    print(f"  Username: {admin.username}")
    print(f"  Role: {admin.role}")
    print(f"  Password hash: {admin.password[:50]}...")
    
    # Test password verification
    test_password = 'admin'
    plain_password_bytes = test_password.encode('utf-8')
    hashed_password_bytes = admin.password.encode('utf-8')
    
    try:
        is_valid = bcrypt.checkpw(plain_password_bytes, hashed_password_bytes)
        print(f"  Password verification for 'admin': {is_valid}")
    except Exception as e:
        print(f"  Password verification error: {e}")
else:
    print("Admin user not found")

db.close()
