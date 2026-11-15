"""
CampusTrack - End-to-End Live Integration Verification
Tests complete real API + MongoDB flow matching the Flutter application's operations:
1. Health verification (/api/health)
2. Create student via POST /api/students
3. Verify student document directly in MongoDB collection
4. Update student via PUT /api/students/<student_id> and verify in MongoDB
5. Mark attendance via POST /api/attendance and verify in MongoDB
6. Record exam marks via POST /api/marks and verify in MongoDB
7. Query summaries & reports (/api/dashboard, /api/reports/rankings, etc.)
8. Delete student and verify cascading deletion in MongoDB (preventing orphaned records)
"""

import sys
import json
import urllib.request
import urllib.error
from db.connection import get_db, close_db

if sys.platform.startswith("win"):
    sys.stdout.reconfigure(encoding="utf-8")

BASE_URL = "http://127.0.0.1:5000/api"

def make_request(path, method="GET", data=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    body = json.dumps(data).encode("utf-8") if data else None
    
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            status = resp.status
            content = resp.read().decode("utf-8")
            return status, json.loads(content)
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8")
        try:
            return e.code, json.loads(content)
        except Exception:
            return e.code, {"error": content}
    except Exception as e:
        return 0, {"error": str(e)}

def run_e2e_test():
    print("=" * 65)
    print("🚀 CampusTrack End-to-End Live Integration Verification")
    print("=" * 65)

    db = get_db()
    test_student_id = "STU9999"

    # Pre-cleanup in case of prior incomplete run
    db.students.delete_many({"student_id": test_student_id})
    db.attendance.delete_many({"student_id": test_student_id})
    db.marks.delete_many({"student_id": test_student_id})

    # Step 1: Health Check
    print("\n[Step 1] Checking API & Database Health...")
    status, res = make_request("/health")
    assert status == 200, f"Health check failed with {status}: {res}"
    assert res.get("healthy") is True, f"Service unhealthy: {res}"
    print(f"  ✓ API healthy, connected to MongoDB database '{res['database_details']['database']}'")

    # Step 2: Create Student (Simulating Flutter Registration Form)
    print(f"\n[Step 2] Creating student {test_student_id} via POST /api/students...")
    student_payload = {
        "student_id": test_student_id,
        "name": "Integration Tester",
        "course": "B.Tech Computer Science",
        "department": "B.Tech Computer Science",
        "semester": 6,
        "email": "integration.tester@college.edu",
        "phone": "+91 9876543299",
        "active": True
    }
    status, res = make_request("/students", method="POST", data=student_payload)
    assert status == 201, f"Failed to create student: {status} -> {res}"
    print(f"  ✓ API Response (201 Created): {res.get('message')}")

    # Step 3: Verify document presence in MongoDB Compass / PyMongo
    print(f"\n[Step 3] Verifying document directly in MongoDB collection 'students'...")
    doc = db.students.find_one({"student_id": test_student_id})
    assert doc is not None, "Student document NOT found in MongoDB!"
    assert doc["name"] == "Integration Tester"
    assert doc["email"] == "integration.tester@college.edu"
    print(f"  ✓ MongoDB Confirmed: _id={doc['_id']}, name='{doc['name']}', course='{doc['course']}'")

    # Step 4: Update Student (Simulating Flutter Edit Profile)
    print(f"\n[Step 4] Updating student profile via PUT /api/students/{test_student_id}...")
    update_payload = {
        "name": "Integration Tester (Senior)",
        "course": "B.Tech Data Science",
        "semester": 7
    }
    status, res = make_request(f"/students/{test_student_id}", method="PUT", data=update_payload)
    assert status == 200, f"Failed to update student: {status} -> {res}"
    print(f"  ✓ API Response (200 OK): {res.get('message')}")

    # Verify update in MongoDB
    doc = db.students.find_one({"student_id": test_student_id})
    assert doc["name"] == "Integration Tester (Senior)"
    assert doc["semester"] == 7
    print(f"  ✓ MongoDB Confirmed: name updated to '{doc['name']}', semester={doc['semester']}")

    # Step 5: Mark Attendance (Simulating Flutter Mark Attendance Screen)
    print(f"\n[Step 5] Marking attendance via POST /api/attendance...")
    att_payload = {
        "student_id": test_student_id,
        "date": "2026-10-25",
        "subject": "NoSQL Databases",
        "status": "Present",
        "remarks": "Live Integration Verification"
    }
    status, res = make_request("/attendance", method="POST", data=att_payload)
    assert status == 201, f"Failed to mark attendance: {status} -> {res}"
    print(f"  ✓ API Response (201 Created): {res.get('message')}")

    # Verify attendance in MongoDB
    att_doc = db.attendance.find_one({"student_id": test_student_id, "date": "2026-10-25"})
    assert att_doc is not None, "Attendance record NOT found in MongoDB!"
    assert att_doc["status"] == "Present"
    print(f"  ✓ MongoDB Confirmed: _id={att_doc['_id']}, status='{att_doc['status']}', subject='{att_doc['subject']}'")

    # Step 6: Record Examination Marks (Simulating Flutter Marks Form)
    print(f"\n[Step 6] Recording exam marks via POST /api/marks...")
    marks_payload = {
        "student_id": test_student_id,
        "subject": "NoSQL Databases",
        "exam": "Final",
        "marks_obtained": 94.5,
        "max_marks": 100.0
    }
    status, res = make_request("/marks", method="POST", data=marks_payload)
    assert status == 201, f"Failed to record marks: {status} -> {res}"
    print(f"  ✓ API Response (201 Created): {res.get('message')}")

    # Verify marks in MongoDB
    marks_doc = db.marks.find_one({"student_id": test_student_id, "exam": "Final"})
    assert marks_doc is not None, "Marks record NOT found in MongoDB!"
    assert marks_doc["marks_obtained"] == 94.5
    print(f"  ✓ MongoDB Confirmed: _id={marks_doc['_id']}, score={marks_doc['marks_obtained']}/{marks_doc['max_marks']}")

    # Step 7: Verify Aggregation Pipelines (Dashboard & Reports)
    print("\n[Step 7] Testing MongoDB Aggregation Pipelines across Dashboard & Reports...")
    status, dash = make_request("/dashboard")
    assert status == 200, f"Dashboard failed: {status}"
    dash_data = dash.get("data", {})
    print(f"  ✓ Dashboard Aggregation: Total Students={dash_data.get('total_students')}, "
          f"Avg Attendance={dash_data.get('overall_attendance_pct')}%, "
          f"Avg Marks={dash_data.get('avg_marks_pct')}%")

    status, rankings = make_request("/reports/rankings")
    assert status == 200, f"Rankings failed: {status}"
    rank_list = rankings.get("data", [])
    test_rank = next((r for r in rank_list if r.get("student_id") == test_student_id), None)
    if test_rank:
        print(f"  ✓ Rankings Aggregation Found Tester: Rank #{test_rank.get('rank')}, "
              f"Average Score={test_rank.get('avg_percentage')}%")

    # Step 8: Cascade Deletion (Simulating Student Delete from Flutter List)
    print(f"\n[Step 8] Deleting student {test_student_id} via DELETE /api/students/{test_student_id}...")
    status, res = make_request(f"/students/{test_student_id}", method="DELETE")
    assert status == 200, f"Failed to delete student: {status} -> {res}"
    print(f"  ✓ API Response (200 OK): {res.get('message')}")
    cleaned = res.get("data", {}).get("cascade_deleted", {})
    print(f"  ✓ Cascade Report: attendance records removed={cleaned.get('attendance_records')}, marks records removed={cleaned.get('marks_records')}")

    # Verify complete cleanup in MongoDB
    assert db.students.find_one({"student_id": test_student_id}) is None, "Student still in MongoDB!"
    assert db.attendance.find_one({"student_id": test_student_id}) is None, "Attendance orphan remains!"
    assert db.marks.find_one({"student_id": test_student_id}) is None, "Marks orphan remains!"
    print("  ✓ MongoDB Confirmed: Student and all dependent records cleanly deleted (0 orphans).")

    print("\n" + "=" * 65)
    print("🎉 ALL END-TO-END INTEGRATION TESTS PASSED SUCCESSFULLY! (8/8)")
    print("=" * 65)

if __name__ == "__main__":
    try:
        run_e2e_test()
    finally:
        close_db()
