ffrom fastapi import APIRouter, HTTPException

from app.database.database import db

from app.models.transaction_model import (
    TransactionCreate
)

from app.ai.financial_advisor import (
    generate_financial_advice
)

from app.services.n8n_service import (
    send_n8n_alert
)

from app.routes.notification_routes import (
    notifications_collection
)


router = APIRouter()

transactions_collection = db["transactions"]

budgets_collection = db["budgets"]


@router.post("/transactions/create")
async def create_transaction(
    transaction: TransactionCreate
):

    try:

        new_transaction = {

            "user_email":
                transaction.user_email,

            "type":
                transaction.type,

            "category":
                transaction.category,

            "amount":
                transaction.amount,

            "description":
                transaction.description,

            "created_at":
                transaction.created_at
        }

        result = await (
            transactions_collection
            .insert_one(new_transaction)
        )

        # =========================
        # ACTUALIZAR PRESUPUESTO
        # =========================

        if transaction.type == "expense":

            budget = await budgets_collection.find_one({

                "user_email":
                    transaction.user_email,

                "category":
                    transaction.category
            })

            if budget:

                current_spent = float(
                    budget.get(
                        "current_spent",
                        0
                    )
                )

                monthly_limit = float(
                    budget.get(
                        "monthly_limit",
                        0
                    )
                )

                new_spent = (
                    current_spent +
                    float(transaction.amount)
                )

                await budgets_collection.update_one(

                    {
                        "_id":
                            budget["_id"]
                    },

                    {
                        "$set": {

                            "current_spent":
                                new_spent
                        }
                    }
                )

                progress = (
                    (new_spent / monthly_limit) * 100
                    if monthly_limit > 0
                    else 0
                )

                # =========================
                # ALERTA PRESUPUESTO 80%
                # =========================

                if progress >= 80 and progress < 100:

                    await notifications_collection.insert_one({

                        "user_email":
                            transaction.user_email,

                        "title":
                            "Presupuesto cerca del límite",

                        "message":
                            f"Has usado {round(progress, 1)}% de tu presupuesto de {transaction.category}.",

                        "type":
                            "budget_warning",

                        "read":
                            False,

                        "created_at":
                            transaction.created_at
                    })

                # =========================
                # ALERTA PRESUPUESTO 100%
                # =========================

                if progress >= 100:

                    await notifications_collection.insert_one({

                        "user_email":
                            transaction.user_email,

                        "title":
                            "Presupuesto superado",

                        "message":
                            f"Has superado tu presupuesto mensual de {transaction.category}.",

                        "type":
                            "budget_exceeded",

                        "read":
                            False,

                        "created_at":
                            transaction.created_at
                    })

        # =========================
        # NOTIFICACIÓN GASTO ALTO
        # =========================

        if (
            transaction.type == "expense"
            and transaction.amount >= 1000
        ):

            await notifications_collection.insert_one({

                "user_email":
                    transaction.user_email,

                "title":
                    "Gasto alto detectado",

                "message":
                    f"Registraste un gasto de ${transaction.amount} en {transaction.category}.",

                "type":
                    "expense_alert",

                "read":
                    False,

                "created_at":
                    transaction.created_at
            })

        # =========================
        # CALCULAR BALANCE
        # =========================

        transactions_cursor = (
            transactions_collection.find({

                "user_email":
                    transaction.user_email
            })
        )

        balance = 0

        async for tx in transactions_cursor:

            if tx["type"] == "income":

                balance += tx["amount"]

            elif tx["type"] == "expense":

                balance -= tx["amount"]

        # =========================
        # BALANCE NEGATIVO
        # =========================

        if balance < 0:

            await notifications_collection.insert_one({

                "user_email":
                    transaction.user_email,

                "title":
                    "Balance negativo",

                "message":
                    "Tu balance actual está por debajo de cero.",

                "type":
                    "negative_balance",

                "read":
                    False,

                "created_at":
                    transaction.created_at
            })

        # =========================
        # ALERTA N8N
        # =========================

        await send_n8n_alert({

            "event":
                "transaction_created",

            "user_email":
                transaction.user_email,

            "type":
                transaction.type,

            "category":
                transaction.category,

            "amount":
                transaction.amount,

            "description":
                transaction.description,

            "created_at":
                str(transaction.created_at),

            "transaction_id":
                str(result.inserted_id),

            "balance":
                balance
        })

        return {

            "message":
                "Transaction created",

            "transaction_id":
                str(result.inserted_id),

            "balance":
                balance
        }

    except Exception as e:

        raise HTTPException(

            status_code=500,

            detail=str(e)
        )


@router.get(
    "/transactions/{user_email}"
)
async def get_transactions(
    user_email: str
):

    try:

        transactions_cursor = (
            transactions_collection.find({

                "user_email":
                    user_email
            })
        )

        transactions = []

        async for tx in transactions_cursor:

            tx["_id"] = str(tx["_id"])

            transactions.append(tx)

        return transactions

    except Exception as e:

        raise HTTPException(

            status_code=500,

            detail=str(e)
        )


@router.get(
    "/balance/{user_email}"
)
async def get_balance(
    user_email: str
):

    try:

        transactions_cursor = (
            transactions_collection.find({

                "user_email":
                    user_email
            })
        )

        balance = 0

        async for tx in transactions_cursor:

            if tx["type"] == "income":

                balance += tx["amount"]

            elif tx["type"] == "expense":

                balance -= tx["amount"]

        return {

            "user_email":
                user_email,

            "balance":
                balance
        }

    except Exception as e:

        raise HTTPException(

            status_code=500,

            detail=str(e)
        )


@router.get(
    "/financial-advice/{user_email}"
)
async def financial_advice(
    user_email: str
):

    try:

        transactions_cursor = (
            transactions_collection.find({

                "user_email":
                    user_email
            })
        )

        income = 0

        expenses = 0

        async for tx in transactions_cursor:

            if tx["type"] == "income":

                income += tx["amount"]

            elif tx["type"] == "expense":

                expenses += tx["amount"]

        advice = generate_financial_advice(

            income,

            expenses
        )

        return {

            "user_email":
                user_email,

            "income":
                income,

            "expenses":
                expenses,

            "advice":
                advice
        }

    except Exception as e:

        raise HTTPException(

            status_code=500,

            detail=str(e)
        )