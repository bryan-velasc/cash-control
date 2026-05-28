from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TransactionCreate(BaseModel):

    user_email: str

    type: str

    category: str

    amount: float

    description: str

    note: Optional[str] = ""

    source_mode: Optional[str] = "general"

    source_transaction_id: Optional[str] = None

    source_transaction_name: Optional[str] = None

    created_at: datetime = datetime.utcnow()