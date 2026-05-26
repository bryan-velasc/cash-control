from pydantic import BaseModel


class CopilotRequest(BaseModel):
    user_email: str
    message: str