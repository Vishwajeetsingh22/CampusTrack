import logging
import secrets
import hashlib
from datetime import datetime, timedelta, timezone
import jwt
from werkzeug.security import generate_password_hash, check_password_hash

from config import Config
from db.connection import get_db
from services.email_service import send_verification_email, send_password_reset_email

logger = logging.getLogger("campustrack.auth")

def hash_token(raw_token: str) -> str:
    """Computes SHA-256 hash of a raw token for secure database storage."""
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

def generate_jwt(user: dict) -> str:
    """Creates a signed JSON Web Token (JWT) with user claims."""
    now = datetime.now(timezone.utc)
    expiration = now + timedelta(hours=Config.JWT_EXPIRATION_HOURS)
    
    payload = {
        "user_id": str(user["_id"]),
        "email": user["email"],
        "role": user.get("role", "student"),
        "full_name": user.get("full_name", ""),
        "student_id": user.get("student_id"),
        "iat": now,
        "exp": expiration
    }
    return jwt.encode(payload, Config.JWT_SECRET_KEY, algorithm="HS256")

def decode_jwt(token: str) -> dict:
    """Decodes and validates a JSON Web Token."""
    try:
        return jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise ValueError("Session token has expired. Please log in again.")
    except jwt.InvalidTokenError:
        raise ValueError("Invalid authentication token.")

def sanitize_user(user: dict) -> dict:
    """Removes sensitive hash fields before returning user details to client."""
    sanitized = {
        "id": str(user["_id"]),
        "email": user["email"],
        "role": user["role"],
        "full_name": user["full_name"],
        "student_id": user.get("student_id"),
        "is_verified": user.get("is_verified", False),
        "created_at": user.get("created_at").isoformat() if user.get("created_at") else None
    }
    return sanitized

def register_user(data: dict) -> dict:
    """
    Registers a new student or administrator in MongoDB and triggers real email verification.
    """
    db = get_db()

    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    full_name = data.get("full_name", "").strip()
    role = data.get("role", "student").strip().lower()
    student_id = data.get("student_id", "").strip().upper() if data.get("student_id") else None

    # Validation
    if not email or "@" not in email:
        raise ValueError("A valid email address is required.")
    if not password or len(password) < 8:
        raise ValueError("Password must be at least 8 characters long.")
    if not full_name:
        raise ValueError("Full name is required.")
    if role not in ("admin", "student"):
        raise ValueError("Role must be 'admin' or 'student'.")

    # If student role, ensure student_id is provided and valid
    if role == "student":
        if not student_id:
            raise ValueError("Student ID / Roll Number is required for student registration.")
        # Verify student exists in students collection
        existing_student = db.students.find_one({"student_id": student_id})
        if not existing_student:
            raise ValueError(f"Student ID '{student_id}' is not enrolled in the college records.")

    # Check for existing email in users collection
    existing_user = db.users.find_one({"email": email})
    if existing_user:
        raise ValueError(f"An account with email '{email}' already exists.")

    # If student role, verify student_id is not already linked to another user account
    if role == "student" and student_id:
        existing_student_user = db.users.find_one({"student_id": student_id})
        if existing_student_user:
            raise ValueError(f"An account has already been registered for Student ID '{student_id}'.")

    # Generate secure 32-byte URL-safe token for email verification
    raw_token = secrets.token_urlsafe(32)
    token_hash = hash_token(raw_token)
    token_expires = datetime.now(timezone.utc) + timedelta(hours=24)

    # Hash password securely using pbkdf2/scrypt
    password_hash = generate_password_hash(password)

    now = datetime.now(timezone.utc)
    new_user = {
        "email": email,
        "password_hash": password_hash,
        "role": role,
        "full_name": full_name,
        "student_id": student_id,
        "is_verified": False,
        "verification_token_hash": token_hash,
        "verification_token_expires": token_expires,
        "reset_token_hash": None,
        "reset_token_expires": None,
        "created_at": now,
        "updated_at": now
    }

    result = db.users.insert_one(new_user)
    new_user["_id"] = result.inserted_id

    # Send verification email
    email_delivery = send_verification_email(email, full_name, raw_token)

    return {
        "user": sanitize_user(new_user),
        "email_delivery": email_delivery,
        "verification_token": raw_token  # Returned for developer convenience in dev mode
    }

def verify_email(raw_token: str) -> dict:
    """
    Validates an email verification token and marks user as verified.
    """
    if not raw_token:
        raise ValueError("Verification token is missing.")

    db = get_db()
    token_hash = hash_token(raw_token)
    now = datetime.now(timezone.utc)

    user = db.users.find_one({"verification_token_hash": token_hash})
    if not user:
        raise ValueError("Invalid or unrecognized verification token.")

    token_expires = user.get("verification_token_expires")
    if token_expires:
        # Normalize timezone if naive
        if token_expires.tzinfo is None:
            token_expires = token_expires.replace(tzinfo=timezone.utc)
        if token_expires < now:
            raise ValueError("Verification token has expired. Please request a new verification link.")

    # Mark user as verified
    db.users.update_one(
        {"_id": user["_id"]},
        {
            "$set": {
                "is_verified": True,
                "verification_token_hash": None,
                "verification_token_expires": None,
                "updated_at": now
            }
        }
    )

    user["is_verified"] = True
    token = generate_jwt(user)

    return {
        "message": "Email verified successfully! You may now access your academic portal.",
        "user": sanitize_user(user),
        "token": token
    }

def resend_verification_email(email: str) -> dict:
    """Regenerates and resends a verification token if unverified."""
    db = get_db()
    user = db.users.find_one({"email": email.strip().lower()})
    if not user:
        raise ValueError("No account found with this email address.")
    if user.get("is_verified"):
        return {"message": "Account is already verified. Please sign in."}

    raw_token = secrets.token_urlsafe(32)
    token_hash = hash_token(raw_token)
    token_expires = datetime.now(timezone.utc) + timedelta(hours=24)

    db.users.update_one(
        {"_id": user["_id"]},
        {
            "$set": {
                "verification_token_hash": token_hash,
                "verification_token_expires": token_expires,
                "updated_at": datetime.now(timezone.utc)
            }
        }
    )

    delivery = send_verification_email(user["email"], user["full_name"], raw_token)
    return {
        "message": "A new verification email has been sent.",
        "email_delivery": delivery,
        "verification_token": raw_token
    }

def authenticate_user(identifier: str, password: str) -> dict:
    """
    Authenticates a user via Email or Student Roll Number + Password.
    Returns signed JWT and sanitized user profile.
    """
    if not identifier or not password:
        raise ValueError("Email/Student ID and password are required.")

    db = get_db()
    clean_id = identifier.strip()

    # Search by email or student_id
    user = db.users.find_one({
        "$or": [
            {"email": clean_id.lower()},
            {"student_id": clean_id.upper()}
        ]
    })

    if not user:
        raise ValueError("Invalid credentials. Please verify your Email/Student ID and password.")

    if not check_password_hash(user["password_hash"], password):
        raise ValueError("Invalid credentials. Please verify your Email/Student ID and password.")

    # Check email verification
    if not user.get("is_verified", False):
        raise PermissionError("Your email has not been verified. Please check your inbox or click 'Resend Verification'.")

    # Generate JWT
    token = generate_jwt(user)

    return {
        "token": token,
        "user": sanitize_user(user)
    }

def request_password_reset(email: str) -> dict:
    """Generates password reset token and dispatches reset email."""
    db = get_db()
    clean_email = email.strip().lower()
    user = db.users.find_one({"email": clean_email})
    if not user:
        # Security best practice: don't reveal whether user exists
        return {"message": "If an account exists with that email, a password reset link has been dispatched."}

    raw_token = secrets.token_urlsafe(32)
    token_hash = hash_token(raw_token)
    token_expires = datetime.now(timezone.utc) + timedelta(hours=1)

    db.users.update_one(
        {"_id": user["_id"]},
        {
            "$set": {
                "reset_token_hash": token_hash,
                "reset_token_expires": token_expires,
                "updated_at": datetime.now(timezone.utc)
            }
        }
    )

    delivery = send_password_reset_email(user["email"], user["full_name"], raw_token)
    return {
        "message": "Password reset instructions have been sent to your email.",
        "email_delivery": delivery,
        "reset_token": raw_token
    }

def reset_password(raw_token: str, new_password: str) -> dict:
    """Resets password using a validated reset token."""
    if not raw_token or not new_password:
        raise ValueError("Token and new password are required.")
    if len(new_password) < 8:
        raise ValueError("New password must be at least 8 characters long.")

    db = get_db()
    token_hash = hash_token(raw_token)
    now = datetime.now(timezone.utc)

    user = db.users.find_one({"reset_token_hash": token_hash})
    if not user:
        raise ValueError("Invalid or expired password reset token.")

    token_expires = user.get("reset_token_expires")
    if token_expires:
        if token_expires.tzinfo is None:
            token_expires = token_expires.replace(tzinfo=timezone.utc)
        if token_expires < now:
            raise ValueError("Password reset token has expired. Please request a new one.")

    password_hash = generate_password_hash(new_password)
    db.users.update_one(
        {"_id": user["_id"]},
        {
            "$set": {
                "password_hash": password_hash,
                "reset_token_hash": None,
                "reset_token_expires": None,
                "updated_at": now
            }
        }
    )

    return {"message": "Password has been reset successfully. You may now log in with your new password."}

def seed_default_users():
    """
    Seeds default demonstration accounts for testing and evaluation:
    - Admin: admin@campustrack.edu / Admin@1234
    - Student: alex.turner@campustrack.edu / Student@1234 (linked to STU1001)
    """
    db = get_db()
    now = datetime.now(timezone.utc)

    # 1. Admin Account
    if not db.users.find_one({"email": "admin@campustrack.edu"}):
        admin_doc = {
            "email": "admin@campustrack.edu",
            "password_hash": generate_password_hash("Admin@1234"),
            "role": "admin",
            "full_name": "Dr. Eleanor Vance (Dean)",
            "student_id": None,
            "is_verified": True,
            "verification_token_hash": None,
            "verification_token_expires": None,
            "reset_token_hash": None,
            "reset_token_expires": None,
            "created_at": now,
            "updated_at": now
        }
        db.users.insert_one(admin_doc)
        logger.info("Seeded default Administrator account: admin@campustrack.edu / Admin@1234")

    # 2. Student Account (STU1001)
    if not db.users.find_one({"email": "alex.turner@campustrack.edu"}):
        student_doc = {
            "email": "alex.turner@campustrack.edu",
            "password_hash": generate_password_hash("Student@1234"),
            "role": "student",
            "full_name": "Alex Turner",
            "student_id": "STU1001",
            "is_verified": True,
            "verification_token_hash": None,
            "verification_token_expires": None,
            "reset_token_hash": None,
            "reset_token_expires": None,
            "created_at": now,
            "updated_at": now
        }
        db.users.insert_one(student_doc)
        logger.info("Seeded default Student account: alex.turner@campustrack.edu / Student@1234 (STU1001)")
