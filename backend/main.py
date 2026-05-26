from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI

from app.database.database import db

from app.routes.auth_routes import (
    router as auth_router
)

from app.routes.transaction_routes import (
    router as transaction_router
)

from app.routes.notification_routes import (
    router as notification_router
)

from app.routes.goal_routes import (
    router as goal_router
)

from app.routes.ocr_routes import (
    router as ocr_router
)

from app.routes.copilot_routes import (
    router as copilot_router
)

# from app.routes.budget_routes import (
#     router as budget_router
# )

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(transaction_router)
app.include_router(notification_router)
app.include_router(goal_router)
app.include_router(ocr_router)
app.include_router(copilot_router)

# app.include_router(budget_router)


@app.get("/")
async def root():
    return {
        "message": "Cash-Control API Online"
    }


@app.get("/test-db")
async def test_database():
    collections = await db.list_collection_names()

    return {
        "database": "connected",
        "collections": collections
    }