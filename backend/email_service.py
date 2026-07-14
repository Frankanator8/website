import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from dotenv import load_dotenv

load_dotenv()

def send_email():
    # Configuration
    smtp_server = "smtp.gmail.com"
    smtp_port = 587
    sender_email = "hanyangfliu@gmail.com"
    sender_password = os.getenv("GOOGLE_APP_SUPPORT_PASS")
    receiver_email = "hanyangfliu+website@gmail.com"
    
    # Message Setup
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = receiver_email
    message["Subject"] = "Automated Notification"
    
    body = "Hello, this is a test email sent from your Python script."
    message.attach(MIMEText(body, "plain"))
    
    try:
        # Connect to the server
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()  # Upgrade the connection to secure (TLS)
        
        # Login and send
        server.login(sender_email, sender_password)
        server.send_message(message)
        print("Email sent successfully!")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        
    finally:
        server.quit()

if __name__ == "__main__":
    send_email()
