import httpx

N8N_WEBHOOK_URL = (
    "https://TU-N8N.app.n8n.cloud/"
    "webhook/cash-control-alert"
)

async def send_n8n_alert(data):

    try:

        async with httpx.AsyncClient() as client:

            response = await client.post(

                N8N_WEBHOOK_URL,

                json=data,

                timeout=10
            )

            print(
                "N8N RESPONSE:",
                response.status_code
            )

            print(response.text)

    except Exception as e:

        print("N8N ERROR:")
        print(e)