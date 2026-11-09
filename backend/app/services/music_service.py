from typing import List, Optional
from app.schemas.music import TrackSchema
from app.services.providers.audius import AudiusProvider
# Сюда потом импортируем JamendoProvider, DeezerProvider и т.д.

class MusicService:
    def __init__(self):
        # Инициализируем список активных провайдеров
        self.providers = [
            AudiusProvider(),
            # JamendoProvider(),
        ]

    async def search_everywhere(self, query: str) -> List[TrackSchema]:
        combined_results = []
        for provider in self.providers:
            results = await provider.search(query=query)
            combined_results.extend(results)
        return combined_results

    async def get_track(self, track_id: str) -> Optional[TrackSchema]:
        # Определяем провайдера по префиксу ID (например, audius_12345)
        for provider in self.providers:
            if track_id.startswith(f"{provider.provider_name}_"):
                return await provider.get_track_by_id(track_id)
        return None
