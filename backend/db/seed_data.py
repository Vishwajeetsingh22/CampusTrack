from datetime import datetime, timezone
import logging
from db.connection import get_db, init_db

logger = logging.getLogger("campustrack.seed")

STUDENTS_SEED = [
    {"student_id": "STU1001", "name": "Aarav Sharma", "email": "aarav.sharma@campus.edu", "course": "Computer Science", "department": "Computer Science", "semester": 6, "active": True, "phone": "+91-9876543210"},
    {"student_id": "STU1002", "name": "Priya Patel", "email": "priya.patel@campus.edu", "course": "Computer Science", "department": "Computer Science", "semester": 6, "active": True, "phone": "+91-9876543211"},
    {"student_id": "STU1003", "name": "Rohan Iyer", "email": "rohan.iyer@campus.edu", "course": "Computer Science", "department": "Computer Science", "semester": 6, "active": True, "phone": "+91-9876543212"},
    {"student_id": "STU1004", "name": "Ananya Sen", "email": "ananya.sen@campus.edu", "course": "Computer Science", "department": "Computer Science", "semester": 6, "active": True, "phone": "+91-9876543213"},
    {"student_id": "STU1005", "name": "Vikram Malhotra", "email": "vikram.m@campus.edu", "course": "Computer Science", "department": "Computer Science", "semester": 6, "active": True, "phone": "+91-9876543214"},
    {"student_id": "STU1006", "name": "Sneha Reddy", "email": "sneha.reddy@campus.edu", "course": "Information Technology", "department": "Information Technology", "semester": 6, "active": True, "phone": "+91-9876543215"},
    {"student_id": "STU1007", "name": "Karan Verma", "email": "karan.verma@campus.edu", "course": "Information Technology", "department": "Information Technology", "semester": 6, "active": True, "phone": "+91-9876543216"},
    {"student_id": "STU1008", "name": "Diya Nair", "email": "diya.nair@campus.edu", "course": "Information Technology", "department": "Information Technology", "semester": 6, "active": True, "phone": "+91-9876543217"},
    {"student_id": "STU1009", "name": "Aditya Joshi", "email": "aditya.joshi@campus.edu", "course": "Electronics", "department": "Electronics", "semester": 4, "active": True, "phone": "+91-9876543218"},
    {"student_id": "STU1010", "name": "Meera Kapoor", "email": "meera.kapoor@campus.edu", "course": "Electronics", "department": "Electronics", "semester": 4, "active": True, "phone": "+91-9876543219"},
    {"student_id": "STU1011", "name": "Rahul Deshmukh", "email": "rahul.d@campus.edu", "course": "Computer Science", "department": "Computer Science", "semester": 4, "active": True, "phone": "+91-9876543220"},
    {"student_id": "STU1012", "name": "Tanvi Gupta", "email": "tanvi.gupta@campus.edu", "course": "Information Technology", "department": "Information Technology", "semester": 4, "active": False, "phone": "+91-9876543221"},
]

SUBJECTS = ["NoSQL Databases", "Cloud Computing", "Mobile Application Dev", "Operating Systems"]
EXAMS = ["Mid-Term", "Final"]
DATES = ["2026-10-20", "2026-10-21", "2026-10-22", "2026-10-23", "2026-10-24"]

def seed_database(reset=False):
    """Populates MongoDB with realistic college student, attendance, and marks data."""
    db = get_db()
    # Ensure validators and indexes exist
    init_db()

    if reset:
        logger.info("Resetting collections before seeding...")
        db.students.delete_many({})
        db.attendance.delete_many({})
        db.marks.delete_many({})

    # 1. Insert Students
    now = datetime.now(timezone.utc)
    students_inserted = 0
    for s in STUDENTS_SEED:
        doc = s.copy()
        doc["created_at"] = now
        doc["updated_at"] = now
        res = db.students.update_one(
            {"student_id": s["student_id"]},
            {"$set": doc},
            upsert=True
        )
        if res.upserted_id or res.modified_count:
            students_inserted += 1

    # 2. Insert Attendance
    # Create deliberate pattern:
    # STU1004 and STU1007 have several 'Absent' records to test <75% Defaulter Report!
    att_inserted = 0
    for s in STUDENTS_SEED:
        sid = s["student_id"]
        # Explicit requirement: At least one student without attendance records
        # STU1012 (Tanvi Gupta) is newly admitted/on leave and has 0 attendance records
        if sid == "STU1012":
            continue

        for d_idx, d in enumerate(DATES):
            for sub in SUBJECTS[:2]:  # 2 subjects per day
                status = "Present"
                remarks = "On time"

                # Intentional defaulters
                if sid == "STU1004" and d_idx in [1, 2, 3, 4]:
                    status = "Absent"
                    remarks = "Medical absence"
                elif sid == "STU1007" and d_idx in [0, 2, 3]:
                    status = "Absent"
                    remarks = "Uninformed absence"
                elif sid == "STU1005" and d_idx == 3:
                    status = "Late"
                    remarks = "Transit delay"

                res = db.attendance.update_one(
                    {"student_id": sid, "date": d, "subject": sub},
                    {
                        "$set": {
                            "status": status,
                            "remarks": remarks,
                            "updated_at": now
                        },
                        "$setOnInsert": {
                            "student_id": sid,
                            "date": d,
                            "subject": sub,
                            "created_at": now
                        }
                    },
                    upsert=True
                )
                if res.upserted_id or res.modified_count:
                    att_inserted += 1

    # 3. Insert Marks
    marks_inserted = 0
    scores_map = {
        "STU1001": (92, 88, 95, 90), # Top Ranker
        "STU1002": (85, 82, 89, 84),
        "STU1003": (78, 75, 80, 76),
        "STU1004": (52, 48, 55, 50), # Low performer
        "STU1005": (70, 72, 68, 74),
        "STU1006": (94, 91, 93, 89), # Top Ranker
        "STU1007": (60, 58, 62, 65),
        "STU1008": (88, 86, 90, 85),
        "STU1009": (79, 81, 77, 80),
        "STU1010": (82, 84, 80, 83),
        "STU1011": (74, 76, 72, 75),
        "STU1012": (86, 88, 85, 87)
    }

    for s in STUDENTS_SEED:
        sid = s["student_id"]
        scores = scores_map.get(sid, (75, 75, 75, 75))
        for exam in EXAMS:
            for s_idx, sub in enumerate(SUBJECTS):
                # Mid-term max 50, Final max 100
                if exam == "Mid-Term":
                    max_m = 50.0
                    base_score = scores[s_idx]
                    obtained = round((base_score / 100.0) * 50.0, 1)
                else:
                    max_m = 100.0
                    obtained = float(scores[s_idx])

                pct = round((obtained / max_m) * 100.0, 2)
                res = db.marks.update_one(
                    {"student_id": sid, "subject": sub, "exam": exam},
                    {
                        "$set": {
                            "marks_obtained": obtained,
                            "max_marks": max_m,
                            "percentage": pct,
                            "updated_at": now
                        },
                        "$setOnInsert": {
                            "student_id": sid,
                            "subject": sub,
                            "exam": exam,
                            "created_at": now
                        }
                    },
                    upsert=True
                )
                if res.upserted_id or res.modified_count:
                    marks_inserted += 1

    # Ensure STU1012 has zero attendance logs to strictly meet demonstration requirements
    db.attendance.delete_many({"student_id": "STU1012"})

    total_students = db.students.count_documents({})
    total_att = db.attendance.count_documents({})
    total_marks = db.marks.count_documents({})

    logger.info(f"Seeding completed. Students: {total_students}, Attendance: {total_att}, Marks: {total_marks}")

    return {
        "status": "success",
        "students_count": total_students,
        "attendance_count": total_att,
        "marks_count": total_marks,
        "zero_attendance_student": "STU1012 (Tanvi Gupta)",
        "low_attendance_defaulters": ["STU1004 (20.0%)", "STU1007 (40.0%)"]
    }

if __name__ == "__main__":
    import sys
    if sys.platform.startswith("win"):
        sys.stdout.reconfigure(encoding="utf-8")
    reset_flag = "--reset" in sys.argv
    print("=" * 60)
    print(f"🌱 CampusTrack Database Seeding (reset={reset_flag})")
    print("=" * 60)
    if not reset_flag:
        print("[INFO] Non-destructive mode: Existing documents preserved. Upserting sample records.")
    else:
        print("[CAUTION] Destructive reset mode: Clearing collections and re-populating from scratch.")
    counts = seed_database(reset=reset_flag)
    print("\n✓ Database seeding completed successfully!")
    print(f"  • Total Students: {counts['students_count']}")
    print(f"  • Total Attendance Logs: {counts['attendance_count']}")
    print(f"  • Total Examination Marks: {counts['marks_count']}")
    print(f"  • Zero-Attendance Student (Edge Case): {counts['zero_attendance_student']}")
    print(f"  • Attendance Defaulters (<75%): {', '.join(counts['low_attendance_defaulters'])}")
    print("=" * 60)
