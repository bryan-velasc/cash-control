from pydantic import BaseModel

from datetime import datetime


class NotificationCreate(BaseModel):

    user_email: str

    title: str

    message: str

    type: str

    read: bool = False

    created_at: datetime = datetime.utcnow()