# تجهيزات / مستخدمون - دوال أساسية ناقصة كانت تمنع فتح التطبيق
from sqlalchemy.orm import Session
from . import models, schemas
import bcrypt


def _hash_password(password: str) -> str:
    pw_bytes = password.encode("utf-8")[:72]
    return bcrypt.hashpw(pw_bytes, bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(
            password.encode("utf-8")[:72], password_hash.encode("utf-8")
        )
    except Exception:
        return False


def authenticate_user(db: Session, email: str, password: str):
    db_user = db.query(models.User).filter(models.User.email == email).first()
    if db_user is None:
        return None
    if not verify_password(password, db_user.password_hash):
        return None
    return db_user


def get_equipments(db: Session):
    return db.query(models.Equipment).all()


def create_equipment(db: Session, equipment: schemas.EquipmentCreate):
    from fastapi import HTTPException

    existing = db.query(models.Equipment).filter(
        models.Equipment.nom_materiel == equipment.nom_materiel
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="الماتريال هذا موجود already!")
    db_equipment = models.Equipment(
        nom_materiel=equipment.nom_materiel,
        quantite_totale=equipment.quantite_totale,
    )
    db.add(db_equipment)
    db.commit()
    db.refresh(db_equipment)
    return db_equipment


def get_users(db: Session):
    return db.query(models.User).all()


def create_user(db: Session, user: schemas.UserCreate):
    from fastapi import HTTPException

    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="الايميل هذا مستعمل already!")
    db_user = models.User(
        nom_prenom=user.nom_prenom,
        email=user.email,
        password_hash=_hash_password(user.password),
        role=user.role,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def delete_user(db: Session, user_id: int):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if db_user is None:
        return False
    db.delete(db_user)
    db.commit()
    return True


def get_transports(db: Session):
    return db.query(models.Transport).all()


def create_transport(db: Session, transport: schemas.TransportCreate):
    from fastapi import HTTPException

    existing = db.query(models.Transport).filter(
        models.Transport.matricule == transport.matricule
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="الـ matricule هذا مستعمل already!")
    db_transport = models.Transport(
        matricule=transport.matricule,
        modele=transport.modele,
    )
    db.add(db_transport)
    db.commit()
    db.refresh(db_transport)
    return db_transport


def update_transport(db: Session, transport_id: int, transport_update: schemas.TransportCreate):
    db_transport = db.query(models.Transport).filter(
        models.Transport.id == transport_id
    ).first()
    if db_transport:
        db_transport.matricule = transport_update.matricule
        db_transport.modele = transport_update.modele
        db.commit()
        db.refresh(db_transport)
    return db_transport


def delete_transport(db: Session, transport_id: int):
    db_transport = db.query(models.Transport).filter(
        models.Transport.id == transport_id
    ).first()
    if db_transport is None:
        return False
    db.delete(db_transport)
    db.commit()
    return True

def update_equipment(db: Session, equipment_id: int, equipment_update: schemas.EquipmentCreate):
    db_equipment = db.query(models.Equipment).filter(models.Equipment.id == equipment_id).first()
    if db_equipment:
        db_equipment.nom_materiel = equipment_update.nom_materiel
        db_equipment.quantite_totale = equipment_update.quantite_totale
        db.commit()
        db.refresh(db_equipment)
    return db_equipment

# فسخ ماتريال جملة من الستوك
def delete_equipment(db: Session, equipment_id: int):
    db_equipment = db.query(models.Equipment).filter(models.Equipment.id == equipment_id).first()
    if db_equipment:
        db.delete(db_equipment)
        db.commit()
        return True
    return False
from datetime import datetime
from fastapi import HTTPException
from . import models, schemas
import json

# الفانكشن الذكية اللّي تبرمج الحفلة وتثبت في الماتريال والخدامة
def create_event(db: Session, event_data: schemas.EventCreate):
    # 1. التثبت من الماتريال المتوفر في التاريخ هذاكا
    for eq_req in event_data.equipments:
        # نجيبوا الكمية الجملية اللّي تملكها الشركة
        equipment = db.query(models.Equipment).filter(models.Equipment.id == eq_req.equipment_id).first()
        if not equipment:
            raise HTTPException(status_code=400, detail=f"الماتريال رقم {eq_req.equipment_id} مش موجود في الشركة!")
        
        # نحسبوا قداش من قطعة من الماتريال هذا محجوزة في حفلات أخرى في نفس التاريخ
        overlapping_events = db.query(models.Event).filter(
            models.Event.date_debut < event_data.date_fin,
            models.Event.date_fin > event_data.date_debut
        ).all()
        
        assigned_qty = 0
        for ev in overlapping_events:
            for ev_eq in ev.equipments:
                if ev_eq.equipment_id == eq_req.equipment_id:
                    assigned_qty += ev_eq.quantite_demandee
        
        # إذا الحجوزات القديمة + الطلب الجديد يفوتوا الستوك متع الشركة -> نرفضوا الحفلة أوتوماتيكياً!
        if (assigned_qty + eq_req.quantite_demandee) > equipment.quantite_totale:
            dispo = equipment.quantite_totale - assigned_qty
            raise HTTPException(
                status_code=400, 
                detail=f"غلطة! الماتريال [{equipment.nom_materiel}] ما يكفيش. المتوفر في التاريخ هذا هو {dispo} فقط!"
            )

    # 2. إذا كل شيء مريقل، نصنعوا الحفلة
    db_event = models.Event(
        nom_evenement=event_data.nom_evenement,
        date_debut=event_data.date_debut,
        date_fin=event_data.date_fin,
        localisation=event_data.localisation,
        type_show=event_data.type_show,
        transport_id=event_data.transport_id
    )
    
    # نربطوا الخدامة
    if event_data.staff_ids:
        users = db.query(models.User).filter(models.User.id.in_(event_data.staff_ids)).all()
        db_event.staff = users
        
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    
    # نسجلوا الماتريال اللّي تخاذ في جدول الربط
    for eq_req in event_data.equipments:
        ev_eq = models.EventEquipment(
            event_id=db_event.id,
            equipment_id=eq_req.equipment_id,
            quantite_demandee=eq_req.quantite_demandee
        )
        db.add(ev_eq)
    
    db.commit()
    db.refresh(db_event)
    return db_event

# فانكشن باش نخرجوا الحفلات الكل
def get_events(db: Session):
    return db.query(models.Event).all()


def _app_event_to_response(event: models.AppEvent):
    return schemas.AppEventResponse(
        id=event.id,
        troupe=event.troupe,
        type=event.type,
        description=event.description,
        lieu=event.lieu,
        date=event.date,
        staffNames=json.loads(event.staff_names or "[]"),
        vehicle=event.vehicle,
        numChateau=event.num_chateau,
        numBase=event.num_base,
        numRetour=event.num_retour,
        numChanteur=event.num_chanteur,
        numPercussion=event.num_percussion,
        batterie=event.batterie,
    )


def _apply_app_event_data(db_event: models.AppEvent, event_data: schemas.AppEventBase):
    db_event.troupe = event_data.troupe
    db_event.type = event_data.type
    db_event.description = event_data.description
    db_event.lieu = event_data.lieu
    db_event.date = event_data.date
    db_event.staff_names = json.dumps(event_data.staffNames, ensure_ascii=False)
    db_event.vehicle = event_data.vehicle
    db_event.num_chateau = event_data.numChateau
    db_event.num_base = event_data.numBase
    db_event.num_retour = event_data.numRetour
    db_event.num_chanteur = event_data.numChanteur
    db_event.num_percussion = event_data.numPercussion
    db_event.batterie = event_data.batterie


def create_app_event(db: Session, event_data: schemas.AppEventCreate):
    db_event = models.AppEvent()
    _apply_app_event_data(db_event, event_data)
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return _app_event_to_response(db_event)


def get_app_events(db: Session):
    events = db.query(models.AppEvent).order_by(models.AppEvent.date.asc()).all()
    return [_app_event_to_response(event) for event in events]


def update_app_event(db: Session, event_id: int, event_data: schemas.AppEventUpdate):
    db_event = db.query(models.AppEvent).filter(models.AppEvent.id == event_id).first()
    if db_event is None:
        return None
    _apply_app_event_data(db_event, event_data)
    db.commit()
    db.refresh(db_event)
    return _app_event_to_response(db_event)


def delete_app_event(db: Session, event_id: int):
    db_event = db.query(models.AppEvent).filter(models.AppEvent.id == event_id).first()
    if db_event is None:
        return False
    db.delete(db_event)
    db.commit()
    return True
