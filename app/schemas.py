from pydantic import BaseModel, EmailStr
from typing import Optional

# الـ Schema الخاص بالماتريال
class EquipmentBase(BaseModel):
    nom_materiel: str
    quantite_totale: int

class EquipmentCreate(EquipmentBase):
    pass

class EquipmentResponse(EquipmentBase):
    id: int

    class Config:
        from_attributes = True

# الـ Schema الخاص بالخدامة
class UserBase(BaseModel):
    nom_prenom: str
    email: EmailStr
    role: str # Admin, Technicien, Aideur

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    photo_url: Optional[str] = None

    class Config:
        from_attributes = True

# الـ Schema الخاص بتسجيل الدخول
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# الـ Schema الخاص بوسائل النقل
class TransportBase(BaseModel):
    matricule: str
    modele: str

class TransportCreate(TransportBase):
    pass

class TransportResponse(TransportBase):
    id: int

    class Config:
        from_attributes = True
from datetime import datetime
from typing import List, Optional

class EventEquipmentCreate(BaseModel):
    equipment_id: int
    quantite_demandee: int

class EventCreate(BaseModel):
    nom_evenement: str
    date_debut: datetime
    date_fin: datetime
    localisation: Optional[str] = None
    type_show: str # Solo, Duo, Trio, One Man Show, Troupe
    transport_id: Optional[int] = None
    staff_ids: List[int] = [] # أرقام الخدامة الماشيين
    equipments: List[EventEquipmentCreate] # الماتريال المطلوبة والكمية

class EventResponse(BaseModel):
    id: int
    nom_evenement: str
    date_debut: datetime
    date_fin: datetime
    localisation: Optional[str] = None
    type_show: str
    
    class Config:
        from_attributes = True


class AppEventBase(BaseModel):
    troupe: str
    type: str
    description: str
    lieu: str
    date: datetime
    staffNames: List[str] = []
    vehicle: str
    numChateau: int = 0
    numBase: int = 0
    numRetour: int = 0
    numChanteur: int = 0
    numPercussion: int = 0
    batterie: bool = False


class AppEventCreate(AppEventBase):
    pass


class AppEventUpdate(AppEventBase):
    pass


class AppEventResponse(AppEventBase):
    id: int

    class Config:
        from_attributes = True
