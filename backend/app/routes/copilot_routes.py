from fastapi import APIRouter, HTTPException

from app.database.database import db
from app.models.copilot_model import CopilotRequest

router = APIRouter()

transactions_collection = db["transactions"]
budgets_collection = db["budgets"]
goals_collection = db["Objetivos"]


@router.post("/copilot/chat")
async def copilot_chat(data: CopilotRequest):
    try:
        user_email = data.user_email
        message = data.message.lower()

        transactions = []
        budgets = []
        goals = []

        transactions_cursor = transactions_collection.find({
            "user_email": user_email
        })

        async for tx in transactions_cursor:
            transactions.append(tx)

        budgets_cursor = budgets_collection.find({
            "user_email": user_email
        })

        async for budget in budgets_cursor:
            budgets.append(budget)

        goals_cursor = goals_collection.find({
            "user_email": user_email
        })

        async for goal in goals_cursor:
            goals.append(goal)

        income = 0
        expenses = 0
        expenses_by_category = {}

        for tx in transactions:
            amount = float(tx.get("amount", 0))
            tx_type = tx.get("type", "")
            category = tx.get("category", "Otros")

            if tx_type == "income":
                income += amount

            elif tx_type == "expense":
                expenses += amount

                if category not in expenses_by_category:
                    expenses_by_category[category] = 0

                expenses_by_category[category] += amount

        balance = income - expenses

        response = generate_copilot_response(
            message=message,
            income=income,
            expenses=expenses,
            balance=balance,
            expenses_by_category=expenses_by_category,
            budgets=budgets,
            goals=goals,
        )

        return {
            "reply": response,
            "summary": {
                "income": income,
                "expenses": expenses,
                "balance": balance,
                "budgets": len(budgets),
                "goals": len(goals),
            }
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


def generate_copilot_response(
    message,
    income,
    expenses,
    balance,
    expenses_by_category,
    budgets,
    goals,
):
    if "gasto" in message or "gasto más" in message:
        if not expenses_by_category:
            return "Aún no tienes gastos registrados. Cuando registres movimientos podré decirte en qué categoría gastas más."

        top_category = max(
            expenses_by_category,
            key=expenses_by_category.get,
        )

        top_amount = expenses_by_category[top_category]

        return (
            f"Tu mayor gasto está en la categoría '{top_category}', "
            f"con un total aproximado de ${top_amount:.2f}. "
            f"Te recomiendo revisar ese rubro y establecer un presupuesto mensual."
        )

    if "balance" in message or "saldo" in message:
        return (
            f"Tu balance actual es de ${balance:.2f}. "
            f"Ingresos: ${income:.2f}. "
            f"Gastos: ${expenses:.2f}."
        )

    if "ahorrar" in message or "ahorro" in message:
        if balance <= 0:
            return (
                "Actualmente tu balance no permite ahorrar con seguridad. "
                "Primero reduce gastos variables y evita gastos no esenciales."
            )

        suggested_saving = balance * 0.20

        return (
            f"Podrías intentar ahorrar aproximadamente ${suggested_saving:.2f}, "
            "equivalente al 20% de tu balance disponible. "
            "También puedes dirigir ese monto a tus metas activas."
        )

    if "presupuesto" in message or "presupuestos" in message:
        if not budgets:
            return (
                "Aún no tienes presupuestos activos. "
                "Te recomiendo crear presupuestos para Comida, Transporte, Servicios y Compras."
            )

        alerts = []

        for budget in budgets:
            category = budget.get("category", "General")
            limit = float(budget.get("monthly_limit", 0))
            spent = float(budget.get("current_spent", 0))

            progress = (spent / limit) * 100 if limit > 0 else 0

            if progress >= 100:
                alerts.append(
                    f"'{category}' ya superó su límite."
                )
            elif progress >= 80:
                alerts.append(
                    f"'{category}' está cerca del límite con {progress:.1f}% usado."
                )

        if alerts:
            return "Revisión de presupuestos: " + " ".join(alerts)

        return "Tus presupuestos están bajo control por ahora."

    if "meta" in message or "metas" in message:
        if not goals:
            return (
                "Aún no tienes metas de ahorro. "
                "Crea una meta para que pueda ayudarte a calcular cuánto debes ahorrar."
            )

        goal_messages = []

        for goal in goals:
            name = goal.get("goal_name", "Meta")
            target = float(goal.get("target_amount", 0))
            current = float(goal.get("current_amount", 0))

            progress = (current / target) * 100 if target > 0 else 0

            goal_messages.append(
                f"{name}: {progress:.1f}% completada."
            )

        return "Estado de tus metas: " + " ".join(goal_messages)

    if "puedo gastar" in message or "cuánto puedo gastar" in message:
        safe_amount = balance * 0.30 if balance > 0 else 0

        return (
            f"Con base en tu balance actual, una cantidad prudente para gastar sería aproximadamente ${safe_amount:.2f}. "
            "Te recomiendo no superar ese monto si quieres mantener estabilidad financiera."
        )

    return (
        "Soy Cash-Control AI Copilot. Puedo ayudarte a revisar tus gastos, "
        "balance, presupuestos, metas de ahorro y capacidad de gasto. "
        "Prueba preguntarme: ¿En qué gasto más?, ¿Cómo puedo ahorrar?, "
        "¿Qué presupuesto está en riesgo?"
    )