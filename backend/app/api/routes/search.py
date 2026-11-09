from fastapi import APIRouter
from typing import List, Optional
from pydantic import BaseModel

class TrackSchema(BaseModel):
    id: str
    title: str
    artist: str
    album: Optional[str] = None
    duration: int
    cover_url: Optional[str] = None
    audio_url: str
    provider: str

router = APIRouter()

@router.get("/search", response_model=List[TrackSchema])
async def search_music(q: str):
    if not q.strip():
        return []
        
    print(f"Поиск трека в автономном режиме для запроса: {q}")

    # Стабильные прямые ссылки на тестовые mp3-файлы из открытого архива SoundHelix
    return [
        TrackSchema(
            id="local_mix_1",
            title=f"{q.capitalize()} (Remix Vol. 1)",
            artist="Miku Synth Electro",
            album="Cyber Wave",
            duration=372,
            cover_url="https://picsum.photos",
            audio_url="https://soundhelix.com",
            provider="local_mix"
        ),
        TrackSchema(
            id="local_mix_2",
            title=f"Vibe of {q.capitalize()}",
            artist="Neon Station",
            album="Night Drive",
            duration=423,
            cover_url="https://picsum.photos",
            audio_url="https://soundhelix.com",
            provider="local_mix"
        ),
        TrackSchema(
            id="local_mix_3",
            title=f"Chill {q.capitalize()} Beats",
            artist="Lofi Dreamer",
            album="Cozy Room",
            duration=302,
            cover_url="https://picsum.photos",
            audio_url="https://soundhelix.com",
            provider="local_mix"
        )
    ]
