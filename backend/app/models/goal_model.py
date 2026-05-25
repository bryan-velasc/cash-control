from pydantic import BaseModel
from typing import Optional


class GoalCreate(BaseModel):

    user_email: str

    goal_name: str

    target_amount: float

    current_amount: Optional[float] = 0