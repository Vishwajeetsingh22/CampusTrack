from datetime import datetime, timezone
import re
from pymongo.errors import DuplicateKeyError
from db.connection import get_db
from utils.serializers import to_object_id

def validate_marks_data(data, is_update=False):
    """Validates marks submission fields and numerical constraints."""
    errors = []

    if not is_update:
        student_id = data.get("student_id")
        if not student_id or not isinstance(student_id, str):
            errors.append("student_id is required.")

        subject = data.get("subject")
        if not subject or not isinstance(subject, str) or len(subject.strip()) < 2:
            errors.append("subject is required and must be at least 2 characters.")

        exam = data.get("exam")
        if not exam or not isinstance(exam, str) or len(exam.strip()) < 2:
            errors.append("exam name is required (e.g. Mid-Term, Final, Quiz 1).")

    # Safe numeric validation
    marks_obtained = data.get("marks_obtained")
    max_marks = data.get("max_marks")

    val_obtained = None
    val_max = None

    if marks_obtained is not None:
        try:
            val_obtained = float(marks_obtained)
            if val_obtained < 0:
                errors.append("marks_obtained must be greater than or equal to 0.")
        except (ValueError, TypeError):
            errors.append("marks_obtained must be a valid number.")

    if max_marks is not None:
        try:
            val_max = float(max_marks)
            if val_max <= 0:
                errors.append("max_marks must be greater than 0.")
        except (ValueError, TypeError):
            errors.append("max_marks must be a valid number.")

    if val_obtained is not None and val_max is not None:
        if val_obtained > val_max:
            errors.append(f"marks_obtained ({val_obtained}) cannot exceed max_marks ({val_max}).")

    return errors

def add_marks(data):
    """
    Records exam marks for a student and calculates percentage.
    Prevents duplicate marks for the same student, subject, and exam.
    """
    db = get_db()
    errors = validate_marks_data(data, is_update=False)
    if errors:
        return None, errors, 400

    student_id = data["student_id"].strip().upper()
    subject = data["subject"].strip()
    exam = data["exam"].strip()
    marks_obtained = float(data["marks_obtained"])
    max_marks = float(data["max_marks"])

    # Verify student exists in MongoDB (prevent broken references)
    student = db.students.find_one({"student_id": student_id})
    if not student:
        return None, [f"Student with ID '{student_id}' does not exist."], 404

    # Check for duplicate record
    existing = db.marks.find_one({
        "student_id": student_id,
        "subject": subject,
        "exam": exam
    })
    if existing:
        return None, [f"Marks record for student '{student_id}', subject '{subject}', exam '{exam}' already exists."], 409

    # Calculate percentage
    percentage = round((marks_obtained / max_marks) * 100.0, 2)
    now = datetime.now(timezone.utc)

    document = {
        "student_id": student_id,
        "subject": subject,
        "exam": exam,
        "marks_obtained": marks_obtained,
        "max_marks": max_marks,
        "percentage": percentage,
        "created_at": now,
        "updated_at": now
    }

    try:
        result = db.marks.insert_one(document)
        document["_id"] = result.inserted_id
        document["student_name"] = student["name"]
        document["course"] = student.get("course") or student.get("department", "N/A")
        return document, None, 201

    except DuplicateKeyError:
        return None, [f"Marks record for student '{student_id}', subject '{subject}', exam '{exam}' already exists."], 409

def get_marks_records(student_id=None, subject=None, exam=None, limit=100, skip=0, page=None):
    """Retrieves marks records with optional filtering, pagination, and student resolution."""
    db = get_db()
    query = {}
    if student_id:
        query["student_id"] = student_id.strip().upper()
    if subject:
        query["subject"] = {"$regex": re.escape(subject.strip()), "$options": "i"}
    if exam:
        query["exam"] = {"$regex": re.escape(exam.strip()), "$options": "i"}

    limit_val = max(1, min(int(limit), 500))
    if page is not None and int(page) > 0:
        skip_val = (int(page) - 1) * limit_val
    else:
        skip_val = max(0, int(skip))

    total = db.marks.count_documents(query)

    pipeline = [
        {"$match": query},
        {"$sort": {"created_at": -1, "student_id": 1}},
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

    records = list(db.marks.aggregate(pipeline))
    return {
        "records": records,
        "total": total,
        "count": len(records),
        "limit": limit_val,
        "skip": skip_val,
        "page": (skip_val // limit_val) + 1 if limit_val > 0 else 1
    }

def update_marks_by_id(record_id, data):
    """Updates marks and recalculates percentage."""
    db = get_db()
    obj_id = to_object_id(record_id)
    if not obj_id:
        return None, ["Invalid marks record ObjectId."], 400

    existing = db.marks.find_one({"_id": obj_id})
    if not existing:
        return None, ["Marks record not found."], 404

    errors = validate_marks_data(data, is_update=True)
    if errors:
        return None, errors, 400

    marks_obtained = float(data.get("marks_obtained", existing["marks_obtained"]))
    max_marks = float(data.get("max_marks", existing["max_marks"]))

    if marks_obtained > max_marks:
        return None, [f"marks_obtained ({marks_obtained}) cannot exceed max_marks ({max_marks})."], 400

    percentage = round((marks_obtained / max_marks) * 100.0, 2)
    now = datetime.now(timezone.utc)

    update_fields = {
        "marks_obtained": marks_obtained,
        "max_marks": max_marks,
        "percentage": percentage,
        "updated_at": now
    }
    if "subject" in data:
        update_fields["subject"] = data["subject"].strip()
    if "exam" in data:
        update_fields["exam"] = data["exam"].strip()

    # Check for uniqueness conflict if subject or exam changed
    new_sub = update_fields.get("subject", existing["subject"])
    new_exam = update_fields.get("exam", existing["exam"])
    if new_sub != existing["subject"] or new_exam != existing["exam"]:
        conflict = db.marks.find_one({
            "student_id": existing["student_id"],
            "subject": new_sub,
            "exam": new_exam,
            "_id": {"$ne": obj_id}
        })
        if conflict:
            return None, ["Another record already exists with this student_id, subject, and exam."], 409

    try:
        db.marks.update_one({"_id": obj_id}, {"$set": update_fields})
        updated = db.marks.find_one({"_id": obj_id})
        return updated, None, 200
    except DuplicateKeyError:
        return None, ["Another record already exists with this student_id, subject, and exam."], 409

def delete_marks_by_id(record_id):
    """Deletes an examination marks entry."""
    db = get_db()
    obj_id = to_object_id(record_id)
    if not obj_id:
        return False, "Invalid marks record ObjectId.", 400

    result = db.marks.delete_one({"_id": obj_id})
    if result.deleted_count == 0:
        return False, "Marks record not found.", 404
    return True, "Marks record deleted successfully.", 200

def get_marks_summary(student_id=None, subject=None, exam=None):
    """
    MongoDB Aggregation Pipeline for marks summary statistics.
    Computes overall marks percentage, min/max scores, and subject/exam breakdowns.
    """
    db = get_db()
    match_stage = {}
    if student_id:
        match_stage["student_id"] = student_id.strip().upper()
    if subject:
        match_stage["subject"] = {"$regex": re.escape(subject.strip()), "$options": "i"}
    if exam:
        match_stage["exam"] = {"$regex": re.escape(exam.strip()), "$options": "i"}

    base_match = [{"$match": match_stage}] if match_stage else []

    # 1. Overall stats pipeline
    overall_pipeline = base_match + [
        {
            "$group": {
                "_id": None,
                "total_records": {"$sum": 1},
                "total_obtained": {"$sum": "$marks_obtained"},
                "total_max": {"$sum": "$max_marks"},
                "avg_percentage": {"$avg": "$percentage"},
                "max_percentage": {"$max": "$percentage"},
                "min_percentage": {"$min": "$percentage"}
            }
        }
    ]
    overall_res = list(db.marks.aggregate(overall_pipeline))
    overall_stats = overall_res[0] if overall_res else {
        "total_records": 0,
        "total_obtained": 0.0,
        "total_max": 0.0,
        "avg_percentage": 0.0,
        "max_percentage": 0.0,
        "min_percentage": 0.0
    }

    # 2. Subject breakdown pipeline
    subject_pipeline = base_match + [
        {
            "$group": {
                "_id": "$subject",
                "count": {"$sum": 1},
                "avg_percentage": {"$avg": "$percentage"},
                "max_percentage": {"$max": "$percentage"},
                "min_percentage": {"$min": "$percentage"}
            }
        },
        {
            "$project": {
                "subject": "$_id",
                "_id": 0,
                "assessments_count": "$count",
                "avg_percentage": {"$round": ["$avg_percentage", 2]},
                "max_percentage": {"$round": ["$max_percentage", 2]},
                "min_percentage": {"$round": ["$min_percentage", 2]}
            }
        },
        {"$sort": {"subject": 1}}
    ]
    subject_breakdown = list(db.marks.aggregate(subject_pipeline))

    # 3. Student details lookup if student_id specified
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
        "total_records": overall_stats.get("total_records", 0),
        "total_obtained": round(overall_stats.get("total_obtained", 0.0), 2),
        "total_max": round(overall_stats.get("total_max", 0.0), 2),
        "avg_percentage": round(overall_stats.get("avg_percentage", 0.0), 2),
        "max_percentage": round(overall_stats.get("max_percentage", 0.0), 2),
        "min_percentage": round(overall_stats.get("min_percentage", 0.0), 2),
        "subject_breakdown": subject_breakdown
    }
