import os
import httpx
from dotenv import load_dotenv

load_dotenv()

N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL")

async def send_n8n_alert(data: dict):

    print("N8N URL USADA:", N8N_WEBHOOK_URL)

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                N8N_WEBHOOK_URL,
                json=data,
                timeout=10
            )

            print("N8N STATUS:", response.status_code)
            print("N8N RESPONSE:", response.text)

    except Exception as e:
        print("N8N ERROR:", e)