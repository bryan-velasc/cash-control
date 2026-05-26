from fastapi import APIRouter, HTTPException
from datetime import datetime
import re

from app.database.database import db
from app.models.security_model import SecurityAnalyzeRequest

router = APIRouter()

security_logs_collection = db["security_logs"]


@router.post("/security/analyze")
async def analyze_security(data: SecurityAnalyzeRequest):
    try:
        content = data.content.strip()
        lower = content.lower()

        score = 0
        threats = []

        suspicious_words = [
            "bloqueada",
            "suspendida",
            "verifica tu cuenta",
            "actualiza tus datos",
            "urgente",
            "premio",
            "ganaste",
            "contraseña",
            "token",
            "nip",
            "cvv",
            "tarjeta",
            "transferencia",
            "deposito",
            "depósito",
            "banco",
            "iniciar sesión",
            "reactivar",
        ]

        for word in suspicious_words:
            if word in lower:
                score += 10
                threats.append(f"Palabra sospechosa detectada: {word}")

        urls = extract_urls(content)

        for url in urls:
            url_lower = url.lower()

            if is_shortened_url(url_lower):
                score += 20
                threats.append(f"URL acortada detectada: {url}")

            if has_suspicious_domain(url_lower):
                score += 25
                threats.append(f"Dominio sospechoso detectado: {url}")

            if has_fake_bank_pattern(url_lower):
                score += 30
                threats.append(f"Posible banco falso detectado: {url}")

        if asks_for_sensitive_data(lower):
            score += 35
            threats.append("Solicita datos sensibles como contraseña, NIP, CVV o token")

        if has_urgency_pattern(lower):
            score += 15
            threats.append("Usa lenguaje de urgencia o presión")

        if score >= 80:
            risk = "alto"
            recommendation = "No abras enlaces ni compartas datos. El contenido parece altamente riesgoso."
        elif score >= 45:
            risk = "medio"
            recommendation = "Ten precaución. Verifica directamente desde la app o sitio oficial."
        else:
            risk = "bajo"
            recommendation = "No se detectaron señales fuertes de amenaza, pero revisa el origen."

        result = {
            "risk": risk,
            "score": min(score, 100),
            "threats": threats,
            "urls": urls,
            "recommendation": recommendation,
            "source": data.source,
            "created_at": datetime.utcnow().isoformat(),
        }

        if data.user_email:
            await security_logs_collection.insert_one({
                "user_email": data.user_email,
                "content": content,
                **result,
            })

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/security/logs/{user_email}")
async def get_security_logs(user_email: str):
    try:
        cursor = security_logs_collection.find({
            "user_email": user_email
        })

        logs = []

        async for log in cursor:
            log["_id"] = str(log["_id"])
            logs.append(log)

        return logs

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def extract_urls(text: str):
    pattern = r"(https?://[^\s]+|www\.[^\s]+)"
    return re.findall(pattern, text)


def is_shortened_url(url: str):
    shorteners = [
        "bit.ly",
        "tinyurl.com",
        "t.co",
        "goo.gl",
        "ow.ly",
        "is.gd",
        "cutt.ly",
        "rebrand.ly",
    ]

    return any(shortener in url for shortener in shorteners)


def has_suspicious_domain(url: str):
    suspicious_terms = [
        "login",
        "verify",
        "verificar",
        "seguridad",
        "bloqueo",
        "reactivar",
        "update",
        "account",
        "cuenta",
    ]

    return any(term in url for term in suspicious_terms)


def has_fake_bank_pattern(url: str):
    banks = [
        "bbva",
        "banamex",
        "santander",
        "banorte",
        "hsbc",
        "scotiabank",
        "bancoazteca",
        "mercadopago",
        "paypal",
    ]

    fake_indicators = [
        "-secure",
        "-login",
        "login-",
        "secure-",
        "verifica",
        "reactiva",
        "soporte",
        "cliente",
    ]

    return any(bank in url for bank in banks) and any(
        indicator in url for indicator in fake_indicators
    )


def asks_for_sensitive_data(text: str):
    sensitive = [
        "contraseña",
        "password",
        "nip",
        "cvv",
        "token",
        "código",
        "codigo",
        "pin",
        "datos de tu tarjeta",
        "número de tarjeta",
        "numero de tarjeta",
    ]

    return any(item in text for item in sensitive)


def has_urgency_pattern(text: str):
    urgency = [
        "urgente",
        "última oportunidad",
        "ultima oportunidad",
        "en 24 horas",
        "inmediatamente",
        "evita el bloqueo",
        "será bloqueada",
        "sera bloqueada",
        "suspendida",
        "bloqueada",
    ]

    return any(item in text for item in urgency)