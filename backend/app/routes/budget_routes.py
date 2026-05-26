from fastapi import APIRouter, HTTPException
from bson import ObjectId
from datetime import datetime

from app.database.database import db

from app.models.budget_model import (
    BudgetCreate
)

router = APIRouter()

budgets_collection = db["budgets"]


@router.post("/budgets/create")
async def create_budget(
    budget: BudgetCreate
):

    try:

        existing_budget = await budgets_collection.find_one({
            "user_email": budget.user_email,
            "category": budget.category,
        })

        if existing_budget:

            raise HTTPException(
                status_code=400,
                detail="Ya existe un presupuesto para esta categoría"
            )

        new_budget = {

            "user_email":
                budget.user_email,

            "category":
                budget.category,

            "monthly_limit":
                float(budget.monthly_limit),

            "current_spent":
                float(budget.current_spent or 0),

            "created_at":
                datetime.utcnow().isoformat()
        }

        result = await budgets_collection.insert_one(
            new_budget
        )

        return {
            "message":
                "Budget created",

            "budget_id":
                str(result.inserted_id)
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/budgets/{user_email}")
async def get_budgets(
    user_email: str
):

    try:

        cursor = budgets_collection.find({

            "user_email":
                user_email
        })

        budgets = []

        async for budget in cursor:

            budget_id = str(
                budget["_id"]
            )

            monthly_limit = float(
                budget.get(
                    "monthly_limit",
                    budget.get("limit", 0)
                )
            )

            current_spent = float(
                budget.get(
                    "current_spent",
                    0
                )
            )

            progress = (
                (current_spent / monthly_limit) * 100
                if monthly_limit > 0
                else 0
            )

            if progress > 100:
                progress = 100

            status = "normal"

            if progress >= 100:
                status = "exceeded"

            elif progress >= 80:
                status = "warning"

            budgets.append({

                "id":
                    budget_id,

                "_id":
                    budget_id,

                "user_email":
                    budget.get(
                        "user_email",
                        ""
                    ),

                "category":
                    budget.get(
                        "category",
                        "General"
                    ),

                "monthly_limit":
                    monthly_limit,

                "current_spent":
                    current_spent,

                "remaining":
                    max(
                        monthly_limit - current_spent,
                        0
                    ),

                "progress":
                    progress,

                "status":
                    status,

                "created_at":
                    budget.get(
                        "created_at",
                        ""
                    )
            })

        return budgets

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.put("/budgets/add-spent/{budget_id}")
async def add_spent_to_budget(
    budget_id: str,
    data: dict
):

    try:

        amount = float(
            data.get(
                "amount",
                0
            )
        )

        if amount <= 0:

            raise HTTPException(
                status_code=400,
                detail="La cantidad debe ser mayor a 0"
            )

        budget = await budgets_collection.find_one({
            "_id": ObjectId(budget_id)
        })

        if not budget:

            raise HTTPException(
                status_code=404,
                detail="Presupuesto no encontrado"
            )

        current_spent = float(
            budget.get(
                "current_spent",
                0
            )
        )

        monthly_limit = float(
            budget.get(
                "monthly_limit",
                budget.get("limit", 0)
            )
        )

        new_spent = (
            current_spent +
            amount
        )

        await budgets_collection.update_one(

            {
                "_id":
                    ObjectId(budget_id)
            },

            {
                "$set": {

                    "current_spent":
                        new_spent
                }
            }
        )

        progress = (
            (new_spent / monthly_limit) * 100
            if monthly_limit > 0
            else 0
        )

        if progress > 100:
            progress = 100

        return {

            "message":
                "Gasto agregado al presupuesto",

            "current_spent":
                new_spent,

            "remaining":
                max(
                    monthly_limit - new_spent,
                    0
                ),

            "progress":
                progress
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.delete("/budgets/{budget_id}")
async def delete_budget(
    budget_id: str
):

    try:

        result = await budgets_collection.delete_one({
            "_id": ObjectId(budget_id)
        })

        if result.deleted_count == 0:

            raise HTTPException(
                status_code=404,
                detail="Presupuesto no encontrado"
            )

        return {
            "message":
                "Presupuesto eliminado"
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )