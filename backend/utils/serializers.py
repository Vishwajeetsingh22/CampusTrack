from datetime import datetime, date
from bson import ObjectId
from bson.errors import InvalidId
from flask import jsonify

def serialize_value(val):
    """Recursively convert BSON/MongoDB types to JSON serializable Python types."""
    if isinstance(val, ObjectId):
        return str(val)
    if isinstance(val, (datetime, date)):
        return val.isoformat()
    if isinstance(val, dict):
        return {k: serialize_value(v) for k, v in val.items()}
    if isinstance(val, list):
        return [serialize_value(item) for item in val]
    return val

def serialize_doc(doc):
    """Convert a single MongoDB document to a JSON-serializable dictionary."""
    if not doc:
        return None
    serialized = serialize_value(doc)
    # Ensure id string is also available as a convenience
    if "_id" in serialized and isinstance(serialized["_id"], str):
        serialized["id"] = serialized["_id"]
    return serialized

def serialize_docs(docs):
    """Convert an iterable of MongoDB documents to a list of JSON-serializable dicts."""
    return [serialize_doc(d) for d in docs if d is not None]

def is_valid_object_id(id_str):
    """Check if a string is a valid 24-character hexadecimal ObjectId."""
    if not id_str or not isinstance(id_str, str):
        return False
    return ObjectId.is_valid(id_str)

def to_object_id(id_str):
    """Safely convert a string to ObjectId, returning None if invalid."""
    try:
        return ObjectId(id_str)
    except (InvalidId, TypeError):
        return None

def success_response(data=None, message="Success", status_code=200, **extra):
    """Standardized API success response payload."""
    payload = {
        "success": True,
        "message": message,
        "data": serialize_value(data) if data is not None else None
    }
    if extra:
        payload.update(serialize_value(extra))
    return jsonify(payload), status_code

def error_response(message="An error occurred", status_code=400, details=None):
    """Standardized API error response payload."""
    payload = {
        "success": False,
        "error": message,
    }
    if details is not None:
        payload["details"] = serialize_value(details)
    return jsonify(payload), status_code
