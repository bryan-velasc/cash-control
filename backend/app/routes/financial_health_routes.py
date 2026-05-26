from fastapi import APIRouter, HTTPException

from app.database.database import db

router = APIRouter()

transactions_collection = db["transactions"]
budgets_collection = db["budgets"]
goals_collection = db["Objetivos"]


@router.get("/financial-health/{user_email}")
async def financial_health(user_email: str):
    try:
        transactions = []
        budgets = []
        goals = []

        tx_cursor = transactions_collection.find({
            "user_email": user_email
        })

        async for tx in tx_cursor:
            transactions.append(tx)

        budget_cursor = budgets_collection.find({
            "user_email": user_email
        })

        async for budget in budget_cursor:
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

        savings_rate = (
            (balance / income) * 100
            if income > 0
            else 0
        )

        expense_ratio = (
            (expenses / income) * 100
            if income > 0
            else 100
        )

        budget_risk = calculate_budget_risk(budgets)

        goals_progress = calculate_goals_progress(goals)

        score = calculate_score(
            savings_rate=savings_rate,
            expense_ratio=expense_ratio,
            budget_risk=budget_risk,
            goals_progress=goals_progress,
            balance=balance,
        )

        risk_level = get_risk_level(score)

        prediction = predict_end_balance(
            income=income,
            expenses=expenses,
            balance=balance,
        )

        top_category = get_top_expense_category(
            expenses_by_category
        )

        recommendations = generate_recommendations(
            score=score,
            balance=balance,
            savings_rate=savings_rate,
            expense_ratio=expense_ratio,
            budget_risk=budget_risk,
            goals_progress=goals_progress,
            top_category=top_category,
        )

        return {
            "score": score,
            "risk_level": risk_level,
            "income": income,
            "expenses": expenses,
            "balance": balance,
            "savings_rate": savings_rate,
            "expense_ratio": expense_ratio,
            "budget_risk": budget_risk,
            "goals_progress": goals_progress,
            "predicted_end_balance": prediction,
            "top_expense_category": top_category,
            "recommendations": recommendations,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


def calculate_budget_risk(budgets):
    if not budgets:
        return 0

    risky = 0

    for budget in budgets:
        limit = float(
            budget.get(
                "monthly_limit",
                budget.get("limit", 0)
            )
        )

        spent = float(
            budget.get(
                "current_spent",
                0
            )
        )

        progress = (
            (spent / limit) * 100
            if limit > 0
            else 0
        )

        if progress >= 80:
            risky += 1

    return round(
        (risky / len(budgets)) * 100,
        2
    )


def calculate_goals_progress(goals):
    if not goals:
        return 0

    total_target = 0
    total_current = 0

    for goal in goals:
        total_target += float(
            goal.get("target_amount", 0)
        )

        total_current += float(
            goal.get("current_amount", 0)
        )

    if total_target <= 0:
        return 0

    return round(
        min((total_current / total_target) * 100, 100),
        2
    )


def calculate_score(
    savings_rate,
    expense_ratio,
    budget_risk,
    goals_progress,
    balance,
):
    score = 100

    if balance < 0:
        score -= 30

    if expense_ratio > 90:
        score -= 25
    elif expense_ratio > 75:
        score -= 15
    elif expense_ratio > 60:
        score -= 8

    if savings_rate < 5:
        score -= 20
    elif savings_rate < 15:
        score -= 10

    if budget_risk >= 70:
        score -= 20
    elif budget_risk >= 40:
        score -= 10

    if goals_progress >= 50:
        score += 5
    elif goals_progress >= 20:
        score += 2

    if score < 0:
        score = 0

    if score > 100:
        score = 100

    return round(score, 1)


def get_risk_level(score):
    if score >= 80:
        return "Excelente"

    if score >= 65:
        return "Buena"

    if score >= 45:
        return "Media"

    if score >= 25:
        return "Alta"

    return "Crítica"


def predict_end_balance(income, expenses, balance):
    if income <= 0 and expenses <= 0:
        return balance

    predicted_extra_expense = expenses * 0.15

    return round(
        balance - predicted_extra_expense,
        2
    )


def get_top_expense_category(expenses_by_category):
    if not expenses_by_category:
        return None

    category = max(
        expenses_by_category,
        key=expenses_by_category.get
    )

    return {
        "category": category,
        "amount": round(
            expenses_by_category[category],
            2
        )
    }


def generate_recommendations(
    score,
    balance,
    savings_rate,
    expense_ratio,
    budget_risk,
    goals_progress,
    top_category,
):
    recommendations = []

    if balance < 0:
        recommendations.append(
            "Tu balance está en negativo. Evita gastos no esenciales y prioriza cubrir pagos básicos."
        )

    if expense_ratio > 80:
        recommendations.append(
            "Tus gastos están consumiendo gran parte de tus ingresos. Intenta reducir gastos variables este mes."
        )

    if savings_rate < 10:
        recommendations.append(
            "Tu tasa de ahorro es baja. Intenta ahorrar al menos el 10% de tus ingresos."
        )

    if budget_risk >= 40:
        recommendations.append(
            "Uno o más presupuestos están cerca del límite. Revisa tus categorías con mayor consumo."
        )

    if top_category:
        recommendations.append(
            f"Tu categoría con mayor gasto es {top_category['category']} con ${top_category['amount']:.2f}."
        )

    if goals_progress < 20:
        recommendations.append(
            "Tus metas de ahorro tienen poco avance. Considera apartar una cantidad fija semanal."
        )

    if score >= 80:
        recommendations.append(
            "Tu salud financiera es sólida. Mantén tus hábitos actuales y aumenta gradualmente tu ahorro."
        )

    if not recommendations:
        recommendations.append(
            "Tu situación financiera es estable. Sigue monitoreando tus gastos y presupuestos."
        )

    return recommendations