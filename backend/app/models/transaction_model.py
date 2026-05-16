from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TransactionCreate(BaseModel):

    user_email: str

    type: str

    category: str

    amount: float

    description: Optional[str] = ""

    created_at: Optional[datetime] = datetime.utcnow()