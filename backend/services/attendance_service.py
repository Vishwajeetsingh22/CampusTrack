from datetime import datetime, timezone
import re
from pymongo.errors import DuplicateKeyError
from db.connection import get_db
from utils.serializers import to_object_id

DATE_REGEX = re.compile(r"^\d{4}-\d{2}-\d{2}$")
VALID_STATUSES = {"Present", "Absent", "Late"}

def validate_attendance_data(data):
    """Validates attendance input parameters."""
    errors = []

    student_id = data.get("student_id")
    if not student_id or not isinstance(student_id, str):
        errors.append("student_id is required.")

    date_str = data.get("date")
    if not date_str or not isinstance(date_str, str) or not DATE_REGEX.match(date_str.strip()):
        errors.append("date must be in YYYY-MM-DD format.")

    subject = data.get("subject")
    if not subject or not isinstance(subject, str) or len(subject.strip()) < 2:
        errors.append("subject name must be at least 2 characters.")

    status = data.get("status")
    if not status or status not in VALID_STATUSES:
        errors.append("status must be one of: 'Present', 'Absent', 'Late'.")

    return errors

def record_attendance(data):
    """
    Records an attendance entry.
    Prevents duplicate attendance records for the same student, date, and subject.
    """
    db = get_db()
    errors = validate_attendance_data(data)
    if errors:
        return None, errors, 400

    student_id = data["student_id"].strip().upper()
    date_str = data["date"].strip()
    subject = data["subject"].strip()
    status = data["status"].strip()
    remarks = data.get("remarks", "").strip() if data.get("remarks") else ""

    # Verify student exists in students collection (prevent broken references)
    student = db.students.find_one({"student_id": student_id})
    if not student:
        return None, [f"Student with ID '{student_id}' does not exist."], 404

    # Check for duplicate record
    existing = db.attendance.find_one({
        "student_id": student_id,
        "date": date_str,
        "subject": subject
    })
    if existing:
        return None, [f"Attendance for student '{student_id}' in '{subject}' on '{date_str}' already exists."], 409

    now = datetime.now(timezone.utc)
    document = {
        "student_id": student_id,
        "date": date_str,
        "subject": subject,
        "status": status,
        "remarks": remarks,
        "created_at": now,
        "updated_at": now
    }

    try:
        result = db.attendance.insert_one(document)
        document["_id"] = result.inserted_id
        document["student_name"] = student["name"]
        document["course"] = student.get("course") or student.get("department", "N/A")
        return document, None, 201

    except DuplicateKeyError:
        return None, [f"Attendance for '{student_id}' in '{subject}' on '{date_str}' already exists."], 409

def get_attendance_records(student_id=None, date=None, subject=None, status=None, limit=100, skip=0, page=None):
    """Retrieves attendance records with optional filtering, pagination, and student resolution."""
    db = get_db()
    query = {}
    if student_id:
        query["student_id"] = student_id.strip().upper()
    if date:
        query["date"] = date.strip()
    if subject:
        query["subject"] = {"$regex": re.escape(subject.strip()), "$options": "i"}
    if status and status in VALID_STATUSES:
        query["status"] = status.strip()

    limit_val = max(1, min(int(limit), 500))
    if page is not None and int(page) > 0:
        skip_val = (int(page) - 1) * limit_val
    else:
        skip_val = max(0, int(skip))

    total = db.attendance.count_documents(query)

    pipeline = [
        {"$match": query},
        {"$sort": {"date": -1, "student_id": 1}},
        {"$skip": skip_val},
        {"$limit": limit_val},
        {
            "$lookup": {
                "from": "students",
                "localField": "student_id",
                "foreignField": "student_id",
                "as": "student"
            }
        },
        {
            "$addFields": {
                "student_name": {"$ifNull": [{"$arrayElemAt": ["$student.name", 0]}, "Unknown"]},
                "course": {"$ifNull": [{"$arrayElemAt": ["$student.course", 0]}, {"$arrayElemAt": ["$student.department", 0]}]},
                "semester": {"$ifNull": [{"$arrayElemAt": ["$student.semester", 0]}, 0]}
            }
        },
        {"$project": {"student": 0}}
    ]

    records = list(db.attendance.aggregate(pipeline))
    return {
        "records": records,
        "total": total,
        "count": len(records),
        "limit": limit_val,
        "skip": skip_val,
        "page": (skip_val // limit_val) + 1 if limit_val > 0 else 1
    }

def update_attendance_by_id(record_id, data):
    """Updates an attendance record by ObjectId."""
    db = get_db()
    obj_id = to_object_id(record_id)
    if not obj_id:
        return None, ["Invalid attendance record ObjectId."], 400

    existing = db.attendance.find_one({"_id": obj_id})
    if not existing:
        return None, ["Attendance record not found."], 404

    update_fields = {"updated_at": datetime.now(timezone.utc)}
    if "status" in data:
        status = data["status"].strip()
        if status not in VALID_STATUSES:
            return None, ["Status must be 'Present', 'Absent', or 'Late'."], 400
        update_fields["status"] = status

    if "remarks" in data:
        update_fields["remarks"] = str(data["remarks"]).strip()

    if "date" in data:
        new_date = str(data["date"]).strip()
        if not DATE_REGEX.match(new_date):
            return None, ["date must be in YYYY-MM-DD format."], 400
        update_fields["date"] = new_date

    if "subject" in data:
        new_subject = str(data["subject"]).strip()
        if len(new_subject) < 2:
            return None, ["subject must be at least 2 characters."], 400
        update_fields["subject"] = new_subject

    # Check for potential uniqueness conflict if date/subject changed
    check_date = update_fields.get("date", existing["date"])
    check_subject = update_fields.get("subject", existing["subject"])
    if check_date != existing["date"] or check_subject != existing["subject"]:
        conflict = db.attendance.find_one({
            "student_id": existing["student_id"],
            "date": check_date,
            "subject": check_subject,
            "_id": {"$ne": obj_id}
        })
        if conflict:
            return None, ["Another attendance record exists for this student, date, and subject."], 409

    try:
        db.attendance.update_one({"_id": obj_id}, {"$set": update_fields})
        updated = db.attendance.find_one({"_id": obj_id})
        return updated, None, 200
    except DuplicateKeyError:
        return None, ["Duplicate record error: Unique constraint violated."], 409

def delete_attendance_by_id(record_id):
    """Deletes an attendance record."""
    db = get_db()
    obj_id = to_object_id(record_id)
    if not obj_id:
        return False, "Invalid attendance record ObjectId.", 400

    result = db.attendance.delete_one({"_id": obj_id})
    if result.deleted_count == 0:
        return False, "Attendance record not found.", 404
    return True, "Attendance record deleted successfully.", 200

def get_attendance_summary(student_id=None, subject=None, date=None):
    """
    MongoDB Aggregation Pipeline for attendance summary statistics.
    Computes class-wide or student-specific statistics: total classes, counts, and attendance percentage.
    """
    db = get_db()
    match_stage = {}
    if student_id:
        match_stage["student_id"] = student_id.strip().upper()
    if subject:
        match_stage["subject"] = {"$regex": re.escape(subject.strip()), "$options": "i"}
    if date:
        match_stage["date"] = date.strip()

    # 1. Overall counts pipeline
    base_match = [{"$match": match_stage}] if match_stage else []
    overall_pipeline = base_match + [
        {
            "$group": {
                "_id": "$status",
                "count": {"$sum": 1}
            }
        }
    ]
    status_results = list(db.attendance.aggregate(overall_pipeline))
    status_counts = {item["_id"]: item["count"] for item in status_results if item.get("_id")}

    total_classes = sum(status_counts.values())
    present_count = status_counts.get("Present", 0)
    absent_count = status_counts.get("Absent", 0)
    late_count = status_counts.get("Late", 0)

    # Percentage formula: Present = 1.0, Late = 0.5
    overall_percentage = 0.0
    if total_classes > 0:
        overall_percentage = round(((present_count + (late_count * 0.5)) / total_classes) * 100.0, 2)

    # 2. Subject-wise attendance breakdown
    subject_pipeline = base_match + [
        {
            "$group": {
                "_id": "$subject",
                "total": {"$sum": 1},
                "present": {"$sum": {"$cond": [{"$eq": ["$status", "Present"]}, 1, 0]}},
                "absent": {"$sum": {"$cond": [{"$eq": ["$status", "Absent"]}, 1, 0]}},
                "late": {"$sum": {"$cond": [{"$eq": ["$status", "Late"]}, 1, 0]}}
            }
        },
        {
            "$project": {
                "subject": "$_id",
                "_id": 0,
                "total": 1,
                "present": 1,
                "absent": 1,
                "late": 1,
                "percentage": {
                    "$round": [
                        {
                            "$multiply": [
                                {
                                    "$divide": [
                                        {"$add": ["$present", {"$multiply": ["$late", 0.5]}]},
                                        "$total"
                                    ]
                                },
                                100
                            ]
                        },
                        2
                    ]
                }
            }
        },
        {"$sort": {"subject": 1}}
    ]
    subject_breakdown = list(db.attendance.aggregate(subject_pipeline))

    # 3. If student_id is specified, lookup student profile details
    student_details = None
    if student_id:
        st = db.students.find_one({"student_id": student_id.strip().upper()})
        if st:
            student_details = {
                "student_id": st["student_id"],
                "name": st["name"],
                "course": st.get("course") or st.get("department", "N/A"),
                "semester": st.get("semester", 0),
                "email": st.get("email", "")
            }

    return {
        "student_id": student_id.upper() if student_id else None,
        "student_details": student_details,
        "total_classes": total_classes,
        "present_count": present_count,
        "absent_count": absent_count,
        "late_count": late_count,
        "attendance_percentage": overall_percentage,
        "subject_breakdown": subject_breakdown
    }

def batch_record_attendance(payload):
    """Batch records attendance for a class on a given date and subject."""
    db = get_db()
    date_str = payload.get("date")
    subject = payload.get("subject")
    records = payload.get("records", [])

    if not date_str or not DATE_REGEX.match(date_str.strip()):
        return None, ["A valid date in YYYY-MM-DD format is required."], 400
    if not subject or len(subject.strip()) < 2:
        return None, ["subject must be at least 2 characters."], 400
    if not records or not isinstance(records, list):
        return None, ["records array is required and cannot be empty."], 400

    results = []
    errors = []
    now = datetime.now(timezone.utc)

    for item in records:
        student_id = item.get("student_id", "").strip().upper()
        status = item.get("status", "Present").strip()
        remarks = item.get("remarks", "").strip()

        if status not in VALID_STATUSES:
            errors.append(f"Invalid status '{status}' for student {student_id}")
            continue

        student = db.students.find_one({"student_id": student_id})
        if not student:
            errors.append(f"Student ID '{student_id}' not found.")
            continue

        db.attendance.update_one(
            {"student_id": student_id, "date": date_str, "subject": subject},
            {
                "$set": {
                    "status": status,
                    "remarks": remarks,
                    "updated_at": now
                },
                "$setOnInsert": {
                    "created_at": now
                }
            },
            upsert=True
        )
        results.append({
            "student_id": student_id,
            "student_name": student["name"],
            "status": status
        })

    return {
        "processed_count": len(results),
        "results": results,
        "errors": errors
    }, None, 200
