from fastapi import APIRouter

# Именно эту переменную 'router' сейчас ищет файл main.py
router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "OK", "message": "Server is running"}
