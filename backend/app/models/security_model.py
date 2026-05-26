from pydantic import BaseModel
from typing import Optional


class SecurityAnalyzeRequest(BaseModel):
    user_email: Optional[str] = None
    content: str
    source: Optional[str] = "manual"