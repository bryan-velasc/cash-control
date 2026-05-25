from fastapi import APIRouter, HTTPException

from bson import ObjectId

from app.database.database import db

from app.models.goal_model import GoalCreate

router = APIRouter()

goals_collection = db["goals"]


@router.post("/goals/create")
async def create_goal(goal: GoalCreate):

    try:

        result = await goals_collection.insert_one({

            "user_email": goal.user_email,

            "goal_name": goal.goal_name,

            "target_amount": goal.target_amount,

            "current_amount": goal.current_amount,

            "completed": False,

            "created_at": goal.created_at
        })

        return {

            "message": "Goal created",

            "goal_id": str(result.inserted_id)
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/goals/{user_email}")
async def get_goals(user_email: str):

    try:

        cursor = goals_collection.find({
            "user_email": user_email
        })

        goals = []

        async for goal in cursor:

            goal["_id"] = str(goal["_id"])

            target = goal.get("target_amount", 0)

            current = goal.get("current_amount", 0)

            if target > 0:

                progress = (current / target) * 100

            else:

                progress = 0

            if progress >= 100:

                progress = 100

            goal["progress"] = progress

            goal["remaining_amount"] = max(
                target - current,
                0
            )

            goals.append(goal)

        return goals

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.put("/goals/add-saving/{goal_id}")
async def add_saving_to_goal(
    goal_id: str,
    data: dict
):

    try:

        amount = float(
            data.get("amount", 0)
        )

        goal = await goals_collection.find_one({
            "_id": ObjectId(goal_id)
        })

        if not goal:

            raise HTTPException(
                status_code=404,
                detail="Meta no encontrada"
            )

        new_amount = (
            goal["current_amount"] +
            amount
        )

        completed = (
            new_amount >=
            goal["target_amount"]
        )

        await goals_collection.update_one(

            {
                "_id": ObjectId(goal_id)
            },

            {
                "$set": {
                    "current_amount": new_amount,
                    "completed": completed
                }
            }
        )

        return {
            "message": "Ahorro agregado",
            "current_amount": new_amount,
            "completed": completed
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.put("/goals/update/{goal_id}")
async def update_goal(
    goal_id: str,
    data: dict
):

    try:

        update_data = {}

        if "goal_name" in data:
            update_data["goal_name"] = data["goal_name"]

        if "target_amount" in data:
            update_data["target_amount"] = float(
                data["target_amount"]
            )

        if "current_amount" in data:
            update_data["current_amount"] = float(
                data["current_amount"]
            )

        await goals_collection.update_one(

            {
                "_id": ObjectId(goal_id)
            },

            {
                "$set": update_data
            }
        )

        return {
            "message": "Meta actualizada"
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.delete("/goals/{goal_id}")
async def delete_goal(goal_id: str):

    try:

        await goals_collection.delete_one({
            "_id": ObjectId(goal_id)
        })

        return {
            "message": "Meta eliminada"
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )