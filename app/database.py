import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

# لو متغير DATABASE_URL موجود (استضافة Render + Postgres) نستعملو،
# وإلا نستعمل SQLite محلية بجانب المشروع.
_DATABASE_URL = os.environ.get("DATABASE_URL", "").strip()
if _DATABASE_URL:
    if _DATABASE_URL.startswith("postgres://"):
        _DATABASE_URL = _DATABASE_URL.replace(
            "postgres://", "postgresql+psycopg2://", 1
        )
    elif _DATABASE_URL.startswith("postgresql://"):
        _DATABASE_URL = _DATABASE_URL.replace(
            "postgresql://", "postgresql+psycopg2://", 1
        )
    SQLALCHEMY_DATABASE_URL = _DATABASE_URL
    # NullPool: ضروري مع السيرفرات serverless (Vercel) باش ما تتعباش القاعدة
    engine = create_engine(SQLALCHEMY_DATABASE_URL, poolclass=NullPool)
else:
    _DB_PATH = Path(__file__).resolve().parent.parent / "sono_db.db"
    SQLALCHEMY_DATABASE_URL = f"sqlite:///{_DB_PATH}"
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# فانكشن باش نعيطوا لقاعدة البيانات وقت الحاجة
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()