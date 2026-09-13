from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
from .database import engine, Base, get_db
from . import models, schemas, crud

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sono Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "success", "message": "مرحباً بيك في سيرفر تطبيق الـ Sono جاهز للخدمة!"}

# Endpoint باش تخرج الماتريال الكل
@app.get("/equipments", response_model=List[schemas.EquipmentResponse])
def read_equipments(db: Session = Depends(get_db)):
    return crud.get_equipments(db)

# Endpoint باش تزيد ماتريال جديد للستوك
@app.post("/equipments", response_model=schemas.EquipmentResponse)
def add_equipment(equipment: schemas.EquipmentCreate, db: Session = Depends(get_db)):
    return crud.create_equipment(equipment=equipment, db=db)

# Endpoint باش تزيد خدام جديد (Technicien / Aideur / Admin)
@app.post("/users", response_model=schemas.UserResponse)
def add_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    return crud.create_user(user=user, db=db)

# Endpoint باش تشوف الخدامة الكل
@app.get("/users", response_model=List[schemas.UserResponse])
def read_users(db: Session = Depends(get_db)):
    return crud.get_users(db)

# Endpoint باش تفسخ خدام
@app.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    success = crud.delete_user(db=db, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="الخدام هذا مش موجود!")
    return {"status": "success", "message": "تم فسخ الخدام بنجاح!"}

# Endpoint تسجيل الدخول: يرجع الخدام بالـ role متاعو
@app.post("/login", response_model=schemas.UserResponse)
def login(credentials: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = crud.authenticate_user(
        db=db, email=credentials.email, password=credentials.password
    )
    if user is None:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect!")
    return user

# Endpoints النقل (Transport)
@app.get("/transports", response_model=List[schemas.TransportResponse])
def read_transports(db: Session = Depends(get_db)):
    return crud.get_transports(db)

@app.post("/transports", response_model=schemas.TransportResponse)
def add_transport(transport: schemas.TransportCreate, db: Session = Depends(get_db)):
    return crud.create_transport(transport=transport, db=db)

@app.put("/transports/{transport_id}", response_model=schemas.TransportResponse)
def update_transport(transport_id: int, transport: schemas.TransportCreate, db: Session = Depends(get_db)):
    db_transport = crud.update_transport(db=db, transport_id=transport_id, transport_update=transport)
    if db_transport is None:
        raise HTTPException(status_code=404, detail="الكراهبة هذي مش موجودة!")
    return db_transport

@app.delete("/transports/{transport_id}")
def delete_transport(transport_id: int, db: Session = Depends(get_db)):
    success = crud.delete_transport(db=db, transport_id=transport_id)
    if not success:
        raise HTTPException(status_code=404, detail="الكراهبة هذي مش موجودة!")
    return {"status": "success", "message": "تم فسخ الكراهبة بنجاح!"}
# Endpoint باش تبدل كمية ماتريال (تستحق الـ id متع القطعة)
@app.put("/equipments/{equipment_id}", response_model=schemas.EquipmentResponse)
def update_equipment(equipment_id: int, equipment: schemas.EquipmentCreate, db: Session = Depends(get_db)):
    db_equipment = crud.update_equipment(db=db, equipment_id=equipment_id, equipment_update=equipment)
    if db_equipment is None:
        raise HTTPException(status_code=404, detail="الماتريال هذا مش موجود!")
    return db_equipment

# Endpoint باش تفسخ قطعة ماتريal
@app.delete("/equipments/{equipment_id}")
def delete_equipment(equipment_id: int, db: Session = Depends(get_db)):
    success = crud.delete_equipment(db=db, equipment_id=equipment_id)
    if not success:
        raise HTTPException(status_code=404, detail="الماتريال هذا مش موجود باش يتفسخ!")
    return {"status": "success", "message": "تم فسخ الماتريال بنجاح!"}
# Endpoint باش تبرمج حفلة جديدة (وتقيد الخدامة والماتريال)
@app.post("/events", response_model=schemas.EventResponse)
def create_event(event: schemas.EventCreate, db: Session = Depends(get_db)):
    return crud.create_event(db=db, event_data=event)

# Endpoint باش تشوف الحفلات الكل اللّي تبرمجت
@app.get("/events", response_model=List[schemas.EventResponse])
def read_events(db: Session = Depends(get_db)):
    return crud.get_events(db)


@app.get("/app-events", response_model=List[schemas.AppEventResponse])
def read_app_events(db: Session = Depends(get_db)):
    return crud.get_app_events(db)


@app.post("/app-events", response_model=schemas.AppEventResponse)
def add_app_event(event: schemas.AppEventCreate, db: Session = Depends(get_db)):
    return crud.create_app_event(db=db, event_data=event)


@app.put("/app-events/{event_id}", response_model=schemas.AppEventResponse)
def edit_app_event(event_id: int, event: schemas.AppEventUpdate, db: Session = Depends(get_db)):
    updated_event = crud.update_app_event(db=db, event_id=event_id, event_data=event)
    if updated_event is None:
        raise HTTPException(status_code=404, detail="Evenement introuvable")
    return updated_event


@app.delete("/app-events/{event_id}")
def remove_app_event(event_id: int, db: Session = Depends(get_db)):
    success = crud.delete_app_event(db=db, event_id=event_id)
    if not success:
        raise HTTPException(status_code=404, detail="Evenement introuvable")
    return {"status": "success", "message": "Evenement supprime"}


# Route diagnostic temporaire (à supprimer après stabilisation)
@app.get("/debug-echo/{full_path:path}", include_in_schema=False)
def debug_echo(full_path: str, request: Request):
    return {
        "scope_path": request.scope.get("path"),
        "original_path": request.scope.get("vercel_original_path"),
        "root_path": request.scope.get("root_path", ""),
        "route_path": full_path,
    }
