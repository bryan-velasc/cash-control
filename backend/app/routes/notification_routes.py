from fastapi import APIRouter, HTTPException

from app.database.database import db


router = APIRouter()

notifications_collection = db["notifications"]


@router.get("/notifications/{user_email}")
async def get_notifications(
    user_email: str
):

    try:

        cursor = notifications_collection.find({
            "user_email": user_email
        }).sort("created_at", -1)

        notifications = []

        async for notification in cursor:

            notification["_id"] = str(
                notification["_id"]
            )

            notifications.append(
                notification
            )

        return notifications

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.put("/notifications/read/{notification_id}")
async def mark_notification_read(
    notification_id: str
):

    try:

        from bson import ObjectId

        await notifications_collection.update_one(

            {
                "_id": ObjectId(
                    notification_id
                )
            },

            {
                "$set": {
                    "read": True
                }
            }
        )

        return {
            "message": "Notificación marcada como leída"
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.delete("/notifications/{notification_id}")
async def delete_notification(
    notification_id: str
):

    try:

        from bson import ObjectId

        await notifications_collection.delete_one({

            "_id": ObjectId(
                notification_id
            )
        })

        return {
            "message": "Notificación eliminada"
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )