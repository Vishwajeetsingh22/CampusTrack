import logging
from pymongo.database import Database

logger = logging.getLogger("campustrack.schema")

STUDENTS_SCHEMA = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["student_id", "name", "email", "course", "semester", "active"],
        "properties": {
            "student_id": {
                "bsonType": "string",
                "pattern": "^[A-Za-z0-9_-]{3,20}$",
                "description": "Unique student roll number / identifier (e.g. STU1001 or CS202601) - required"
            },
            "name": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 100,
                "description": "Full name of the student - required"
            },
            "email": {
                "bsonType": "string",
                "pattern": "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$",
                "description": "Valid email address - required"
            },
            "course": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 100,
                "description": "Academic course or degree program (e.g. Computer Science, Information Technology) - required"
            },
            "department": {
                "bsonType": "string",
                "description": "Academic department (alias for course)"
            },
            "semester": {
                "bsonType": "int",
                "minimum": 1,
                "maximum": 8,
                "description": "Current semester number (1 to 8) - required"
            },
            "active": {
                "bsonType": "bool",
                "description": "Whether the student is actively enrolled - required"
            },
            "phone": {
                "bsonType": "string",
                "description": "Contact telephone number - optional"
            },
            "created_at": {
                "bsonType": "date",
                "description": "Timestamp of student enrollment"
            },
            "updated_at": {
                "bsonType": "date",
                "description": "Timestamp of last modification"
            }
        }
    }
}

ATTENDANCE_SCHEMA = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["student_id", "date", "subject", "status"],
        "properties": {
            "student_id": {
                "bsonType": "string",
                "description": "Student ID matching students.student_id - required"
            },
            "date": {
                "bsonType": "string",
                "pattern": "^\\d{4}-\\d{2}-\\d{2}$",
                "description": "Attendance date in ISO YYYY-MM-DD format - required"
            },
            "subject": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 100,
                "description": "Course or subject name - required"
            },
            "status": {
                "enum": ["Present", "Absent", "Late"],
                "description": "Must be one of 'Present', 'Absent', or 'Late' - required"
            },
            "remarks": {
                "bsonType": "string",
                "maxLength": 200,
                "description": "Optional notes or remarks"
            },
            "created_at": {
                "bsonType": "date",
                "description": "Timestamp of attendance entry"
            },
            "updated_at": {
                "bsonType": "date",
                "description": "Timestamp of attendance update"
            }
        }
    }
}

MARKS_SCHEMA = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["student_id", "subject", "exam", "marks_obtained", "max_marks"],
        "properties": {
            "student_id": {
                "bsonType": "string",
                "description": "Student ID matching students.student_id - required"
            },
            "subject": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 100,
                "description": "Subject name - required"
            },
            "exam": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 50,
                "description": "Exam name (e.g. Mid-Term, Final, Quiz 1) - required"
            },
            "marks_obtained": {
                "bsonType": ["double", "int", "decimal", "long"],
                "minimum": 0,
                "description": "Score obtained, must be >= 0 - required"
            },
            "max_marks": {
                "bsonType": ["double", "int", "decimal", "long"],
                "minimum": 1,
                "description": "Maximum marks possible, must be >= 1 - required"
            },
            "percentage": {
                "bsonType": ["double", "int", "decimal", "long"],
                "minimum": 0,
                "maximum": 100,
                "description": "Calculated percentage (0 to 100) - optional/computed"
            },
            "created_at": {
                "bsonType": "date",
                "description": "Timestamp when marks were recorded"
            },
            "updated_at": {
                "bsonType": "date",
                "description": "Timestamp when marks were last updated"
            }
        }
    }
}

USERS_SCHEMA = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["email", "password_hash", "role", "full_name", "is_verified"],
        "properties": {
            "email": {
                "bsonType": "string",
                "pattern": "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$",
                "description": "User email address - required and unique"
            },
            "password_hash": {
                "bsonType": "string",
                "minLength": 10,
                "description": "Secure hashed password string - required"
            },
            "role": {
                "enum": ["admin", "student"],
                "description": "User role: must be 'admin' or 'student' - required"
            },
            "full_name": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 100,
                "description": "Full name of user - required"
            },
            "student_id": {
                "bsonType": ["string", "null"],
                "description": "Associated student_id roll number (required for student role)"
            },
            "is_verified": {
                "bsonType": "bool",
                "description": "Whether user's email address has been verified - required"
            },
            "verification_token_hash": {
                "bsonType": ["string", "null"],
                "description": "SHA-256 hash of active email verification token"
            },
            "verification_token_expires": {
                "bsonType": ["date", "null"],
                "description": "Expiry timestamp for email verification token"
            },
            "reset_token_hash": {
                "bsonType": ["string", "null"],
                "description": "SHA-256 hash of password reset token"
            },
            "reset_token_expires": {
                "bsonType": ["date", "null"],
                "description": "Expiry timestamp for password reset token"
            },
            "created_at": {
                "bsonType": "date",
                "description": "User account creation timestamp"
            },
            "updated_at": {
                "bsonType": "date",
                "description": "User account last update timestamp"
            }
        }
    }
}

def setup_schema_validators(db: Database):
    """
    Applies $jsonSchema collection validators to MongoDB collections.
    Creates collections if they do not exist, or updates validators using collMod.
    """
    collections = {
        "students": STUDENTS_SCHEMA,
        "attendance": ATTENDANCE_SCHEMA,
        "marks": MARKS_SCHEMA,
        "users": USERS_SCHEMA
    }

    existing_collections = db.list_collection_names()

    for col_name, schema in collections.items():
        try:
            if col_name not in existing_collections:
                db.create_collection(
                    col_name,
                    validator=schema,
                    validationLevel="strict",
                    validationAction="error"
                )
                logger.info(f"Created collection '{col_name}' with schema validator.")
            else:
                db.command(
                    "collMod",
                    col_name,
                    validator=schema,
                    validationLevel="strict",
                    validationAction="error"
                )
                logger.info(f"Updated schema validator on existing collection '{col_name}'.")
        except Exception as e:
            logger.warning(f"Note on validator for '{col_name}': {e}")
