from fastapi import APIRouter, HTTPException

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

            goals.append(goal)

        return goals

    except Exception as e:

        raise HTTPException(

            status_code=500,

            detail=str(e)
        )