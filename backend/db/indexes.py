import logging
from pymongo import ASCENDING, DESCENDING
from pymongo.database import Database

logger = logging.getLogger("campustrack.indexes")

def setup_indexes(db: Database):
    """
    Creates single and compound indexes on MongoDB collections.
    Enforces uniqueness constraints and query performance optimization.
    """
    try:
        # 1. Students collection indexes
        # Unique index on student_id to prevent duplicate roll numbers
        db.students.create_index(
            [("student_id", ASCENDING)],
            unique=True,
            name="idx_students_student_id_unique"
        )
        # Secondary index on course & department for academic filtering
        db.students.create_index(
            [("course", ASCENDING)],
            name="idx_students_course"
        )
        db.students.create_index(
            [("department", ASCENDING)],
            name="idx_students_department"
        )
        db.students.create_index(
            [("active", ASCENDING)],
            name="idx_students_active"
        )
        logger.info("Students indexes created successfully.")

        # 2. Attendance collection indexes
        # Compound unique index on student_id + date + subject
        # Prevents duplicate attendance entries for the same student, subject, and date
        db.attendance.create_index(
            [
                ("student_id", ASCENDING),
                ("date", ASCENDING),
                ("subject", ASCENDING)
            ],
            unique=True,
            name="idx_attendance_student_date_subject_unique"
        )
        # Secondary indexes for date range queries and status analytics
        db.attendance.create_index([("date", DESCENDING)], name="idx_attendance_date")
        db.attendance.create_index([("status", ASCENDING)], name="idx_attendance_status")
        logger.info("Attendance indexes created successfully.")

        # 3. Marks collection indexes
        # Compound unique index on student_id + subject + exam
        # Prevents duplicate marks entries for the same student, subject, and exam
        db.marks.create_index(
            [
                ("student_id", ASCENDING),
                ("subject", ASCENDING),
                ("exam", ASCENDING)
            ],
            unique=True,
            name="idx_marks_student_subject_exam_unique"
        )
        # Secondary indexes for subject-wise and exam-wise analytics
        db.marks.create_index([("subject", ASCENDING)], name="idx_marks_subject")
        db.marks.create_index([("exam", ASCENDING)], name="idx_marks_exam")
        logger.info("Marks indexes created successfully.")

        # 4. Users collection indexes (Authentication & RBAC)
        db.users.create_index([("email", ASCENDING)], unique=True, name="idx_users_email_unique")
        db.users.create_index([("student_id", ASCENDING)], sparse=True, name="idx_users_student_id")
        db.users.create_index([("role", ASCENDING)], name="idx_users_role")
        db.users.create_index([("verification_token_hash", ASCENDING)], sparse=True, name="idx_users_verification_token")
        db.users.create_index([("reset_token_hash", ASCENDING)], sparse=True, name="idx_users_reset_token")
        logger.info("Users indexes created successfully.")

        return True
    except Exception as e:
        logger.error(f"Error creating MongoDB indexes: {e}")
        raise
