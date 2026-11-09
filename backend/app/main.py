from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import health, search  # Убрали tracks отсюда

app = FastAPI(title="MikuMusic 2.0 API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/api/v1", tags=["Health"])
app.include_router(search.router, prefix="/api/v1", tags=["Search"])
# Сроку с tracks тоже временно комментируем символом #
# app.include_router(tracks.router, prefix="/api/v1", tags=["Tracks"])
