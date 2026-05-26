from pydantic import BaseModel
from typing import Optional


class BudgetCreate(BaseModel):

    user_email: str

    category: str

    monthly_limit: float

    current_spent: Optional[float] = 0