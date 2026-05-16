from pydantic import BaseModel

from datetime import datetime


class GoalCreate(BaseModel):

    user_email: str

    goal_name: str

    target_amount: float

    current_amount: float = 0

    created_at: datetime = datetime.utcnow()