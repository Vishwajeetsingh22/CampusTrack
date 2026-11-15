import logging
import smtplib
import urllib.request
import json
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from config import Config

logger = logging.getLogger("campustrack.email")

def _build_verification_html(full_name: str, verify_url: str) -> str:
    return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Verify Your CampusTrack Account</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F0F4F8; margin: 0; padding: 24px; color: #1E293B;">
    <div style="max-width: 600px; margin: 0 auto; background: #FFFFFF; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.08); border: 1px solid #E2E8F0;">
        <div style="background: linear-gradient(135deg, #0D1B2A 0%, #1B263B 100%); padding: 32px 24px; text-align: center; color: #FFFFFF;">
            <div style="display: inline-block; background: rgba(255,255,255,0.12); padding: 12px; border-radius: 50%; margin-bottom: 12px;">
                <span style="font-size: 32px;">🎓</span>
            </div>
            <h1 style="margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px;">CampusTrack</h1>
            <p style="margin: 4px 0 0 0; font-size: 13px; color: #94A3B8; text-transform: uppercase; letter-spacing: 1.5px;">Student Attendance & Performance Portal</p>
        </div>
        
        <div style="padding: 32px 28px;">
            <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #0F172A;">Welcome, {full_name}!</h2>
            <p style="margin: 0 0 16px 0; font-size: 15px; line-height: 1.6; color: #475569;">
                Thank you for creating an account on CampusTrack. To activate your academic portal access, verify your email address by clicking the button below.
            </p>
            
            <div style="text-align: center; margin: 32px 0;">
                <a href="{verify_url}" style="display: inline-block; background: #2563EB; color: #FFFFFF; text-decoration: none; font-size: 15px; font-weight: 600; padding: 14px 32px; border-radius: 8px; box-shadow: 0 4px 12px rgba(37,99,235,0.25);">
                    Verify Email Address
                </a>
            </div>
            
            <p style="margin: 24px 0 8px 0; font-size: 13px; color: #64748B;">
                Or copy and paste this verification URL into your browser:
            </p>
            <div style="background: #F1F5F9; padding: 12px; border-radius: 6px; word-break: break-all; font-family: monospace; font-size: 12px; color: #1E293B;">
                {verify_url}
            </div>
            
            <p style="margin: 24px 0 0 0; font-size: 13px; color: #94A3B8;">
                This link will expire in 24 hours. If you did not create this account, you can safely ignore this email.
            </p>
        </div>
        
        <div style="background: #F8FAFC; border-top: 1px solid #E2E8F0; padding: 16px 24px; text-align: center; font-size: 12px; color: #94A3B8;">
            CampusTrack Academic Portal &bull; Department of Academic Computing &bull; 2026
        </div>
    </div>
</body>
</html>"""

def _build_password_reset_html(full_name: str, reset_url: str) -> str:
    return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reset Your CampusTrack Password</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F0F4F8; margin: 0; padding: 24px; color: #1E293B;">
    <div style="max-width: 600px; margin: 0 auto; background: #FFFFFF; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.08); border: 1px solid #E2E8F0;">
        <div style="background: linear-gradient(135deg, #0D1B2A 0%, #1B263B 100%); padding: 32px 24px; text-align: center; color: #FFFFFF;">
            <div style="display: inline-block; background: rgba(255,255,255,0.12); padding: 12px; border-radius: 50%; margin-bottom: 12px;">
                <span style="font-size: 32px;">🔐</span>
            </div>
            <h1 style="margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px;">CampusTrack</h1>
            <p style="margin: 4px 0 0 0; font-size: 13px; color: #94A3B8; text-transform: uppercase; letter-spacing: 1.5px;">Security & Account Recovery</p>
        </div>
        
        <div style="padding: 32px 28px;">
            <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #0F172A;">Hello {full_name},</h2>
            <p style="margin: 0 0 16px 0; font-size: 15px; line-height: 1.6; color: #475569;">
                We received a request to reset your password for your CampusTrack portal account. Click the button below to choose a new password.
            </p>
            
            <div style="text-align: center; margin: 32px 0;">
                <a href="{reset_url}" style="display: inline-block; background: #2563EB; color: #FFFFFF; text-decoration: none; font-size: 15px; font-weight: 600; padding: 14px 32px; border-radius: 8px; box-shadow: 0 4px 12px rgba(37,99,235,0.25);">
                    Reset Password
                </a>
            </div>
            
            <p style="margin: 24px 0 8px 0; font-size: 13px; color: #64748B;">
                Or copy and paste this URL into your browser:
            </p>
            <div style="background: #F1F5F9; padding: 12px; border-radius: 6px; word-break: break-all; font-family: monospace; font-size: 12px; color: #1E293B;">
                {reset_url}
            </div>
            
            <p style="margin: 24px 0 0 0; font-size: 13px; color: #94A3B8;">
                This password reset link is valid for 1 hour. If you did not request a password reset, please ignore this email; your account remains secure.
            </p>
        </div>
        
        <div style="background: #F8FAFC; border-top: 1px solid #E2E8F0; padding: 16px 24px; text-align: center; font-size: 12px; color: #94A3B8;">
            CampusTrack Security Portal &bull; 2026
        </div>
    </div>
</body>
</html>"""

def _send_smtp_email(to_email: str, subject: str, html_body: str) -> bool:
    """Delivers email through configured SMTP server."""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = Config.MAIL_DEFAULT_SENDER
    msg["To"] = to_email

    part = MIMEText(html_body, "html")
    msg.attach(part)

    try:
        server = smtplib.SMTP(Config.MAIL_SERVER, Config.MAIL_PORT, timeout=10)
        if Config.MAIL_USE_TLS:
            server.starttls()
        if Config.MAIL_USERNAME and Config.MAIL_PASSWORD:
            server.login(Config.MAIL_USERNAME, Config.MAIL_PASSWORD)
        server.sendmail(Config.MAIL_DEFAULT_SENDER, [to_email], msg.as_string())
        server.quit()
        logger.info(f"Successfully sent email to {to_email} via SMTP ({Config.MAIL_SERVER}).")
        return True
    except Exception as e:
        logger.error(f"SMTP delivery to {to_email} failed: {e}")
        return False

def _send_resend_api(to_email: str, subject: str, html_body: str) -> bool:
    """Delivers email via Resend REST API."""
    try:
        url = "https://api.resend.com/emails"
        headers = {
            "Authorization": f"Bearer {Config.RESEND_API_KEY}",
            "Content-Type": "application/json"
        }
        data = {
            "from": Config.MAIL_DEFAULT_SENDER,
            "to": [to_email],
            "subject": subject,
            "html": html_body
        }
        req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=10) as response:
            if response.status in (200, 201):
                logger.info(f"Successfully sent email to {to_email} via Resend API.")
                return True
        return False
    except Exception as e:
        logger.error(f"Resend API email to {to_email} failed: {e}")
        return False

def send_verification_email(to_email: str, full_name: str, token: str) -> dict:
    """
    Sends an account verification email with a secure token link.
    Supports SMTP, Resend API, and safe development log display.
    """
    verify_url = f"{Config.FRONTEND_URL}/api/auth/verify-email/{token}"
    subject = "Verify your CampusTrack Portal Account"
    html_content = _build_verification_html(full_name, verify_url)

    # 1. Try Resend API if configured
    if Config.RESEND_API_KEY:
        if _send_resend_api(to_email, subject, html_content):
            return {"status": "sent", "channel": "resend", "verify_url": verify_url}

    # 2. Try SMTP if configured
    if Config.MAIL_SERVER and Config.MAIL_USERNAME:
        if _send_smtp_email(to_email, subject, html_content):
            return {"status": "sent", "channel": "smtp", "verify_url": verify_url}

    # 3. Development / Local demonstration fallback:
    # Print distinct verification banner in server logs so review and testing is instantaneous!
    banner = f"""
================================================================================
>>> [CampusTrack EMAIL SERVICE] VERIFICATION LINK FOR {to_email}
Name: {full_name}
Token: {token}
Action Link: {verify_url}
(Configure MAIL_SERVER & MAIL_USERNAME in .env for production SMTP delivery)
================================================================================
"""
    logger.info("Generated verification email token for %s", to_email)
    try:
        print(banner, flush=True)
    except Exception:
        pass
    return {"status": "delivered_local", "channel": "console", "verify_url": verify_url, "token": token}

def send_password_reset_email(to_email: str, full_name: str, token: str) -> dict:
    """
    Sends a password reset email with a secure token link.
    """
    reset_url = f"{Config.FRONTEND_URL}/api/auth/reset-password?token={token}"
    subject = "Reset your CampusTrack Password"
    html_content = _build_password_reset_html(full_name, reset_url)

    if Config.RESEND_API_KEY:
        if _send_resend_api(to_email, subject, html_content):
            return {"status": "sent", "channel": "resend", "reset_url": reset_url}

    if Config.MAIL_SERVER and Config.MAIL_USERNAME:
        if _send_smtp_email(to_email, subject, html_content):
            return {"status": "sent", "channel": "smtp", "reset_url": reset_url}

    banner = f"""
================================================================================
>>> [CampusTrack SECURITY] PASSWORD RESET LINK FOR {to_email}
Name: {full_name}
Token: {token}
Action Link: {reset_url}
(Configure MAIL_SERVER in .env for production SMTP delivery)
================================================================================
"""
    logger.info("Generated password reset token for %s", to_email)
    try:
        print(banner, flush=True)
    except Exception:
        pass
    return {"status": "delivered_local", "channel": "console", "reset_url": reset_url, "token": token}
