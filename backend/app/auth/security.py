import hashlib

from jose import jwt
from datetime import datetime, timedelta

SECRET_KEY = "cashcontrolsecret"
ALGORITHM = "HS256"


def hash_password(password: str):

    return hashlib.sha256(
        password.encode()
    ).hexdigest()


def verify_password(password: str, hashed: str):

    return hashlib.sha256(
        password.encode()
    ).hexdigest() == hashed


def create_access_token(data: dict):

    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(days=7)

    to_encode.update({
        "exp": expire
    })

    return jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )