import json
import unittest
from app import create_app
from db.connection import get_db

class TestCampusTrackAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = create_app()
        cls.client = cls.app.test_client()
        cls.db = get_db()

    def test_01_health_check(self):
        """Test GET /health returns 200 with healthy MongoDB status."""
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data.get("healthy"))
        self.assertTrue(data["database_details"].get("connected"))

    def test_02_students_crud(self):
        """Test complete Student lifecycle: create, get, search, update, delete."""
        test_id = "STU_TEST_01"
        self.db.students.delete_many({"student_id": test_id})

        # 1. Create student
        payload = {
            "student_id": test_id,
            "name": "Integration Tester",
            "course": "Computer Science",
            "semester": 6,
            "email": "test.integration@campus.edu",
            "active": True,
            "phone": "+91-9999911111"
        }
        res = self.client.post("/api/students", json=payload)
        self.assertEqual(res.status_code, 201)
        created = res.get_json().get("data")
        self.assertEqual(created["student_id"], test_id)
        self.assertEqual(created["course"], "Computer Science")
        self.assertTrue(created["active"])
        self.assertIn("created_at", created)
        self.assertIn("updated_at", created)

        # 2. Get single student
        res_get = self.client.get(f"/api/students/{test_id}")
        self.assertEqual(res_get.status_code, 200)
        student = res_get.get_json().get("data")
        self.assertEqual(student["email"], "test.integration@campus.edu")

        # 3. List and search students
        res_list = self.client.get("/api/students?search=Integration&active=true")
        self.assertEqual(res_list.status_code, 200)
        results = res_list.get_json()
        self.assertGreaterEqual(results.get("count", 0), 1)

        # 4. Update student
        update_payload = {"name": "Integration Tester Updated", "active": False}
        res_put = self.client.put(f"/api/students/{test_id}", json=update_payload)
        self.assertEqual(res_put.status_code, 200)
        updated = res_put.get_json().get("data")
        self.assertEqual(updated["name"], "Integration Tester Updated")
        self.assertFalse(updated["active"])

        # 5. Delete student safely
        res_del = self.client.delete(f"/api/students/{test_id}")
        self.assertEqual(res_del.status_code, 200)

        # Verify not found after delete
        res_check = self.client.get(f"/api/students/{test_id}")
        self.assertEqual(res_check.status_code, 404)

    def test_03_attendance_endpoints_and_uniqueness(self):
        """Test Attendance marking, uniqueness, summary, and updates."""
        test_sid = "STU1001"
        test_date = "2026-11-01"
        test_subject = "NoSQL Systems"

        # Cleanup any previous test run
        self.db.attendance.delete_many({
            "student_id": test_sid,
            "date": test_date,
            "subject": test_subject
        })

        # 1. Post Attendance
        payload = {
            "student_id": test_sid,
            "date": test_date,
            "subject": test_subject,
            "status": "Present",
            "remarks": "On time test"
        }
        res_post = self.client.post("/api/attendance", json=payload)
        self.assertEqual(res_post.status_code, 201)
        record = res_post.get_json().get("data")
        record_id = record["_id"]

        # 2. Prevent duplicate attendance (same student, date, subject)
        res_dup = self.client.post("/api/attendance", json=payload)
        self.assertEqual(res_dup.status_code, 409)

        # 3. List attendance with filters
        res_list = self.client.get(f"/api/attendance?student_id={test_sid}&date={test_date}")
        self.assertEqual(res_list.status_code, 200)
        list_data = res_list.get_json().get("data")
        self.assertGreaterEqual(len(list_data), 1)

        # 4. Attendance Summary
        res_sum = self.client.get(f"/api/attendance/summary?student_id={test_sid}")
        self.assertEqual(res_sum.status_code, 200)
        sum_data = res_sum.get_json().get("data")
        self.assertIn("attendance_percentage", sum_data)
        self.assertIn("subject_breakdown", sum_data)

        # 5. Update attendance
        res_put = self.client.put(f"/api/attendance/{record_id}", json={"status": "Late", "remarks": "Delayed"})
        self.assertEqual(res_put.status_code, 200)
        updated_rec = res_put.get_json().get("data")
        self.assertEqual(updated_rec["status"], "Late")

        # 6. Delete attendance
        res_del = self.client.delete(f"/api/attendance/{record_id}")
        self.assertEqual(res_del.status_code, 200)

    def test_04_marks_endpoints_and_ranges(self):
        """Test Marks recording, numeric range validation, summary, and duplicate prevention."""
        test_sid = "STU1001"
        test_sub = "Advanced Data Structures"
        test_exam = "Mid-Term Test"

        # Cleanup
        self.db.marks.delete_many({
            "student_id": test_sid,
            "subject": test_sub,
            "exam": test_exam
        })

        # 1. Invalid marks range: marks_obtained > max_marks
        invalid_payload = {
            "student_id": test_sid,
            "subject": test_sub,
            "exam": test_exam,
            "marks_obtained": 105,
            "max_marks": 100
        }
        res_inv = self.client.post("/api/marks", json=invalid_payload)
        self.assertEqual(res_inv.status_code, 400)

        # 2. Valid marks entry
        valid_payload = {
            "student_id": test_sid,
            "subject": test_sub,
            "exam": test_exam,
            "marks_obtained": 85,
            "max_marks": 100
        }
        res_post = self.client.post("/api/marks", json=valid_payload)
        self.assertEqual(res_post.status_code, 201)
        record = res_post.get_json().get("data")
        record_id = record["_id"]
        self.assertEqual(record["percentage"], 85.0)

        # 3. Duplicate prevention
        res_dup = self.client.post("/api/marks", json=valid_payload)
        self.assertEqual(res_dup.status_code, 409)

        # 4. Marks Summary
        res_sum = self.client.get(f"/api/marks/summary?student_id={test_sid}")
        self.assertEqual(res_sum.status_code, 200)
        sum_data = res_sum.get_json().get("data")
        self.assertIn("avg_percentage", sum_data)
        self.assertIn("subject_breakdown", sum_data)

        # 5. Update marks
        res_put = self.client.put(f"/api/marks/{record_id}", json={"marks_obtained": 90})
        self.assertEqual(res_put.status_code, 200)
        self.assertEqual(res_put.get_json().get("data")["percentage"], 90.0)

        # 6. Delete marks
        res_del = self.client.delete(f"/api/marks/{record_id}")
        self.assertEqual(res_del.status_code, 200)

    def test_05_dashboard_and_reports(self):
        """Test Dashboard metrics and all required Reports endpoints."""
        # 1. GET /api/dashboard
        res_dash = self.client.get("/api/dashboard")
        self.assertEqual(res_dash.status_code, 200)
        dash = res_dash.get_json().get("data")
        self.assertIn("total_students", dash)
        self.assertIn("overall_attendance_pct", dash)
        self.assertIn("avg_marks_pct", dash)

        # 2. GET /api/reports/attendance
        res_att = self.client.get("/api/reports/attendance")
        self.assertEqual(res_att.status_code, 200)
        att_report = res_att.get_json().get("data")
        self.assertIsInstance(att_report, list)
        if att_report:
            self.assertIn("attendance_pct", att_report[0])

        # 3. GET /api/reports/performance
        res_perf = self.client.get("/api/reports/performance")
        self.assertEqual(res_perf.status_code, 200)
        perf_report = res_perf.get_json().get("data")
        self.assertIn("subjects", perf_report)
        self.assertIn("overall_summary", perf_report)

        # 4. GET /api/reports/low-attendance
        res_low = self.client.get("/api/reports/low-attendance")
        self.assertEqual(res_low.status_code, 200)
        low_att = res_low.get_json().get("data")
        self.assertIsInstance(low_att, list)
        # All items should have attendance_pct < 75.0
        for item in low_att:
            self.assertLess(item["attendance_pct"], 75.0)

        # 5. GET /api/reports/rankings
        res_rank = self.client.get("/api/reports/rankings")
        self.assertEqual(res_rank.status_code, 200)
        rankings = res_rank.get_json().get("data")
        self.assertIsInstance(rankings, list)
        if len(rankings) >= 2:
            self.assertGreaterEqual(rankings[0]["avg_percentage"], rankings[1]["avg_percentage"])
            self.assertEqual(rankings[0]["rank"], 1)

if __name__ == "__main__":
    unittest.main(verbosity=2)
