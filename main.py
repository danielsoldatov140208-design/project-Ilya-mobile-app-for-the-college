import os
import shutil
import secrets
from pathlib import Path
from datetime import datetime, timedelta, timezone

import jwt
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from pydantic import BaseModel, Field
from fastapi import FastAPI, Depends, HTTPException, File, UploadFile
from fastapi.staticfiles import StaticFiles
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from passlib.context import CryptContext


SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError(
        "Не задан SECRET_KEY. Создай переменную окружения SECRET_KEY "
        "со случайным секретным ключом."
    )

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

TECHNICIAN_SECRET_CODE = os.getenv("TECHNICIAN_SECRET_CODE")

DATABASE_URL = "sqlite:///./servicedesk.db"
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

ALLOWED_STATUSES = {"Новая", "В работе", "Выполнена", "Отклонена"}
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_UPLOAD_SIZE = 5 * 1024 * 1024  # 5 MB

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")



class TicketModel(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    teacher = Column(String, nullable=False)
    room = Column(String, nullable=False)
    description = Column(String, nullable=False)
    status = Column(String, default="Новая", nullable=False)
    photo_url = Column(String, nullable=True)


class UserModel(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="teacher", nullable=False)


Base.metadata.create_all(bind=engine)


class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=8, max_length=72)
    secret_code: str | None = None


class UserLogin(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    id: int
    username: str
    role: str

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TicketCreate(BaseModel):
    teacher: str = Field(min_length=1, max_length=100)
    room: str = Field(min_length=1, max_length=50)
    description: str = Field(min_length=1, max_length=2000)


class TicketUpdateStatus(BaseModel):
    status: str


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_access_token(data: dict) -> str:
    payload = data.copy()
    payload["exp"] = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


security = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db)
) -> UserModel:
    if credentials is None:
        raise HTTPException(
            status_code=401,
            detail="Необходим токен авторизации",
            headers={"WWW-Authenticate": "Bearer"}
        )

    try:
        payload = jwt.decode(
            credentials.credentials,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        user_id = int(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, TypeError, ValueError):
        raise HTTPException(
            status_code=401,
            detail="Недействительный или просроченный токен",
            headers={"WWW-Authenticate": "Bearer"}
        )

    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Пользователь не найден",
            headers={"WWW-Authenticate": "Bearer"}
        )
    return user


def require_technician(
    user: UserModel = Depends(get_current_user)
) -> UserModel:
    if user.role != "technician":
        raise HTTPException(
            status_code=403,
            detail="Это действие доступно только техникам"
        )
    return user


app = FastAPI(title="Service Desk API")
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")


@app.get("/")
def root():
    return {"message": "Service Desk API работает"}


@app.post("/register", response_model=UserResponse, status_code=201)
def register_user(user_data: UserCreate, db: Session = Depends(get_db)):
    username = user_data.username.strip()
    if not username:
        raise HTTPException(status_code=400, detail="Имя пользователя не может быть пустым")

    existing_user = db.query(UserModel).filter(
        UserModel.username == username
    ).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Такое имя уже существует!")

    role = (
        "technician"
        if TECHNICIAN_SECRET_CODE is not None
        and user_data.secret_code is not None
        and secrets.compare_digest(user_data.secret_code, TECHNICIAN_SECRET_CODE)
        else "teacher"
    )

    new_user = UserModel(
        username=username,
        role=role,
        hashed_password=pwd_context.hash(user_data.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.post("/login", response_model=TokenResponse)
def login_user(user_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(
        UserModel.username == user_data.username
    ).first()

    if not user or not pwd_context.verify(
        user_data.password, user.hashed_password
    ):
        raise HTTPException(status_code=401, detail="Неверный логин или пароль")

    token = create_access_token({"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer"}


@app.get("/users/me", response_model=UserResponse)
def read_current_user(user: UserModel = Depends(get_current_user)):
    return user


@app.post("/tickets", status_code=201)
def create_ticket(
    ticket_data: TicketCreate,
    db: Session = Depends(get_db),
    user: UserModel = Depends(get_current_user)
):
    new_ticket = TicketModel(
        teacher=ticket_data.teacher,
        room=ticket_data.room,
        description=ticket_data.description
    )
    db.add(new_ticket)
    db.commit()
    db.refresh(new_ticket)
    return {"message": "Заявка успешно создана!", "ticket": new_ticket}


@app.get("/tickets")
def get_tickets(
    db: Session = Depends(get_db),
    user: UserModel = Depends(require_technician)
):
    return db.query(TicketModel).order_by(TicketModel.id.desc()).all()


@app.patch("/tickets/{ticket_id}")
def update_ticket_status(
    ticket_id: int,
    status_data: TicketUpdateStatus,
    db: Session = Depends(get_db),
    user: UserModel = Depends(require_technician)
):
    if status_data.status not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"Недопустимый статус. Разрешены: {', '.join(sorted(ALLOWED_STATUSES))}"
        )

    ticket = db.query(TicketModel).filter(
        TicketModel.id == ticket_id
    ).first()
    if ticket is None:
        raise HTTPException(status_code=404, detail="Заявка не найдена")

    ticket.status = status_data.status
    db.commit()
    db.refresh(ticket)
    return {"message": "Статус успешно обновлён!", "ticket": ticket}


@app.delete("/tickets/{ticket_id}")
def delete_ticket(
    ticket_id: int,
    db: Session = Depends(get_db),
    user: UserModel = Depends(require_technician)
):
    ticket = db.query(TicketModel).filter(
        TicketModel.id == ticket_id
    ).first()
    if ticket is None:
        raise HTTPException(status_code=404, detail="Заявка не найдена")

    if ticket.photo_url:
        file_path = Path(ticket.photo_url)
        try:
            file_path.resolve().relative_to(UPLOAD_DIR.resolve())
            if file_path.is_file():
                file_path.unlink()
        except (ValueError, OSError):
            pass

    db.delete(ticket)
    db.commit()
    return {"message": "Заявка успешно удалена"}


@app.post("/tickets/{ticket_id}/upload-photo")
def upload_ticket_photo(
    ticket_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: UserModel = Depends(require_technician)
):
    ticket = db.query(TicketModel).filter(
        TicketModel.id == ticket_id
    ).first()
    if ticket is None:
        raise HTTPException(status_code=404, detail="Заявка не найдена")

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Разрешены только изображения JPEG, PNG и WebP"
        )

    extension_by_type = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp"
    }
    filename = f"ticket_{ticket_id}_{secrets.token_hex(8)}{extension_by_type[file.content_type]}"
    destination = UPLOAD_DIR / filename
    size = 0

    try:
        with destination.open("wb") as buffer:
            while True:
                chunk = file.file.read(1024 * 1024)
                if not chunk:
                    break
                size += len(chunk)
                if size > MAX_UPLOAD_SIZE:
                    raise HTTPException(
                        status_code=413,
                        detail="Размер изображения не должен превышать 5 МБ"
                    )
                buffer.write(chunk)
    except Exception:
        if destination.exists():
            destination.unlink()
        raise
    finally:
        file.file.close()

    old_photo = ticket.photo_url
    if old_photo:
        old_path = Path(old_photo)
        try:
            old_path.resolve().relative_to(UPLOAD_DIR.resolve())
            if old_path.is_file():
                old_path.unlink()
        except (ValueError, OSError):
            pass

    ticket.photo_url = f"uploads/{filename}"
    db.commit()
    db.refresh(ticket)

    return {
        "message": "Фото успешно загружено!",
        "photo_url": f"/uploads/{filename}",
        "ticket": ticket
    }
