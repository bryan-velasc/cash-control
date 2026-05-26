from pydantic import BaseModel


class OCRAnalyzeRequest(BaseModel):
    text: str