"""
CampusTrack — Comprehensive Isolated Backend Test Suite
Verifies all REST API endpoints, schemas, indexes, status codes, validations,
error handling, empty datasets, division-by-zero safety, and report calculations.

Uses an isolated test database: 'campustrack_test_suite'
Real data in 'campustrack' is never touched or modified.
"""

import sys
import unittest
import json
from datetime import datetime, timezone
from bson import ObjectId

# Ensure utf-8 output in Windows console
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from config import Config
# Switch to dedicated isolated test database before importing app/db
Config.MONGO_DB_NAME = "campustrack_test_suite"

from app import create_app
from db.connection import get_client, get_db, close_db, init_db, check_db_health


class CampusTrackComprehensiveTestSuite(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Set up test application, client, and initialize clean isolated database."""
        cls.client_mongo = get_client()
        # Drop test database if leftover from previous test run
        cls.client_mongo.drop_database("campustrack_test_suite")
        
        # Initialize schema validators and unique indexes on test db
        init_db()
        cls.db = get_db()
        cls.app = create_app()
        cls.client = cls.app.test_client()

    @classmethod
    def tearDownClass(cls):
        """Drop isolated test database and restore production db name."""
        try:
            cls.client_mongo.drop_database("campustrack_test_suite")
        finally:
            close_db()
            Config.MONGO_DB_NAME = "campustrack"

    # =========================================================================
    # 1. Health Checks
    # =========================================================================
    def test_01_health_check_endpoints(self):
        """Verify /health and /api/health report MongoDB connectivity and 200 OK."""
        for path in ["/health", "/api/health"]:
            res = self.client.get(path)
            self.assertEqual(res.status_code, 200)
            data = res.get_json()
            self.assertTrue(data.get("healthy"))
            self.assertEqual(data.get("service"), "CampusTrack API")
            self.assertTrue(data["database_details"].get("connected"))
            self.assertEqual(data["database_details"].get("database"), "campustrack_test_suite")

    # =========================================================================
    # 2. Student Management CRUD & Validation Edge Cases
    # =========================================================================
    def test_02_create_student_success(self):
        """Create valid students and verify 201 Created and persisted fields."""
        payload = {
            "student_id": "STU9001",
            "name": "Aarav Sharma",
            "email": "aarav.sharma@campus.edu",
            "course": "Computer Science",
            "semester": 4,
            "active": True,
            "phone": "+91-9876543210"
        }
        res = self.client.post("/api/students", json=payload)
        self.assertEqual(res.status_code, 201)
        body = res.get_json()
        self.assertTrue(body.get("success"))
        created = body.get("data")
        self.assertEqual(created["student_id"], "STU9001")
        self.assertEqual(created["name"], "Aarav Sharma")
        self.assertEqual(created["semester"], 4)
        self.assertTrue(created["active"])
        self.assertIn("created_at", created)

    def test_03_create_student_duplicate_rejection(self):
        """Verify duplicate student_id receives HTTP 409 Conflict."""
        payload = {
            "student_id": "STU9001",
            "name": "Duplicate Aarav",
            "email": "dup.aarav@campus.edu",
            "course": "Computer Science",
            "semester": 4,
            "active": True
        }
        res = self.client.post("/api/students", json=payload)
        self.assertEqual(res.status_code, 409)
        body = res.get_json()
        self.assertFalse(body.get("success"))
        self.assertIn("already exists", body.get("error", "").lower() + str(body.get("details", "")).lower())

    def test_04_create_student_validation_failures(self):
        """Verify invalid email, semester, and missing fields return 400 Bad Request."""
        # 1. Invalid email
        bad_email = {
            "student_id": "STU9002",
            "name": "Bad Email Student",
            "email": "not-an-email",
            "course": "Computer Science",
            "semester": 3,
            "active": True
        }
        res = self.client.post("/api/students", json=bad_email)
        self.assertEqual(res.status_code, 400)

        # 2. Invalid semester (< 1 or > 8)
        bad_sem = {
            "student_id": "STU9003",
            "name": "Bad Semester Student",
            "email": "bad.sem@campus.edu",
            "course": "Computer Science",
            "semester": 10,
            "active": True
        }
        res = self.client.post("/api/students", json=bad_sem)
        self.assertEqual(res.status_code, 400)

        # 3. Missing required field (name)
        missing_name = {
            "student_id": "STU9004",
            "email": "missing.name@campus.edu",
            "course": "Computer Science",
            "semester": 2,
            "active": True
        }
        res = self.client.post("/api/students", json=missing_name)
        self.assertEqual(res.status_code, 400)

    def test_05_get_student_by_id_and_missing(self):
        """Verify student retrieval by ID and 404 for missing students."""
        # Existing student
        res_ok = self.client.get("/api/students/STU9001")
        self.assertEqual(res_ok.status_code, 200)
        self.assertEqual(res_ok.get_json()["data"]["name"], "Aarav Sharma")

        # Missing student
        res_404 = self.client.get("/api/students/NON_EXISTENT_ID")
        self.assertEqual(res_404.status_code, 404)
        self.assertFalse(res_404.get_json()["success"])

    def test_06_update_student_and_edge_cases(self):
        """Verify student update, semester validation on update, and 404 for missing student."""
        # Valid update
        update_data = {"name": "Aarav Sharma (Honors)", "semester": 5}
        res_put = self.client.put("/api/students/STU9001", json=update_data)
        self.assertEqual(res_put.status_code, 200)
        updated = res_put.get_json()["data"]
        self.assertEqual(updated["name"], "Aarav Sharma (Honors)")
        self.assertEqual(updated["semester"], 5)

        # Invalid semester update
        res_bad = self.client.put("/api/students/STU9001", json={"semester": 9})
        self.assertEqual(res_bad.status_code, 400)

        # Update non-existent student
        res_missing = self.client.put("/api/students/UNKNOWN_ID", json={"name": "Ghost"})
        self.assertEqual(res_missing.status_code, 404)

    def test_07_search_and_filter_students(self):
        """Verify student search by name and filtering by active status."""
        # Create second student
        self.client.post("/api/students", json={
            "student_id": "STU9005",
            "name": "Bhavna Patel",
            "email": "bhavna.patel@campus.edu",
            "course": "Information Technology",
            "semester": 6,
            "active": False
        })
        # Search by query
        res_search = self.client.get("/api/students?search=Bhavna")
        self.assertEqual(res_search.status_code, 200)
        data = res_search.get_json()["data"]
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["student_id"], "STU9005")

        # Filter by active
        res_active = self.client.get("/api/students?active=false")
        self.assertEqual(res_active.status_code, 200)
        data_inactive = res_active.get_json()["data"]
        self.assertTrue(any(s["student_id"] == "STU9005" for s in data_inactive))

    def test_08_delete_student_lifecycle(self):
        """Verify deleting a student safely, cascaded checks, and 404 for non-existent student."""
        # Create temporary student to delete
        temp_id = "STU_TEMP_DEL"
        self.client.post("/api/students", json={
            "student_id": temp_id,
            "name": "Temporary Deletable Student",
            "email": "temp.del@campus.edu",
            "course": "Mechanical",
            "semester": 1,
            "active": True
        })
        # Delete student
        res_del = self.client.delete(f"/api/students/{temp_id}")
        self.assertEqual(res_del.status_code, 200)
        self.assertTrue(res_del.get_json()["success"])

        # Subsequent retrieval returns 404
        res_check = self.client.get(f"/api/students/{temp_id}")
        self.assertEqual(res_check.status_code, 404)

        # Deleting non-existent student returns 404
        res_del_ghost = self.client.delete(f"/api/students/{temp_id}")
        self.assertEqual(res_del_ghost.status_code, 404)

    # =========================================================================
    # 3. Attendance Management CRUD, Uniqueness, & Edge Cases
    # =========================================================================
    def test_09_record_attendance_success(self):
        """Record valid attendance (Present, Absent, Late) and verify 201 Created."""
        payload = {
            "student_id": "STU9001",
            "date": "2026-11-01",
            "subject": "Distributed Systems",
            "status": "Present",
            "remarks": "On time"
        }
        res = self.client.post("/api/attendance", json=payload)
        self.assertEqual(res.status_code, 201)
        rec = res.get_json()["data"]
        self.assertEqual(rec["student_id"], "STU9001")
        self.assertEqual(rec["status"], "Present")
        self.assertIn("_id", rec)
        # Store for update/delete tests
        self.__class__.test_att_id = rec["_id"]

    def test_10_attendance_duplicate_prevention(self):
        """Verify duplicate attendance for same student, date, and subject returns 409."""
        dup_payload = {
            "student_id": "STU9001",
            "date": "2026-11-01",
            "subject": "Distributed Systems",
            "status": "Late"
        }
        res = self.client.post("/api/attendance", json=dup_payload)
        self.assertEqual(res.status_code, 409)
        self.assertFalse(res.get_json()["success"])

    def test_11_attendance_validation_failures(self):
        """Verify invalid attendance status and non-existent student return errors."""
        # Invalid status (e.g., 'Excused')
        bad_status = {
            "student_id": "STU9001",
            "date": "2026-11-02",
            "subject": "Distributed Systems",
            "status": "Excused"
        }
        res_status = self.client.post("/api/attendance", json=bad_status)
        self.assertEqual(res_status.status_code, 400)

        # Non-existent student
        missing_stu = {
            "student_id": "GHOST_STU",
            "date": "2026-11-02",
            "subject": "Distributed Systems",
            "status": "Present"
        }
        res_ghost = self.client.post("/api/attendance", json=missing_stu)
        self.assertEqual(res_ghost.status_code, 404)

        # Invalid date format
        bad_date = {
            "student_id": "STU9001",
            "date": "02-11-2026", # Not YYYY-MM-DD
            "subject": "Distributed Systems",
            "status": "Present"
        }
        res_date = self.client.post("/api/attendance", json=bad_date)
        self.assertEqual(res_date.status_code, 400)

    def test_12_attendance_update_and_delete(self):
        """Verify attendance update, invalid ObjectId handling, and deletion."""
        att_id = self.__class__.test_att_id

        # Update status from Present to Late
        res_put = self.client.put(f"/api/attendance/{att_id}", json={"status": "Late", "remarks": "Late 10m"})
        self.assertEqual(res_put.status_code, 200)
        self.assertEqual(res_put.get_json()["data"]["status"], "Late")

        # Invalid ObjectId format on update
        res_bad_id = self.client.put("/api/attendance/invalid_hex_id", json={"status": "Present"})
        self.assertEqual(res_bad_id.status_code, 400)

        # Non-existent valid ObjectId on update
        fake_id = str(ObjectId())
        res_ghost_id = self.client.put(f"/api/attendance/{fake_id}", json={"status": "Present"})
        self.assertEqual(res_ghost_id.status_code, 404)

        # Invalid ObjectId on delete
        res_del_bad = self.client.delete("/api/attendance/invalid_hex_id")
        self.assertEqual(res_del_bad.status_code, 400)

        # Delete valid attendance
        res_del = self.client.delete(f"/api/attendance/{att_id}")
        self.assertEqual(res_del.status_code, 200)

        # Deleting non-existent attendance returns 404
        res_del_fake = self.client.delete(f"/api/attendance/{fake_id}")
        self.assertEqual(res_del_fake.status_code, 404)

    # =========================================================================
    # 4. Marks Management CRUD, Validation & Range Checks
    # =========================================================================
    def test_13_record_marks_success(self):
        """Record valid exam marks and verify calculated percentage and 201 Created."""
        payload = {
            "student_id": "STU9001",
            "subject": "Distributed Systems",
            "exam": "Mid-Term Exam",
            "marks_obtained": 84,
            "max_marks": 100
        }
        res = self.client.post("/api/marks", json=payload)
        self.assertEqual(res.status_code, 201)
        rec = res.get_json()["data"]
        self.assertEqual(rec["student_id"], "STU9001")
        self.assertEqual(rec["percentage"], 84.0)
        self.assertIn("_id", rec)
        self.__class__.test_marks_id = rec["_id"]

    def test_14_marks_range_and_missing_student_validations(self):
        """Verify marks_obtained > max_marks, negative marks, and missing students return errors."""
        # 1. marks_obtained > max_marks (e.g. 105 / 100)
        over_max = {
            "student_id": "STU9001",
            "subject": "Distributed Systems",
            "exam": "Final Exam",
            "marks_obtained": 105,
            "max_marks": 100
        }
        res_over = self.client.post("/api/marks", json=over_max)
        self.assertEqual(res_over.status_code, 400)

        # 2. Negative marks
        neg_marks = {
            "student_id": "STU9001",
            "subject": "Distributed Systems",
            "exam": "Final Exam",
            "marks_obtained": -5,
            "max_marks": 100
        }
        res_neg = self.client.post("/api/marks", json=neg_marks)
        self.assertEqual(res_neg.status_code, 400)

        # 3. max_marks <= 0
        zero_max = {
            "student_id": "STU9001",
            "subject": "Distributed Systems",
            "exam": "Final Exam",
            "marks_obtained": 0,
            "max_marks": 0
        }
        res_zero = self.client.post("/api/marks", json=zero_max)
        self.assertEqual(res_zero.status_code, 400)

        # 4. Non-existent student
        ghost_marks = {
            "student_id": "GHOST_STU",
            "subject": "Distributed Systems",
            "exam": "Mid-Term Exam",
            "marks_obtained": 50,
            "max_marks": 100
        }
        res_ghost = self.client.post("/api/marks", json=ghost_marks)
        self.assertEqual(res_ghost.status_code, 404)

    def test_15_marks_duplicate_prevention(self):
        """Verify duplicate entry for same student, subject, and exam returns 409 Conflict."""
        dup_payload = {
            "student_id": "STU9001",
            "subject": "Distributed Systems",
            "exam": "Mid-Term Exam",
            "marks_obtained": 90,
            "max_marks": 100
        }
        res = self.client.post("/api/marks", json=dup_payload)
        self.assertEqual(res.status_code, 409)
        self.assertFalse(res.get_json()["success"])

    def test_16_marks_update_and_delete(self):
        """Verify updating marks recalculates percentage, handles invalid IDs, and deletes safely."""
        marks_id = self.__class__.test_marks_id

        # Update marks from 84 to 92
        res_put = self.client.put(f"/api/marks/{marks_id}", json={"marks_obtained": 92})
        self.assertEqual(res_put.status_code, 200)
        self.assertEqual(res_put.get_json()["data"]["percentage"], 92.0)

        # Invalid ObjectId format on update
        res_bad_id = self.client.put("/api/marks/invalid_oid", json={"marks_obtained": 80})
        self.assertEqual(res_bad_id.status_code, 400)

        # Non-existent valid ObjectId on update
        fake_id = str(ObjectId())
        res_ghost = self.client.put(f"/api/marks/{fake_id}", json={"marks_obtained": 80})
        self.assertEqual(res_ghost.status_code, 404)

        # Delete marks
        res_del = self.client.delete(f"/api/marks/{marks_id}")
        self.assertEqual(res_del.status_code, 200)

        # Deleting non-existent marks returns 404
        res_del_ghost = self.client.delete(f"/api/marks/{fake_id}")
        self.assertEqual(res_del_ghost.status_code, 404)

    # =========================================================================
    # 5. Empty Datasets & Division-by-Zero Protection
    # =========================================================================
    def test_17_empty_dataset_and_division_by_zero_safety(self):
        """Verify dashboard and all reports handle zero records and division by zero without 500 error."""
        # Ensure a student exists with 0 attendance records and 0 marks records
        zero_id = "STU_ZERO_01"
        self.db.students.delete_many({"student_id": zero_id})
        self.client.post("/api/students", json={
            "student_id": zero_id,
            "name": "Zero Records Student",
            "email": "zero.records@campus.edu",
            "course": "Computer Science",
            "semester": 1,
            "active": True
        })
        # Clear attendance and marks in test db to test pure zero state
        self.db.attendance.delete_many({})
        self.db.marks.delete_many({})

        # 1. GET /api/dashboard with empty attendance and marks
        res_dash = self.client.get("/api/dashboard")
        self.assertEqual(res_dash.status_code, 200)
        dash = res_dash.get_json()["data"]
        self.assertEqual(dash["overall_attendance_pct"], 0.0)
        self.assertEqual(dash["avg_marks_pct"], 0.0)
        self.assertGreaterEqual(dash["total_students"], 1)

        # 2. GET /api/reports/attendance with empty records
        res_att = self.client.get("/api/reports/attendance")
        self.assertEqual(res_att.status_code, 200)
        att_data = res_att.get_json()["data"]
        self.assertIsInstance(att_data, list)
        self.assertEqual(len(att_data), 0)

        # 3. GET /api/reports/performance with empty records
        res_perf = self.client.get("/api/reports/performance")
        self.assertEqual(res_perf.status_code, 200)
        perf_data = res_perf.get_json()["data"]
        self.assertEqual(perf_data["overall_summary"]["overall_avg"], 0.0)
        self.assertEqual(perf_data["overall_summary"]["total_assessments"], 0)

        # 4. GET /api/reports/low-attendance with empty records
        res_low = self.client.get("/api/reports/low-attendance")
        self.assertEqual(res_low.status_code, 200)
        low_data = res_low.get_json()["data"]
        self.assertIsInstance(low_data, list)

        # 5. GET /api/reports/rankings with empty records
        res_rank = self.client.get("/api/reports/rankings")
        self.assertEqual(res_rank.status_code, 200)
        rank_data = res_rank.get_json()["data"]
        self.assertIsInstance(rank_data, list)

        # 6. GET /api/reports/subject-attendance with empty records
        res_sub_att = self.client.get("/api/reports/subject-attendance")
        self.assertEqual(res_sub_att.status_code, 200)
        self.assertIsInstance(res_sub_att.get_json()["data"], list)

        # 7. GET /api/reports/unified with empty attendance/marks
        # Demonstrates student with zero records has 0.0 attendance and 0.0 marks with no division-by-zero
        res_uni = self.client.get(f"/api/reports/unified?student_id={zero_id}")
        self.assertEqual(res_uni.status_code, 200)
        uni_data = res_uni.get_json()["data"]
        self.assertEqual(len(uni_data), 1)
        zero_uni = uni_data[0]
        self.assertEqual(zero_uni["student_id"], zero_id)
        self.assertEqual(zero_uni["total_classes"], 0)
        self.assertEqual(zero_uni["attendance_percentage"], 0.0)
        self.assertEqual(zero_uni["total_exams"], 0)
        self.assertEqual(zero_uni["marks_percentage"], 0.0)

    # =========================================================================
    # 6. Report Calculation Verification Against Controlled Mathematical Dataset
    # =========================================================================
    def test_18_report_calculations_with_controlled_dataset(self):
        """
        Verify exact mathematical accuracy of report aggregations with known values:
        - Student 1: 3 Present, 1 Late, 0 Absent out of 4 classes.
          Attendance formula: (Present + 0.5 * Late) / Total * 100 = (3 + 0.5) / 4 * 100 = 87.5%
          Marks: 90/100, 80/100 -> Average = 85.0%
        - Student 2: 1 Present, 0 Late, 3 Absent out of 4 classes.
          Attendance formula: 1 / 4 * 100 = 25.0% (< 75.0% threshold -> defaulter)
          Marks: 50/100, 60/100 -> Average = 55.0%
        """
        # Setup controlled students
        s1 = {
            "student_id": "CALC01",
            "name": "High Performer",
            "email": "calc01@campus.edu",
            "course": "Computer Science",
            "semester": 4,
            "active": True
        }
        s2 = {
            "student_id": "CALC02",
            "name": "Low Defaulter",
            "email": "calc02@campus.edu",
            "course": "Computer Science",
            "semester": 4,
            "active": True
        }
        self.client.post("/api/students", json=s1)
        self.client.post("/api/students", json=s2)

        # S1 Attendance: 3 Present, 1 Late (4 classes)
        for i in range(1, 4):
            self.client.post("/api/attendance", json={
                "student_id": "CALC01",
                "date": f"2026-11-0{i}",
                "subject": "Mathematics",
                "status": "Present"
            })
        self.client.post("/api/attendance", json={
            "student_id": "CALC01",
            "date": "2026-11-04",
            "subject": "Mathematics",
            "status": "Late"
        })

        # S2 Attendance: 1 Present, 3 Absent (4 classes)
        self.client.post("/api/attendance", json={
            "student_id": "CALC02",
            "date": "2026-11-01",
            "subject": "Mathematics",
            "status": "Present"
        })
        for i in range(2, 5):
            self.client.post("/api/attendance", json={
                "student_id": "CALC02",
                "date": f"2026-11-0{i}",
                "subject": "Mathematics",
                "status": "Absent"
            })

        # S1 Marks: 90/100 and 80/100 (Avg = 85.0%)
        self.client.post("/api/marks", json={
            "student_id": "CALC01",
            "subject": "Mathematics",
            "exam": "Quiz 1",
            "marks_obtained": 90,
            "max_marks": 100
        })
        self.client.post("/api/marks", json={
            "student_id": "CALC01",
            "subject": "Mathematics",
            "exam": "Quiz 2",
            "marks_obtained": 80,
            "max_marks": 100
        })

        # S2 Marks: 50/100 and 60/100 (Avg = 55.0%)
        self.client.post("/api/marks", json={
            "student_id": "CALC02",
            "subject": "Mathematics",
            "exam": "Quiz 1",
            "marks_obtained": 50,
            "max_marks": 100
        })
        self.client.post("/api/marks", json={
            "student_id": "CALC02",
            "subject": "Mathematics",
            "exam": "Quiz 2",
            "marks_obtained": 60,
            "max_marks": 100
        })

        # Verify Attendance Report
        res_att = self.client.get("/api/reports/attendance")
        self.assertEqual(res_att.status_code, 200)
        att_map = {item["student_id"]: item for item in res_att.get_json()["data"]}
        
        self.assertAlmostEqual(att_map["CALC01"]["attendance_pct"], 87.5, places=1)
        self.assertEqual(att_map["CALC01"]["present_count"], 3)
        self.assertEqual(att_map["CALC01"]["late_count"], 1)

        self.assertAlmostEqual(att_map["CALC02"]["attendance_pct"], 25.0, places=1)
        self.assertEqual(att_map["CALC02"]["present_count"], 1)
        self.assertEqual(att_map["CALC02"]["absent_count"], 3)

        # Verify Low Attendance Report (threshold 75.0%)
        res_low = self.client.get("/api/reports/low-attendance?threshold=75.0")
        self.assertEqual(res_low.status_code, 200)
        low_ids = [item["student_id"] for item in res_low.get_json()["data"]]
        self.assertIn("CALC02", low_ids)
        self.assertNotIn("CALC01", low_ids)

        # Verify Rankings: CALC01 must rank higher than CALC02
        res_rank = self.client.get("/api/reports/rankings")
        self.assertEqual(res_rank.status_code, 200)
        rank_list = res_rank.get_json()["data"]
        calc01_rank = next(item for item in rank_list if item["student_id"] == "CALC01")
        calc02_rank = next(item for item in rank_list if item["student_id"] == "CALC02")
        self.assertAlmostEqual(calc01_rank["avg_percentage"], 85.0, places=1)
        self.assertAlmostEqual(calc02_rank["avg_percentage"], 55.0, places=1)
        self.assertLess(calc01_rank["rank"], calc02_rank["rank"])

        # Verify Unified Analytics (demonstrating 0 Cartesian product multiplication)
        res_uni = self.client.get("/api/reports/unified?student_id=CALC01")
        self.assertEqual(res_uni.status_code, 200)
        uni_data = res_uni.get_json()["data"]
        self.assertEqual(len(uni_data), 1)
        calc01_uni = uni_data[0]
        self.assertEqual(calc01_uni["total_classes"], 4)
        self.assertEqual(calc01_uni["total_exams"], 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
