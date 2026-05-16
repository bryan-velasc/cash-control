from pydantic import BaseModel

class BudgetCreate(BaseModel):

    user_email: str

    category: str

    limit: float