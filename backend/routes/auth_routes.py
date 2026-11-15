import logging
from flask import Blueprint, request, jsonify, render_template_string
from utils.serializers import success_response, error_response
from utils.auth_middleware import token_required
from services.auth_service import (
    register_user,
    verify_email,
    resend_verification_email,
    authenticate_user,
    request_password_reset,
    reset_password
)
from db.connection import get_db

logger = logging.getLogger("campustrack.routes.auth")
auth_bp = Blueprint("auth_bp", __name__, url_prefix="/api/auth")

@auth_bp.route("/register", methods=["POST"])
def register():
    """
    Registers a new student or administrator.
    Validates input and dispatches a genuine verification email.
    """
    data = request.get_json(silent=True)
    if not data:
        return error_response("Request body must be valid JSON.", status_code=400)

    try:
        result = register_user(data)
        return success_response(
            data=result,
            message="Registration successful! Please check your email to verify your account.",
            status_code=201
        )
    except ValueError as val_err:
        return error_response(str(val_err), status_code=400)
    except Exception as e:
        logger.error(f"Error in register: {e}")
        return error_response(f"Registration failed: {str(e)}", status_code=500)

@auth_bp.route("/verify-email/<token>", methods=["GET"])
def verify_email_get(token):
    """
    Handles email verification link clicked from user's email client.
    Renders an academic confirmation landing page.
    """
    try:
        result = verify_email(token)
        user_name = result["user"].get("full_name", "Student")
        role = result["user"].get("role", "student").title()

        html_page = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>CampusTrack — Account Verified</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #F0F4F8;
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 20px;
        }}
        .card {{
            background: #FFFFFF;
            border-radius: 16px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
            max-width: 520px;
            width: 100%;
            text-align: center;
            overflow: hidden;
            border: 1px solid #E2E8F0;
        }}
        .header {{
            background: linear-gradient(135deg, #0D1B2A 0%, #1B263B 100%);
            padding: 36px 24px;
            color: #FFFFFF;
        }}
        .icon {{
            font-size: 48px;
            margin-bottom: 8px;
        }}
        .content {{
            padding: 32px 28px;
        }}
        h2 {{ color: #0F172A; margin: 0 0 12px 0; }}
        p {{ color: #475569; font-size: 15px; line-height: 1.6; margin: 0 0 24px 0; }}
        .badge {{
            display: inline-block;
            background: #ECFDF5;
            color: #065F46;
            border: 1px solid #A7F3D0;
            padding: 6px 16px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 14px;
            margin-bottom: 24px;
        }}
        .button {{
            display: inline-block;
            background: #1B263B;
            color: #FFFFFF;
            text-decoration: none;
            padding: 12px 28px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 15px;
        }}
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <div class="icon">🎓</div>
            <h1 style="margin:0; font-size: 26px;">CampusTrack</h1>
            <p style="margin:4px 0 0 0; color:#94A3B8; font-size: 13px; text-transform: uppercase;">Academic Portal Verification</p>
        </div>
        <div class="content">
            <div class="badge">✓ Email Verified Successfully</div>
            <h2>Welcome to CampusTrack, {user_name}!</h2>
            <p>Your {role} account has been verified and fully activated. You can now return to the CampusTrack application and log in.</p>
            <a href="/" class="button">Go to CampusTrack Portal</a>
        </div>
    </div>
</body>
</html>"""
        return render_template_string(html_page), 200
    except ValueError as val_err:
        error_html = f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Verification Failed</title></head>
<body style="font-family: sans-serif; background: #F8FAFC; text-align: center; padding: 50px;">
    <h2 style="color: #DC2626;">Verification Failed</h2>
    <p style="color: #475569;">{str(val_err)}</p>
    <a href="/" style="color: #2563EB;">Return to CampusTrack</a>
</body>
</html>"""
        return render_template_string(error_html), 400
    except Exception as e:
        logger.error(f"Error in verify_email_get: {e}")
        return error_response(f"Verification failed: {str(e)}", status_code=500)

@auth_bp.route("/verify-email", methods=["POST"])
def verify_email_post():
    """Validates an email verification token submitted as JSON payload."""
    data = request.get_json(silent=True) or {}
    token = data.get("token")
    if not token:
        return error_response("Token is required in request body.", status_code=400)

    try:
        result = verify_email(token)
        return success_response(data=result, message=result["message"])
    except ValueError as val_err:
        return error_response(str(val_err), status_code=400)
    except Exception as e:
        logger.error(f"Error in verify_email_post: {e}")
        return error_response(f"Verification failed: {str(e)}", status_code=500)

@auth_bp.route("/resend-verification", methods=["POST"])
def resend_verification():
    """Resends a verification email for unverified user accounts."""
    data = request.get_json(silent=True) or {}
    email = data.get("email")
    if not email:
        return error_response("Email is required.", status_code=400)

    try:
        result = resend_verification_email(email)
        return success_response(data=result, message=result["message"])
    except ValueError as val_err:
        return error_response(str(val_err), status_code=400)
    except Exception as e:
        logger.error(f"Error in resend_verification: {e}")
        return error_response(f"Resend failed: {str(e)}", status_code=500)

@auth_bp.route("/login", methods=["POST"])
def login():
    """
    Authenticates user using Email or Student ID + Password.
    Returns JWT session token and user profile.
    """
    data = request.get_json(silent=True)
    if not data:
        return error_response("Request body must be valid JSON.", status_code=400)

    identifier = data.get("identifier") or data.get("email") or data.get("student_id")
    password = data.get("password")

    if not identifier or not password:
        return error_response("Identifier (Email or Student ID) and password are required.", status_code=400)

    try:
        auth_data = authenticate_user(identifier, password)
        return success_response(
            data=auth_data,
            message=f"Welcome back, {auth_data['user']['full_name']}!"
        )
    except PermissionError as perm_err:
        return error_response(str(perm_err), status_code=403)
    except ValueError as val_err:
        return error_response(str(val_err), status_code=401)
    except Exception as e:
        logger.error(f"Error in login: {e}")
        return error_response(f"Login failed: {str(e)}", status_code=500)

@auth_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    """Dispatches password reset link to user's registered email address."""
    data = request.get_json(silent=True) or {}
    email = data.get("email")
    if not email:
        return error_response("Email address is required.", status_code=400)

    try:
        result = request_password_reset(email)
        return success_response(data=result, message=result["message"])
    except Exception as e:
        logger.error(f"Error in forgot_password: {e}")
        return error_response(f"Failed to process password reset request: {str(e)}", status_code=500)

@auth_bp.route("/reset-password", methods=["POST"])
def handle_reset_password():
    """Executes password reset with valid token."""
    data = request.get_json(silent=True) or {}
    token = data.get("token")
    new_password = data.get("new_password")

    if not token or not new_password:
        return error_response("Token and new password are required.", status_code=400)

    try:
        result = reset_password(token, new_password)
        return success_response(data=result, message=result["message"])
    except ValueError as val_err:
        return error_response(str(val_err), status_code=400)
    except Exception as e:
        logger.error(f"Error in reset_password: {e}")
        return error_response(f"Failed to reset password: {str(e)}", status_code=500)

@auth_bp.route("/me", methods=["GET"])
@token_required
def get_current_user_profile():
    """Returns profile of currently authenticated user with student details if applicable."""
    current_user_claims = request.current_user
    db = get_db()

    from bson import ObjectId
    user = db.users.find_one({"_id": ObjectId(current_user_claims["user_id"])})
    if not user:
        return error_response("User account no longer exists.", status_code=404)

    profile_data = {
        "id": str(user["_id"]),
        "email": user["email"],
        "role": user["role"],
        "full_name": user["full_name"],
        "student_id": user.get("student_id"),
        "is_verified": user.get("is_verified", False)
    }

    # If student, attach real student enrollment profile
    if user.get("role") == "student" and user.get("student_id"):
        student_doc = db.students.find_one({"student_id": user["student_id"]})
        if student_doc:
            student_doc["_id"] = str(student_doc["_id"])
            profile_data["student_profile"] = student_doc

    return success_response(data=profile_data, message="User profile retrieved successfully")
