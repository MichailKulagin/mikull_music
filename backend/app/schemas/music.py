from pydantic import BaseModel
from typing import Optional

class TrackSchema(BaseModel):
    id: str
    title: str
    artist: str
    album: Optional[str] = None
    duration: int
    cover_url: Optional[str] = None
    provider: str
