from fastapi import APIRouter, HTTPException

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

router = APIRouter()

transactions_collection = db["transactions"]


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
                str(result.inserted_id)
        })

        return {

            "message":
                "Transaction created",

            "transaction_id":
                str(result.inserted_id)
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