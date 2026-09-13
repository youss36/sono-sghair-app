from sqlalchemy import Boolean, Column, Integer, String, ForeignKey, DateTime, Table
from sqlalchemy.orm import relationship
from .database import Base

# جدول وسيط: يربط الخدامة بالحفلات (Many-to-Many)
event_staff = Table(
    "event_staff",
    Base.metadata,
    Column("event_id", Integer, ForeignKey("events.id", ondelete="CASCADE")),
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"))
)

# جدول وسيط: يربط الماتريال بالحفلات مع تسجيل الكمية اللّي مشات (Association Object)
class EventEquipment(Base):
    __tablename__ = "event_equipment"
    event_id = Column(Integer, ForeignKey("events.id", ondelete="CASCADE"), primary_key=True)
    equipment_id = Column(Integer, ForeignKey("equipments.id", ondelete="CASCADE"), primary_key=True)
    quantite_demandee = Column(Integer, nullable=False) # قداش هزينا من قطعة للحفلة هذي

    equipment = relationship("Equipment")

# جدول وسائل النقل
class Transport(Base):
    __tablename__ = "transports"
    id = Column(Integer, primary_key=True, index=True)
    matricule = Column(String, unique=True, nullable=False)
    modele = Column(String, nullable=False) # Camion, Partner...

# جدول المستخدمين (الخدامة والآدمن)
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    nom_prenom = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="Aideur") # Admin, Technicien, Aideur
    photo_url = Column(String, nullable=True)

# جدول الماتريال (الستوك الأساسي)
class Equipment(Base):
    __tablename__ = "equipments"
    id = Column(Integer, primary_key=True, index=True)
    nom_materiel = Column(String, unique=True, nullable=False)
    quantite_totale = Column(Integer, nullable=False)

# جدول الحفلات الكبير
class Event(Base):
    __tablename__ = "events"
    id = Column(Integer, primary_key=True, index=True)
    nom_evenement = Column(String, nullable=False)
    date_debut = Column(DateTime, nullable=False)
    date_fin = Column(DateTime, nullable=False)
    localisation = Column(String, nullable=True) # Lien Google Maps أو عنوان
    type_show = Column(String, nullable=False) # Solo, Duo, Trio, One Man Show, Troupe
    
    transport_id = Column(Integer, ForeignKey("transports.id", ondelete="SET NULL"), nullable=True)
    
    # العلاقات (Relationships)
    transport = relationship("Transport")
    staff = relationship("User", secondary=event_staff)
    equipments = relationship("EventEquipment")


class AppEvent(Base):
    __tablename__ = "app_events"

    id = Column(Integer, primary_key=True, index=True)
    troupe = Column(String, nullable=False)
    type = Column(String, nullable=False)
    description = Column(String, nullable=False)
    lieu = Column(String, nullable=False)
    date = Column(DateTime, nullable=False)
    staff_names = Column(String, nullable=False, default="")
    vehicle = Column(String, nullable=False)
    num_chateau = Column(Integer, nullable=False, default=0)
    num_base = Column(Integer, nullable=False, default=0)
    num_retour = Column(Integer, nullable=False, default=0)
    num_chanteur = Column(Integer, nullable=False, default=0)
    num_percussion = Column(Integer, nullable=False, default=0)
    batterie = Column(Boolean, nullable=False, default=False)
