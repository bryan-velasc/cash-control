def generate_financial_advice(
    income,
    expenses
):

    advice = []

    if income <= 0:

        advice.append(
            "Necesitas registrar ingresos."
        )

        return advice

    expense_ratio = expenses / income

    if expense_ratio > 0.9:

        advice.append(
            "Tus gastos son extremadamente altos."
        )

    elif expense_ratio > 0.7:

        advice.append(
            "Tus gastos superan el 70% de tus ingresos."
        )

    elif expense_ratio > 0.5:

        advice.append(
            "Buen control financiero, pero puedes ahorrar más."
        )

    else:

        advice.append(
            "Excelente control financiero."
        )

    savings = income - expenses

    if savings > income * 0.2:

        advice.append(
            "Tienes buena capacidad de ahorro."
        )

    if expenses > income:

        advice.append(
            "Estás gastando más de lo que ganas."
        )

    return advice