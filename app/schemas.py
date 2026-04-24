from pydantic import BaseModel, HttpUrl


class LinkCreate(BaseModel):
    original_url: HttpUrl


class LinkResponse(BaseModel):
    code: str
    original_url: str


class LinkStatsResponse(BaseModel):
    code: str
    accesses: int
