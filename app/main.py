import secrets
import string

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

from database import Base, check_database_connection, engine, get_db
from models import ClickEvent, Link
from schemas import LinkCreate, LinkResponse, LinkStatsResponse


app = FastAPI(title="URL Shortener API")


@app.on_event("startup")
def startup() -> None:
    Base.metadata.create_all(bind=engine)


def generate_code(length: int = 6) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict:
    if not check_database_connection():
        raise HTTPException(status_code=503, detail="database unavailable")

    return {
        "status": "ok",
        "db": "reachable",
    }


@app.post("/links", response_model=LinkResponse, status_code=201)
def create_link(payload: LinkCreate, db: Session = Depends(get_db)) -> LinkResponse:
    code = generate_code()

    while db.query(Link).filter(Link.code == code).first() is not None:
        code = generate_code()

    link = Link(
        code=code,
        original_url=str(payload.original_url),
    )

    db.add(link)
    db.commit()
    db.refresh(link)

    return LinkResponse(
        code=link.code,
        original_url=link.original_url,
    )


@app.get("/links/{code}", response_model=LinkResponse)
def get_link(code: str, db: Session = Depends(get_db)) -> LinkResponse:
    link = db.query(Link).filter(Link.code == code).first()

    if link is None:
        raise HTTPException(status_code=404, detail="link not found")

    click_event = ClickEvent(link_id=link.id)
    db.add(click_event)
    db.commit()

    return LinkResponse(
        code=link.code,
        original_url=link.original_url,
    )


@app.get("/links/{code}/stats", response_model=LinkStatsResponse)
def get_link_stats(code: str, db: Session = Depends(get_db)) -> LinkStatsResponse:
    link = db.query(Link).filter(Link.code == code).first()

    if link is None:
        raise HTTPException(status_code=404, detail="link not found")

    accesses = db.query(ClickEvent).filter(ClickEvent.link_id == link.id).count()

    return LinkStatsResponse(
        code=link.code,
        accesses=accesses,
    )
