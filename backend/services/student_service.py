from datetime import datetime, timezone
import re
from pymongo.errors import DuplicateKeyError
from db.connection import get_db
from utils.serializers import to_object_id

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
ID_REGEX = re.compile(r"^[A-Za-z0-9_-]{3,20}$")

def validate_student_data(data, is_update=False):
    """Validates student payload before database interaction."""
    errors = []

    if not is_update:
        student_id = data.get("student_id")
        if not student_id or not isinstance(student_id, str) or not ID_REGEX.match(student_id.strip()):
            errors.append("Valid student_id (3-20 alphanumeric characters, dashes, or underscores) is required.")

    if not is_update or "name" in data:
        name = data.get("name")
        if not name or not isinstance(name, str) or len(name.strip()) < 2:
            errors.append("Student name must be at least 2 characters.")

    if not is_update or "email" in data:
        email = data.get("email")
        if not email or not isinstance(email, str) or not EMAIL_REGEX.match(email.strip()):
            errors.append("A valid email address is required.")

    if not is_update or ("course" in data or "department" in data):
        course = data.get("course") or data.get("department")
        if not course or not isinstance(course, str) or len(course.strip()) < 2:
            errors.append("Course / Department is required and must be at least 2 characters.")

    if not is_update or "semester" in data:
        semester = data.get("semester")
        try:
            sem_int = int(semester)
            if sem_int < 1 or sem_int > 8:
                errors.append("Semester must be an integer between 1 and 8.")
        except (ValueError, TypeError):
            errors.append("Semester must be a valid integer between 1 and 8.")

    if "active" in data:
        active_val = data.get("active")
        if not isinstance(active_val, bool) and str(active_val).lower() not in ["true", "false", "1", "0"]:
            errors.append("active must be a boolean (true or false).")

    return errors

def create_student(data):
    """Creates a new student document in MongoDB."""
    db = get_db()
    
    # Input validation
    errors = validate_student_data(data, is_update=False)
    if errors:
        return None, errors, 400

    student_id = data["student_id"].strip().upper()
    
    # Check if student_id already exists
    existing = db.students.find_one({"student_id": student_id})
    if existing:
        return None, [f"Student with ID '{student_id}' already exists."], 409

    course = (data.get("course") or data.get("department", "")).strip()
    active_val = data.get("active", True)
    if isinstance(active_val, str):
        active_val = active_val.lower() in ["true", "1"]
    else:
        active_val = bool(active_val)

    now = datetime.now(timezone.utc)
    document = {
        "student_id": student_id,
        "name": data["name"].strip(),
        "email": data["email"].strip().lower(),
        "course": course,
        "department": course, # Kept in sync for backwards compatibility
        "semester": int(data["semester"]),
        "active": active_val,
        "phone": data.get("phone", "").strip() if data.get("phone") else "",
        "created_at": now,
        "updated_at": now
    }

    try:
        result = db.students.insert_one(document)
        document["_id"] = result.inserted_id
        return document, None, 201
    except DuplicateKeyError:
        return None, [f"Duplicate student: ID '{student_id}' is already registered."], 409

def get_students(search=None, course=None, department=None, semester=None, active=None, limit=100, skip=0, page=None):
    """Retrieves students with optional search, filtering, and pagination."""
    db = get_db()
    query = {}

    if search:
        search_regex = {"$regex": re.escape(search.strip()), "$options": "i"}
        query["$or"] = [
            {"student_id": search_regex},
            {"name": search_regex},
            {"email": search_regex},
            {"course": search_regex},
            {"department": search_regex}
        ]

    academic_course = course or department
    if academic_course:
        query["$or"] = [
            {"course": academic_course.strip()},
            {"department": academic_course.strip()}
        ]

    if semester is not None and semester != "":
        try:
            query["semester"] = int(semester)
        except (ValueError, TypeError):
            pass

    if active is not None and active != "":
        if isinstance(active, str):
            query["active"] = active.lower() in ["true", "1"]
        else:
            query["active"] = bool(active)

    limit_val = max(1, min(int(limit), 500))
    if page is not None and int(page) > 0:
        skip_val = (int(page) - 1) * limit_val
    else:
        skip_val = max(0, int(skip))

    total = db.students.count_documents(query)
    cursor = db.students.find(query).sort("student_id", 1).skip(skip_val).limit(limit_val)
    students = list(cursor)

    return {
        "students": students,
        "total": total,
        "count": len(students),
        "limit": limit_val,
        "skip": skip_val,
        "page": (skip_val // limit_val) + 1 if limit_val > 0 else 1
    }

def get_student_by_id(identifier):
    """Finds a student by student_id or MongoDB ObjectId."""
    db = get_db()
    if not identifier:
        return None

    # Try matching as student_id string (case-insensitive search)
    student = db.students.find_one({"student_id": identifier.strip().upper()})
    if not student:
        student = db.students.find_one({"student_id": identifier.strip()})

    # If not found and identifier is valid ObjectId, search by _id
    if not student:
        obj_id = to_object_id(identifier)
        if obj_id:
            student = db.students.find_one({"_id": obj_id})

    return student

def update_student(identifier, data):
    """Updates an existing student document."""
    db = get_db()
    student = get_student_by_id(identifier)
    if not student:
        return None, ["Student not found."], 404

    errors = validate_student_data(data, is_update=True)
    if errors:
        return None, errors, 400

    update_fields = {"updated_at": datetime.now(timezone.utc)}

    if "name" in data:
        update_fields["name"] = data["name"].strip()
    if "email" in data:
        update_fields["email"] = data["email"].strip().lower()
    if "course" in data or "department" in data:
        new_course = (data.get("course") or data.get("department")).strip()
        update_fields["course"] = new_course
        update_fields["department"] = new_course
    if "semester" in data:
        update_fields["semester"] = int(data["semester"])
    if "active" in data:
        active_val = data["active"]
        if isinstance(active_val, str):
            update_fields["active"] = active_val.lower() in ["true", "1"]
        else:
            update_fields["active"] = bool(active_val)
    if "phone" in data:
        update_fields["phone"] = data["phone"].strip() if data.get("phone") else ""

    try:
        db.students.update_one({"_id": student["_id"]}, {"$set": update_fields})
        updated_student = db.students.find_one({"_id": student["_id"]})
        return updated_student, None, 200
    except DuplicateKeyError:
        return None, ["Duplicate key error: Unique constraint violated."], 409

def delete_student(identifier):
    """Deletes student and safely cascade-deletes related attendance & marks records to prevent broken references."""
    db = get_db()
    student = get_student_by_id(identifier)
    if not student:
        return False, "Student not found.", 404

    student_id = student["student_id"]
    
    # Cascade delete attendance and marks for clean NoSQL integrity and reference safety
    att_res = db.attendance.delete_many({"student_id": student_id})
    marks_res = db.marks.delete_many({"student_id": student_id})
    db.students.delete_one({"_id": student["_id"]})

    return True, {
        "deleted_student_id": student_id,
        "cascade_deleted": {
            "attendance_records": att_res.deleted_count,
            "marks_records": marks_res.deleted_count
        }
    }, 200
