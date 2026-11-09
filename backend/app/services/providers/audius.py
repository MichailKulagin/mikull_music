import httpx
from typing import List, Optional
from app.services.providers.base import BaseMusicProvider
from app.schemas.music import TrackSchema

class AudiusProvider(BaseMusicProvider):
    def __init__(self):
        # Используем официальную дефолтную ноду (в продакшене лучше динамически выбирать рабочую)
        self.base_url = "https://audius.co"
        self.client = httpx.AsyncClient()

    @property
    def provider_name(self) -> str:
        return "audius"

    async def search(self, query: str, limit: int = 10) -> List[TrackSchema]:
        url = f"{self.base_url}/tracks/search"
        try:
            response = await self.client.get(url, params={"query": query, "limit": limit})
            if response.status_code != 200:
                return []
            
            data = response.json().get("data", [])
            tracks = []
            for item in data:
                # Маппим данные из формата Audius в нашу единую схему TrackSchema
                tracks.append(TrackSchema(
                    id=f"audius_{item['id']}",
                    title=item.get("title", "Unknown"),
                    artist=item.get("user", {}).get("name", "Unknown Artist"),
                    duration=item.get("duration", 0),
                    cover_url=item.get("artwork", {}).get("150x150"),
                    provider=self.provider_name
                ))
            return tracks
        except Exception:
            return []

    async def get_track_by_id(self, track_id: str) -> Optional[TrackSchema]:
        # Удаляем префикс 'audius_', чтобы получить чистый ID для API
        pure_id = track_id.replace("audius_", "")
        url = f"{self.base_url}/tracks/{pure_id}"
        try:
            response = await self.client.get(url)
            if response.status_code != 200:
                return None
            
            item = response.json().get("data", {})
            return TrackSchema(
                id=track_id,
                title=item.get("title", "Unknown"),
                artist=item.get("user", {}).get("name", "Unknown Artist"),
                duration=item.get("duration", 0),
                cover_url=item.get("artwork", {}).get("150x150"),
                provider=self.provider_name
            )
        except Exception:
            return None
