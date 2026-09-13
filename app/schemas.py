from pydantic import BaseModel, EmailStr, Field
from typing import Literal, Optional

RoleType = Literal["Admin", "Technicien", "Aideur"]

# الـ Schema الخاص بالماتريال
class EquipmentBase(BaseModel):
    nom_materiel: str = Field(min_length=1, max_length=100)
    quantite_totale: int = Field(ge=0, le=100000)

class EquipmentCreate(EquipmentBase):
    pass

class EquipmentResponse(EquipmentBase):
    id: int

    class Config:
        from_attributes = True

# الـ Schema الخاص بالخدامة
class UserBase(BaseModel):
    nom_prenom: str = Field(min_length=2, max_length=100)
    email: EmailStr
    role: RoleType = "Aideur"

class UserCreate(UserBase):
    password: str = Field(min_length=4, max_length=72)

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
    matricule: str = Field(min_length=1, max_length=50)
    modele: str = Field(min_length=1, max_length=100)

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
    quantite_demandee: int = Field(ge=1, le=100000)

class EventCreate(BaseModel):
    nom_evenement: str = Field(min_length=1, max_length=200)
    date_debut: datetime
    date_fin: datetime
    localisation: Optional[str] = Field(default=None, max_length=500)
    type_show: str = Field(min_length=1, max_length=50)
    transport_id: Optional[int] = None
    staff_ids: List[int] = Field(default_factory=list) # أرقام الخدامة الماشيين
    equipments: List[EventEquipmentCreate] = Field(default_factory=list)

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
    troupe: str = Field(min_length=1, max_length=100)
    type: str = Field(min_length=1, max_length=50)
    description: str = Field(min_length=1, max_length=2000)
    lieu: str = Field(min_length=1, max_length=500)
    date: datetime
    staffNames: List[str] = Field(default_factory=list, max_length=50)
    vehicle: str = Field(min_length=1, max_length=100)
    numChateau: int = Field(default=0, ge=0, le=1000)
    numBase: int = Field(default=0, ge=0, le=1000)
    numRetour: int = Field(default=0, ge=0, le=1000)
    numChanteur: int = Field(default=0, ge=0, le=1000)
    numPercussion: int = Field(default=0, ge=0, le=1000)
    batterie: bool = False


class AppEventCreate(AppEventBase):
    pass


class AppEventUpdate(AppEventBase):
    pass


class AppEventResponse(AppEventBase):
    id: int

    class Config:
        from_attributes = True
