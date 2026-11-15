import functools
from flask import request
from utils.serializers import error_response
from services.auth_service import decode_jwt

def token_required(f):
    """
    Decorator that verifies the JWT token present in the Authorization header.
    Attaches current_user payload to Flask request context.
    """
    @functools.wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return error_response("Authorization header is missing. Bearer token required.", status_code=401)

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return error_response("Invalid Authorization header format. Expected 'Bearer <token>'.", status_code=401)

        token = parts[1]
        try:
            payload = decode_jwt(token)
            request.current_user = payload
        except ValueError as err:
            return error_response(str(err), status_code=401)
        except Exception as err:
            return error_response(f"Authentication failed: {str(err)}", status_code=401)

        return f(*args, **kwargs)
    return decorated

def require_role(*roles):
    """
    Decorator that enforces role-based access control (RBAC).
    Must be used in conjunction with or after @token_required.
    """
    def decorator(f):
        @functools.wraps(f)
        def decorated(*args, **kwargs):
            if not hasattr(request, "current_user") or not request.current_user:
                return error_response("Authentication required before role verification.", status_code=401)

            user_role = request.current_user.get("role")
            if user_role not in roles:
                return error_response(
                    f"Access forbidden. This action requires one of the following roles: {list(roles)}. Current role: '{user_role}'.",
                    status_code=403
                )
            return f(*args, **kwargs)
        return decorated
    return decorator
