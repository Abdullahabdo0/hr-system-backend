from sqlalchemy import create_engine
from models import Base
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:20101964@localhost/hr_system")

engine = create_engine(DATABASE_URL)

# إنشاء جميع الجداول
Base.metadata.create_all(bind=engine)

print("تم إنشاء جميع الجداول بنجاح!")
