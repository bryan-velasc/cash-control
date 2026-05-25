from fastapi import APIRouter, HTTPException
from bson import ObjectId
from datetime import datetime

from app.database.database import db
from app.models.goal_model import GoalCreate

router = APIRouter()

goals_collection = db["Objetivos"]


@router.post("/goals/create")
async def create_goal(goal: GoalCreate):
    try:
        result = await goals_collection.insert_one({
            "user_email": goal.user_email,
            "goal_name": goal.goal_name,
            "target_amount": float(goal.target_amount),
            "current_amount": float(goal.current_amount or 0),
            "completed": False,
            "created_at": datetime.utcnow().isoformat(),
        })

        return {
            "message": "Goal created",
            "goal_id": str(result.inserted_id),
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


@router.get("/goals/{user_email}")
async def get_goals(user_email: str):
    try:
        cursor = goals_collection.find({
            "user_email": user_email,
        })

        goals = []

        async for goal in cursor:
            goal_id = str(goal["_id"])

            target = float(goal.get("target_amount", 0))
            current = float(goal.get("current_amount", 0))

            progress = (current / target) * 100 if target > 0 else 0

            if progress > 100:
                progress = 100

            goals.append({
                "id": goal_id,
                "_id": goal_id,
                "user_email": goal.get("user_email", ""),
                "goal_name": goal.get("goal_name", "Meta sin nombre"),
                "target_amount": target,
                "current_amount": current,
                "completed": goal.get("completed", False),
                "created_at": goal.get("created_at", ""),
                "progress": progress,
                "remaining_amount": max(target - current, 0),
            })

        return goals

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


@router.put("/goals/add-saving/{goal_id}")
async def add_saving_to_goal(goal_id: str, data: dict):
    try:
        amount = float(data.get("amount", 0))

        if amount <= 0:
            raise HTTPException(
                status_code=400,
                detail="La cantidad debe ser mayor a 0",
            )

        goal = await goals_collection.find_one({
            "_id": ObjectId(goal_id),
        })

        if not goal:
            raise HTTPException(
                status_code=404,
                detail="Meta no encontrada",
            )

        current_amount = float(goal.get("current_amount", 0))
        target_amount = float(goal.get("target_amount", 0))

        new_amount = current_amount + amount
        completed = new_amount >= target_amount

        await goals_collection.update_one(
            {
                "_id": ObjectId(goal_id),
            },
            {
                "$set": {
                    "current_amount": new_amount,
                    "completed": completed,
                },
            },
        )

        progress = (new_amount / target_amount) * 100 if target_amount > 0 else 0

        if progress > 100:
            progress = 100

        return {
            "message": "Ahorro agregado",
            "current_amount": new_amount,
            "completed": completed,
            "progress": progress,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


@router.put("/goals/update/{goal_id}")
async def update_goal(goal_id: str, data: dict):
    try:
        update_data = {}

        if "goal_name" in data:
            update_data["goal_name"] = data["goal_name"]

        if "target_amount" in data:
            update_data["target_amount"] = float(data["target_amount"])

        if "current_amount" in data:
            update_data["current_amount"] = float(data["current_amount"])

        if not update_data:
            raise HTTPException(
                status_code=400,
                detail="No hay datos para actualizar",
            )

        result = await goals_collection.update_one(
            {
                "_id": ObjectId(goal_id),
            },
            {
                "$set": update_data,
            },
        )

        if result.matched_count == 0:
            raise HTTPException(
                status_code=404,
                detail="Meta no encontrada",
            )

        return {
            "message": "Meta actualizada",
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


@router.delete("/goals/{goal_id}")
async def delete_goal(goal_id: str):
    try:
        result = await goals_collection.delete_one({
            "_id": ObjectId(goal_id),
        })

        if result.deleted_count == 0:
            raise HTTPException(
                status_code=404,
                detail="Meta no encontrada",
            )

        return {
            "message": "Meta eliminada",
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )