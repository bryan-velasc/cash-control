from fastapi import (
    APIRouter,
    HTTPException
)

from fastapi_mail import (
    FastMail,
    MessageSchema
)

from app.database.database import db

from app.models.user_model import (
    UserRegister,
    UserLogin
)

from app.utils.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_reset_token,
    verify_reset_token
)

from app.utils.email_config import conf

router = APIRouter()

users_collection = db["users"]


# =========================================================
# REGISTRO
# =========================================================

@router.post("/register")
async def register_user(
    user: UserRegister
):

    existing_user = await users_collection.find_one({
        "email": user.email
    })

    if existing_user:

        raise HTTPException(
            status_code=400,
            detail="El usuario ya existe"
        )

    hashed_password = hash_password(
        user.password
    )

    new_user = {

        "name": user.name,

        "email": user.email,

        "password": hashed_password,

        "google_account": False
    }

    await users_collection.insert_one(
        new_user
    )

    return {
        "message":
            "Usuario creado correctamente"
    }


# =========================================================
# LOGIN NORMAL
# =========================================================

@router.post("/login")
async def login_user(
    user: UserLogin
):

    try:

        existing_user = await users_collection.find_one({
            "email": user.email
        })

        if not existing_user:

            raise HTTPException(
                status_code=404,
                detail="Usuario no encontrado"
            )

        if existing_user.get(
            "google_account"
        ):

            raise HTTPException(
                status_code=401,
                detail="Esta cuenta fue creada con Google"
            )

        valid_password = verify_password(

            user.password,

            existing_user["password"]
        )

        if not valid_password:

            raise HTTPException(
                status_code=401,
                detail="Contraseña incorrecta"
            )

        token = create_access_token({

            "sub":
                existing_user["email"]
        })

        return {

            "token": token,

            "user": {

                "name":
                    existing_user["name"],

                "email":
                    existing_user["email"]
            }
        }

    except Exception as e:

        print(e)

        raise HTTPException(
            status_code=500,
            detail="Error interno servidor"
        )


# =========================================================
# GOOGLE LOGIN
# =========================================================

@router.post("/google-login")
async def google_login(
    data: dict
):

    try:

        email = data.get("email")

        name = data.get(
            "name",
            "Google User"
        )

        existing_user = await users_collection.find_one({
            "email": email
        })

        if not existing_user:

            new_user = {

                "name": name,

                "email": email,

                "password": "",

                "google_account": True
            }

            await users_collection.insert_one(
                new_user
            )

        token = create_access_token({
            "sub": email
        })

        return {

            "token": token,

            "email": email
        }

    except Exception as e:

        print(e)

        raise HTTPException(
            status_code=500,
            detail="Error Google Login"
        )


# =========================================================
# FORGOT PASSWORD
# =========================================================

@router.post("/forgot-password")
async def forgot_password(
    data: dict
):

    email = data.get("email")

    existing_user = await users_collection.find_one({
        "email": email
    })

    if not existing_user:

        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado"
        )

    token = create_reset_token(
        email
    )

    reset_link = f"""

reset_link = f"https://cash-control-3vhg.onrender.com/reset-password?token={token}"

"""

    html = f"""

    <h2>CASH-CONTROL</h2>

    <p>Hola {existing_user['name']}</p>

    <p>Haz clic abajo para cambiar tu contraseña:</p>

    <a href="{reset_link}">
        RESTABLECER CONTRASEÑA
    </a>

    <p>Este enlace expira en 30 minutos.</p>

    """

    message = MessageSchema(

        subject=
            "Recuperación de contraseña",

        recipients=[email],

        body=html,

        subtype="html"
    )

    fm = FastMail(conf)

    await fm.send_message(message)

    return {

        "message":
            "Correo enviado correctamente"
    }


# =========================================================
# RESET PASSWORD
# =========================================================

@router.post("/reset-password")
async def reset_password(
    data: dict
):

    token = data.get("token")

    new_password = data.get(
        "password"
    )

    email = verify_reset_token(
        token
    )

    if not email:

        raise HTTPException(
            status_code=401,
            detail="Token inválido"
        )

    hashed_password = hash_password(
        new_password
    )

    await users_collection.update_one(

        {
            "email": email
        },

        {
            "$set": {
                "password":
                    hashed_password
            }
        }
    )

    return {
        "message":
            "Contraseña actualizada"
    }