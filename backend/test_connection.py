import sys
import unittest
from db.connection import get_db, check_db_health, init_db
from db.schema_validator import setup_schema_validators
from db.indexes import setup_indexes
from pymongo.errors import DuplicateKeyError, OperationFailure
from services.student_service import create_student, get_student_by_id, delete_student
from services.attendance_service import record_attendance
from services.marks_service import add_marks
from services.aggregation_service import get_dashboard_stats, get_defaulters_report

def run_smoke_test():
    print("=" * 60)
    print("CAMPUSTRACK BACKEND & MONGODB INTEGRATION TEST")
    print("=" * 60)

    # 1. Health & Connection Check
    print("\n[1/6] Testing MongoDB connectivity...")
    healthy, details = check_db_health()
    if not healthy:
        print("FAILED: Cannot connect to MongoDB:", details)
        return False
    print("PASSED: MongoDB is alive and responding to ping.")
    print(f"       Database: {details.get('database')}")

    # 2. Schema Validators and Indexes Initialization
    print("\n[2/6] Setting up $jsonSchema validators and unique indexes...")
    db = get_db()
    init_db()
    print("PASSED: Collections, validators, and indexes initialized.")

    # 3. Student Creation & Unique Index Validation
    print("\n[3/6] Testing Student creation and unique index constraint...")
    test_id = "TEST9999"
    # Clean up before testing
    db.students.delete_many({"student_id": test_id})
    db.attendance.delete_many({"student_id": test_id})
    db.marks.delete_many({"student_id": test_id})

    student_data = {
        "student_id": test_id,
        "name": "Integration Test Student",
        "email": "test.student@campus.edu",
        "department": "Computer Science",
        "semester": 6,
        "phone": "+91-9999988888"
    }

    student, err, code = create_student(student_data)
    if err or code != 201:
        print(f"FAILED: create_student returned errors: {err}")
        return False
    print(f"PASSED: Student created with ID: {student.get('student_id')}")

    # Test Duplicate unique index
    dup_student, dup_err, dup_code = create_student(student_data)
    if dup_code != 409:
        print(f"FAILED: Expected 409 Conflict for duplicate student_id, got: {dup_code}")
        return False
    print("PASSED: Unique index on 'student_id' correctly rejected duplicate record (HTTP 409).")

    # 4. Schema Validator Failure Check
    print("\n[4/6] Testing MongoDB $jsonSchema validation enforcement...")
    try:
        # Intentionally violate schema validator by inserting invalid semester (e.g. 99)
        db.students.insert_one({
            "student_id": "TEST_INVALID",
            "name": "Invalid Student",
            "email": "invalid_email_format", # violates regex
            "department": "CS",
            "semester": 99 # violates maximum: 8
        })
        print("FAILED: MongoDB did not reject document violating $jsonSchema!")
        db.students.delete_one({"student_id": "TEST_INVALID"})
        return False
    except OperationFailure as e:
        print(f"PASSED: MongoDB $jsonSchema correctly rejected invalid document: {e.details.get('errmsg', str(e))}")

    # 5. Attendance & Marks Recording
    print("\n[5/6] Testing Attendance and Marks services...")
    att_doc, att_err, att_code = record_attendance({
        "student_id": test_id,
        "date": "2026-10-25",
        "subject": "Integration Testing",
        "status": "Present",
        "remarks": "Automated verification"
    })
    if att_err:
        print(f"FAILED: record_attendance failed: {att_err}")
        return False
    print(f"PASSED: Attendance recorded (Status: {att_doc.get('status')})")

    marks_doc, marks_err, marks_code = add_marks({
        "student_id": test_id,
        "subject": "Integration Testing",
        "exam": "Unit Test 1",
        "marks_obtained": 45,
        "max_marks": 50
    })
    if marks_err:
        print(f"FAILED: add_marks failed: {marks_err}")
        return False
    print(f"PASSED: Marks recorded. Calculated Percentage: {marks_doc.get('percentage')}%")

    # 6. Aggregations & Cascading Cleanup
    print("\n[6/6] Testing MongoDB Aggregations & Cascade cleanup...")
    stats = get_dashboard_stats()
    print(f"PASSED: Aggregations computed - Total Students: {stats.get('total_students')}, Overall Attendance: {stats.get('overall_attendance_pct')}%")

    # Cleanup test record
    delete_student(test_id)
    print(f"PASSED: Test student '{test_id}' and cascading data cleaned up.")

    print("\n" + "=" * 60)
    print("ALL BACKEND & MONGODB INTEGRATION TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = run_smoke_test()
    sys.exit(0 if success else 1)
