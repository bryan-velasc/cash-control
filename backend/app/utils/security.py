from passlib.context import CryptContext

from jose import jwt

from datetime import datetime, timedelta


SECRET_KEY = "cash-control-secret-key"

ALGORITHM = "HS256"

ACCESS_TOKEN_EXPIRE_MINUTES = 60


pwd_context = CryptContext(
    schemes=["pbkdf2_sha256"],
    deprecated="auto"
)

def hash_password(password: str):


    return pwd_context.hash(password)


def verify_password(
    plain_password: str,
    hashed_password: str
):

    return pwd_context.verify(
        plain_password,
        hashed_password
    )


def create_access_token(data: dict):

    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    to_encode.update({
        "exp": expire
    })

    encoded_jwt = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return encoded_jwt

from datetime import datetime, timedelta

SECRET_KEY = "cash-control-secret"

ALGORITHM = "HS256"


def create_reset_token(email: str):

    expire = datetime.utcnow() + timedelta(
        minutes=30
    )

    data = {

        "sub": email,

        "exp": expire
    }

    return jwt.encode(

        data,

        SECRET_KEY,

        algorithm=ALGORITHM
    )


def verify_reset_token(token: str):

    try:

        payload = jwt.decode(

            token,

            SECRET_KEY,

            algorithms=[ALGORITHM]
        )

        return payload["sub"]

    except:

        return None