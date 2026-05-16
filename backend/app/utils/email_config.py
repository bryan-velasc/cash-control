from fastapi_mail import ConnectionConfig

from dotenv import load_dotenv

import os

# CARGAR .env
load_dotenv()

MAIL_USERNAME = os.getenv(
    "MAIL_USERNAME"
)

MAIL_PASSWORD = os.getenv(
    "MAIL_PASSWORD"
)

MAIL_FROM = os.getenv(
    "MAIL_FROM"
)

MAIL_PORT = os.getenv(
    "MAIL_PORT"
)

MAIL_SERVER = os.getenv(
    "MAIL_SERVER"
)

conf = ConnectionConfig(

    MAIL_USERNAME=MAIL_USERNAME,

    MAIL_PASSWORD=MAIL_PASSWORD,

    MAIL_FROM=MAIL_FROM,

    MAIL_PORT=int(MAIL_PORT),

    MAIL_SERVER=MAIL_SERVER,

    MAIL_STARTTLS=True,

    MAIL_SSL_TLS=False,

    USE_CREDENTIALS=True
)