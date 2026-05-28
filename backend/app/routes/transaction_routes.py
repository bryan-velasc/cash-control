from fastapi import APIRouter, HTTPException

from bson import ObjectId

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

        if transaction.amount <= 0:

            raise HTTPException(
                status_code=400,
                detail="El monto debe ser mayor a 0"
            )

        new_transaction = {

            "user_email":
                transaction.user_email,

            "type":
                transaction.type,

            "category":
                transaction.category,

            "amount":
                float(transaction.amount),

            "description":
                transaction.description,

            "note":
                transaction.note,

            "source_mode":
                transaction.source_mode,

            "source_transaction_id":
                transaction.source_transaction_id,

            "source_transaction_name":
                transaction.source_transaction_name,

            "created_at":
                transaction.created_at
        }

        if transaction.type == "income":

            new_transaction["remaining_amount"] = float(
                transaction.amount
            )

        if (
            transaction.type == "expense"
            and transaction.source_mode == "linked_income"
            and transaction.source_transaction_id
        ):

            income_source = await transactions_collection.find_one({
                "_id": ObjectId(
                    transaction.source_transaction_id
                ),
                "user_email": transaction.user_email,
                "type": "income"
            })

            if not income_source:

                raise HTTPException(
                    status_code=404,
                    detail="Ingreso origen no encontrado"
                )

            remaining_amount = float(
                income_source.get(
                    "remaining_amount",
                    income_source.get("amount", 0)
                )
            )

            if remaining_amount < float(transaction.amount):

                raise HTTPException(
                    status_code=400,
                    detail="El ingreso seleccionado no tiene saldo suficiente"
                )

            new_remaining = (
                remaining_amount -
                float(transaction.amount)
            )

            await transactions_collection.update_one(
                {
                    "_id":
                        ObjectId(
                            transaction.source_transaction_id
                        )
                },
                {
                    "$set": {
                        "remaining_amount":
                            new_remaining
                    }
                }
            )

        result = await transactions_collection.insert_one(
            new_transaction
        )

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
                        budget.get("limit", 0)
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

        balance = await calculate_balance(
            transaction.user_email
        )

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

            "note":
                transaction.note,

            "source_mode":
                transaction.source_mode,

            "source_transaction_id":
                transaction.source_transaction_id,

            "source_transaction_name":
                transaction.source_transaction_name,

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

    except HTTPException as e:

        raise e

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/transactions/{user_email}")
async def get_transactions(
    user_email: str
):

    try:

        cursor = transactions_collection.find({
            "user_email":
                user_email
        })

        transactions = []

        async for tx in cursor:

            tx["_id"] = str(
                tx["_id"]
            )

            transactions.append(
                tx
            )

        return transactions

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/balance/{user_email}")
async def get_balance(
    user_email: str
):

    try:

        balance = await calculate_balance(
            user_email
        )

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


@router.get("/transactions/income-sources/{user_email}")
async def get_income_sources(
    user_email: str
):

    try:

        cursor = transactions_collection.find({
            "user_email":
                user_email,

            "type":
                "income"
        })

        sources = []

        async for income in cursor:

            income_id = str(
                income["_id"]
            )

            amount = float(
                income.get(
                    "amount",
                    0
                )
            )

            remaining = float(
                income.get(
                    "remaining_amount",
                    amount
                )
            )

            if remaining > 0:

                sources.append({

                    "id":
                        income_id,

                    "_id":
                        income_id,

                    "description":
                        income.get(
                            "description",
                            "Ingreso"
                        ),

                    "category":
                        income.get(
                            "category",
                            "Ingreso"
                        ),

                    "amount":
                        amount,

                    "remaining_amount":
                        remaining,

                    "created_at":
                        income.get(
                            "created_at",
                            ""
                        )
                })

        return sources

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/transactions/chart-summary/{user_email}")
async def get_chart_summary(
    user_email: str
):

    try:

        cursor = transactions_collection.find({
            "user_email":
                user_email
        })

        transactions = []

        async for tx in cursor:

            transactions.append(tx)

        income_pie_map = {}

        expense_pie_map = {}

        total_pie = []

        total_income = 0

        total_expenses = 0

        for tx in transactions:

            tx_type = tx.get(
                "type",
                ""
            )

            category = tx.get(
                "category",
                "Sin categoría"
            )

            amount = float(
                tx.get(
                    "amount",
                    0
                )
            )

            if tx_type == "income":

                total_income += amount

                income_pie_map[category] = (
                    income_pie_map.get(
                        category,
                        0
                    ) + amount
                )

                remaining = float(
                    tx.get(
                        "remaining_amount",
                        amount
                    )
                )

                total_pie.append({

                    "id":
                        str(tx["_id"]),

                    "label":
                        tx.get(
                            "description",
                            category
                        ),

                    "category":
                        category,

                    "amount":
                        amount,

                    "remaining_amount":
                        remaining,

                    "used_amount":
                        max(
                            amount - remaining,
                            0
                        )
                })

            elif tx_type == "expense":

                total_expenses += amount

                expense_pie_map[category] = (
                    expense_pie_map.get(
                        category,
                        0
                    ) + amount
                )

        income_pie = []

        for category, amount in income_pie_map.items():

            income_pie.append({
                "label":
                    category,

                "amount":
                    amount
            })

        expense_pie = []

        for category, amount in expense_pie_map.items():

            expense_pie.append({
                "label":
                    category,

                "amount":
                    amount
            })

        balance = total_income - total_expenses

        return {

            "total_income":
                total_income,

            "total_expenses":
                total_expenses,

            "total_balance":
                balance,

            "total_pie":
                total_pie,

            "income_pie":
                income_pie,

            "expense_pie":
                expense_pie,

            "comparison":
                {
                    "income":
                        total_income,

                    "expenses":
                        total_expenses,

                    "balance":
                        balance,

                    "expense_ratio":
                        (
                            (total_expenses / total_income) * 100
                            if total_income > 0
                            else 0
                        )
                }
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/financial-advice/{user_email}")
async def financial_advice(
    user_email: str
):

    try:

        cursor = transactions_collection.find({
            "user_email":
                user_email
        })

        income = 0

        expenses = 0

        async for tx in cursor:

            if tx["type"] == "income":

                income += float(
                    tx["amount"]
                )

            elif tx["type"] == "expense":

                expenses += float(
                    tx["amount"]
                )

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


async def calculate_balance(
    user_email: str
):

    cursor = transactions_collection.find({
        "user_email":
            user_email
    })

    balance = 0

    async for tx in cursor:

        amount = float(
            tx.get(
                "amount",
                0
            )
        )

        if tx.get("type") == "income":

            balance += amount

        elif tx.get("type") == "expense":

            balance -= amount

    return balance