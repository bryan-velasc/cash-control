from fastapi import APIRouter, HTTPException
from app.models.ocr_model import OCRAnalyzeRequest
import re

router = APIRouter()


@router.post("/ocr/analyze")
async def analyze_ocr(data: OCRAnalyzeRequest):
    try:
        text = data.text
        lower_text = text.lower()

        amount = extract_amount(text)
        store = extract_store(text)
        date = extract_date(text)
        category = detect_category(lower_text)

        description = f"OCR - {store}" if store else "OCR - Ticket detectado"

        return {
            "store": store,
            "amount": amount,
            "date": date,
            "category": category,
            "description": description,
            "raw_text": text,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


def extract_amount(text: str):
    patterns = [
        r"total\s*[:$]?\s*\$?\s*(\d{1,6}[.,]\d{2})",
        r"importe\s*[:$]?\s*\$?\s*(\d{1,6}[.,]\d{2})",
        r"pago\s*[:$]?\s*\$?\s*(\d{1,6}[.,]\d{2})",
        r"\$?\s*(\d{1,6}[.,]\d{2})",
    ]

    amounts = []

    for pattern in patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)

        for match in matches:
            value = match.replace(",", ".")

            try:
                amounts.append(float(value))
            except:
                pass

    if not amounts:
        return None

    return max(amounts)


def extract_store(text: str):
    lines = [
        line.strip()
        for line in text.split("\n")
        if line.strip()
    ]

    if not lines:
        return None

    ignored_words = [
        "ticket",
        "fecha",
        "total",
        "subtotal",
        "iva",
        "cambio",
        "efectivo",
        "tarjeta",
        "importe",
    ]

    for line in lines[:6]:
        lower = line.lower()

        if not any(word in lower for word in ignored_words):
            return line

    return lines[0]


def extract_date(text: str):
    patterns = [
        r"\d{2}/\d{2}/\d{4}",
        r"\d{2}-\d{2}-\d{4}",
        r"\d{2}/\d{2}/\d{2}",
        r"\d{2}-\d{2}-\d{2}",
        r"\d{4}-\d{2}-\d{2}",
    ]

    for pattern in patterns:
        match = re.search(pattern, text)

        if match:
            return match.group(0)

    return None


def detect_category(lower_text: str):
    if any(word in lower_text for word in [
        "oxxo",
        "walmart",
        "soriana",
        "bodega",
        "super",
        "mercado",
        "abarrotes",
    ]):
        return "Supermercado"

    if any(word in lower_text for word in [
        "pemex",
        "gasolina",
        "combustible",
        "gas",
        "uber",
        "didi",
        "taxi",
    ]):
        return "Transporte"

    if any(word in lower_text for word in [
        "farmacia",
        "similares",
        "guadalajara",
        "medicina",
        "consulta",
    ]):
        return "Salud"

    if any(word in lower_text for word in [
        "cine",
        "netflix",
        "spotify",
        "playstation",
        "xbox",
    ]):
        return "Entretenimiento"

    if any(word in lower_text for word in [
        "restaurante",
        "restaurant",
        "pizza",
        "burger",
        "cafe",
        "tacos",
        "comida",
    ]):
        return "Comida"

    if any(word in lower_text for word in [
        "telcel",
        "cfe",
        "agua",
        "internet",
        "izzi",
        "telmex",
    ]):
        return "Servicios"

    return "Compras"