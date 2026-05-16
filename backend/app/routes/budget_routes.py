from fastapi import APIRouter, HTTPException

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

        new_budget = {

            "user_email":
                budget.user_email,

            "category":
                budget.category,

            "limit":
                budget.limit
        }

        await budgets_collection.insert_one(
            new_budget
        )

        return {
            "message":
                "Budget created"
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

            budget["_id"] = str(
                budget["_id"]
            )

            budgets.append(budget)

        return budgets

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )