from abc import ABC, abstractmethod
from typing import List, Optional
from app.schemas.music import TrackSchema

class BaseMusicProvider(ABC):
    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Возвращает уникальное имя провайдера (например, 'audius')"""
        pass

    @abstractmethod
    async def search(self, query: str, limit: int = 10) -> List[TrackSchema]:
        """Поиск треков в конкретном сервисе"""
        pass

    @abstractmethod
    async def get_track_by_id(self, track_id: str) -> Optional[TrackSchema]:
        """Получение информации о треке по его ID"""
        pass
