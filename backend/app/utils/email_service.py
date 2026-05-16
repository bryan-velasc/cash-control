import smtplib

from email.mime.text import MIMEText

from email.mime.multipart import MIMEMultipart


EMAIL = "TU_CORREO@gmail.com"

PASSWORD = "TU_APP_PASSWORD"


def send_reset_email(
    to_email,
    token
):

    reset_link = (
        f"http://localhost:3000/reset-password/{token}"
    )

    subject = "Recuperación de contraseña"

    body = f"""
    Hola.

    Da clic aquí para recuperar tu contraseña:

    {reset_link}
    """

    msg = MIMEMultipart()

    msg["From"] = EMAIL

    msg["To"] = to_email

    msg["Subject"] = subject

    msg.attach(
        MIMEText(body, "plain")
    )

    server = smtplib.SMTP(
        "smtp.gmail.com",
        587
    )

    server.starttls()

    server.login(
        EMAIL,
        PASSWORD
    )

    server.send_message(msg)

    server.quit()