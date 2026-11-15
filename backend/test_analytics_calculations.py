"""
CampusTrack - Verification of Analytics & Aggregation Calculations
Tests real MongoDB aggregation pipelines against a precisely known dataset:
- Student-wise attendance percentage with Late = 0.5 rule
- Subject-wise attendance summary
- Average marks and percentage scores
- Performance rankings
- Low attendance identification (< 75% threshold)
- Division-by-zero protection (0 classes, 0 marks edge cases)
- Cartesian product double-counting verification
"""

import sys
from datetime import datetime, timezone
from db.connection import get_db, close_db
from services.aggregation_service import (
    get_attendance_report,
    get_low_attendance_report,
    get_student_rankings,
    get_performance_report,
    get_subject_attendance_report,
    get_student_unified_analytics
)

if sys.platform.startswith("win"):
    sys.stdout.reconfigure(encoding="utf-8")

def run_analytics_verification():
    print("=" * 70)
    print("🧪 CAMPUS TRACK - ANALYTICS & AGGREGATION MATHEMATICAL VERIFICATION")
    print("=" * 70)

    db = get_db()
    test_prefix = "KNOWN"
    now = datetime.now(timezone.utc)

    # Clean prior test runs
    db.students.delete_many({"student_id": {"$regex": f"^{test_prefix}"}})
    db.attendance.delete_many({"student_id": {"$regex": f"^{test_prefix}"}})
    db.marks.delete_many({"student_id": {"$regex": f"^{test_prefix}"}})

    try:
        # -------------------------------------------------------------
        # STEP 1: Insert Controlled Known Test Data
        # -------------------------------------------------------------
        print("\n[Step 1] Loading Controlled Test Dataset...")

        # 3 Students:
        # KNOWN01: High performer, Good attendance
        # KNOWN02: Moderate performer, Defaulter (< 75% attendance)
        # KNOWN03: Edge Case (Zero attendance records, Zero marks records)
        students = [
            {
                "student_id": "KNOWN01",
                "name": "Alpha Scholar",
                "course": "B.Tech Computer Science",
                "department": "B.Tech Computer Science",
                "semester": 6,
                "email": "alpha@college.edu",
                "active": True,
                "created_at": now
            },
            {
                "student_id": "KNOWN02",
                "name": "Beta Defaulter",
                "course": "B.Tech Computer Science",
                "department": "B.Tech Computer Science",
                "semester": 6,
                "email": "beta@college.edu",
                "active": True,
                "created_at": now
            },
            {
                "student_id": "KNOWN03",
                "name": "Gamma Newbie",
                "course": "B.Tech Computer Science",
                "department": "B.Tech Computer Science",
                "semester": 6,
                "email": "gamma@college.edu",
                "active": True,
                "created_at": now
            }
        ]
        db.students.insert_many(students)
        print("  ✓ Created 3 test students: KNOWN01 (High), KNOWN02 (Defaulter), KNOWN03 (Edge Case)")

        # Attendance Dataset:
        # KNOWN01: 9 Present, 1 Late, 0 Absent out of 10 sessions in 'NoSQL Databases'
        # Expected %: (9 + (1 * 0.5)) / 10 * 100 = 9.5 / 10 * 100 = 95.00%
        att_known01 = []
        for i in range(1, 10):
            att_known01.append({
                "student_id": "KNOWN01",
                "date": f"2026-10-{i:02d}",
                "subject": "NoSQL Databases",
                "status": "Present",
                "created_at": now
            })
        att_known01.append({
            "student_id": "KNOWN01",
            "date": "2026-10-10",
            "subject": "NoSQL Databases",
            "status": "Late",
            "created_at": now
        })

        # KNOWN02: 6 Present, 2 Late, 2 Absent out of 10 sessions in 'NoSQL Databases'
        # Expected %: (6 + (2 * 0.5)) / 10 * 100 = 7.0 / 10 * 100 = 70.00%
        att_known02 = []
        for i in range(1, 7):
            att_known02.append({
                "student_id": "KNOWN02",
                "date": f"2026-10-{i:02d}",
                "subject": "NoSQL Databases",
                "status": "Present",
                "created_at": now
            })
        for i in range(7, 9):
            att_known02.append({
                "student_id": "KNOWN02",
                "date": f"2026-10-{i:02d}",
                "subject": "NoSQL Databases",
                "status": "Late",
                "created_at": now
            })
        for i in range(9, 11):
            att_known02.append({
                "student_id": "KNOWN02",
                "date": f"2026-10-{i:02d}",
                "subject": "NoSQL Databases",
                "status": "Absent",
                "created_at": now
            })

        db.attendance.insert_many(att_known01 + att_known02)
        print("  ✓ Created 20 attendance records across KNOWN01 and KNOWN02")

        # Marks Dataset:
        # KNOWN01:
        # - Exam 1: Mid-Term, 45.0 / 50.0 = 90.0%
        # - Exam 2: Final, 95.0 / 100.0 = 95.0%
        # Expected Avg %: (90.0 + 95.0) / 2 = 92.50%
        # KNOWN02:
        # - Exam 1: Mid-Term, 35.0 / 50.0 = 70.0%
        # - Exam 2: Final, 60.0 / 100.0 = 60.0%
        # Expected Avg %: (70.0 + 60.0) / 2 = 65.00%
        marks_docs = [
            {
                "student_id": "KNOWN01",
                "subject": "NoSQL Databases",
                "exam": "Mid-Term",
                "marks_obtained": 45.0,
                "max_marks": 50.0,
                "percentage": 90.0,
                "created_at": now
            },
            {
                "student_id": "KNOWN01",
                "subject": "NoSQL Databases",
                "exam": "Final",
                "marks_obtained": 95.0,
                "max_marks": 100.0,
                "percentage": 95.0,
                "created_at": now
            },
            {
                "student_id": "KNOWN02",
                "subject": "NoSQL Databases",
                "exam": "Mid-Term",
                "marks_obtained": 35.0,
                "max_marks": 50.0,
                "percentage": 70.0,
                "created_at": now
            },
            {
                "student_id": "KNOWN02",
                "subject": "NoSQL Databases",
                "exam": "Final",
                "marks_obtained": 60.0,
                "max_marks": 100.0,
                "percentage": 60.0,
                "created_at": now
            }
        ]
        db.marks.insert_many(marks_docs)
        print("  ✓ Created 4 marks records across KNOWN01 and KNOWN02")

        # -------------------------------------------------------------
        # STEP 2: Verify Student-Wise Attendance Percentage Calculation
        # -------------------------------------------------------------
        print("\n[Step 2] Testing Student-Wise Attendance Percentage Pipeline...")
        att_report = get_attendance_report()
        k1_att = next((r for r in att_report if r["student_id"] == "KNOWN01"), None)
        k2_att = next((r for r in att_report if r["student_id"] == "KNOWN02"), None)

        assert k1_att is not None, "KNOWN01 missing from attendance report"
        assert k2_att is not None, "KNOWN02 missing from attendance report"

        print(f"  KNOWN01 Attendance -> Classes: {k1_att['total_classes']}, Present: {k1_att['present_count']}, "
              f"Late: {k1_att['late_count']}, Absent: {k1_att['absent_count']}, Calculated: {k1_att['attendance_pct']}%")
        assert k1_att["attendance_pct"] == 95.0, f"Expected 95.0%, got {k1_att['attendance_pct']}%"
        print("  ✓ KNOWN01 Attendance % matches expected 95.00% exactly")

        print(f"  KNOWN02 Attendance -> Classes: {k2_att['total_classes']}, Present: {k2_att['present_count']}, "
              f"Late: {k2_att['late_count']}, Absent: {k2_att['absent_count']}, Calculated: {k2_att['attendance_pct']}%")
        assert k2_att["attendance_pct"] == 70.0, f"Expected 70.0%, got {k2_att['attendance_pct']}%"
        print("  ✓ KNOWN02 Attendance % matches expected 70.00% exactly")

        # -------------------------------------------------------------
        # STEP 3: Verify Low Attendance Identification (< 75% Threshold)
        # -------------------------------------------------------------
        print("\n[Step 3] Testing Low Attendance / Defaulter Pipeline (< 75% threshold)...")
        defaulters = get_low_attendance_report(threshold=75.0)
        defaulter_ids = [d["student_id"] for d in defaulters]

        assert "KNOWN02" in defaulter_ids, "KNOWN02 (70%) should be flagged as defaulter!"
        assert "KNOWN01" not in defaulter_ids, "KNOWN01 (95%) must NOT be in defaulters list!"
        k2_def = next(d for d in defaulters if d["student_id"] == "KNOWN02")
        print(f"  Defaulter Identified: {k2_def['name']} ({k2_def['student_id']}) with {k2_def['attendance_pct']}% "
              f"(Shortfall: {k2_def['shortfall']}%)")
        assert k2_def["shortfall"] == 5.0, f"Expected 5.0% shortfall, got {k2_def['shortfall']}%"
        print("  ✓ Defaulter correctly identified with 5.00% shortfall below 75% threshold")

        # -------------------------------------------------------------
        # STEP 4: Verify Student Performance Rankings
        # -------------------------------------------------------------
        print("\n[Step 4] Testing Student Rankings Pipeline...")
        rankings = get_student_rankings()
        k1_rank = next((r for r in rankings if r["student_id"] == "KNOWN01"), None)
        k2_rank = next((r for r in rankings if r["student_id"] == "KNOWN02"), None)

        assert k1_rank is not None, "KNOWN01 missing from rankings"
        assert k2_rank is not None, "KNOWN02 missing from rankings"

        print(f"  KNOWN01 Performance -> Exams: {k1_rank['total_exams']}, Avg %: {k1_rank['avg_percentage']}%, Rank: #{k1_rank['rank']}")
        assert k1_rank["avg_percentage"] == 92.5, f"Expected 92.5%, got {k1_rank['avg_percentage']}%"

        print(f"  KNOWN02 Performance -> Exams: {k2_rank['total_exams']}, Avg %: {k2_rank['avg_percentage']}%, Rank: #{k2_rank['rank']}")
        assert k2_rank["avg_percentage"] == 65.0, f"Expected 65.0%, got {k2_rank['avg_percentage']}%"

        assert k1_rank["rank"] < k2_rank["rank"], "KNOWN01 (92.5%) must rank higher than KNOWN02 (65.0%)"
        print("  ✓ Rankings sorted accurately by marks percentage in descending order")

        # -------------------------------------------------------------
        # STEP 5: Verify Subject-Wise Attendance Summary
        # -------------------------------------------------------------
        print("\n[Step 5] Testing Subject-Wise Attendance Summary Pipeline...")
        subj_att = get_subject_attendance_report()
        nosql_subj = next((s for s in subj_att if s["subject"] == "NoSQL Databases"), None)
        assert nosql_subj is not None, "NoSQL Databases missing from subject attendance summary"

        print(f"  NoSQL Databases -> Total Logs: {nosql_subj['total_records']}, Students: {nosql_subj['student_count']}, "
              f"Present: {nosql_subj['present_count']}, Late: {nosql_subj['late_count']}, "
              f"Overall Subject Attendance: {nosql_subj['attendance_percentage']}%")
        # In our known test set, KNOWN01 had 9P+1L, KNOWN02 had 6P+2L.
        # Combined present = 15, late = 3, absent = 2.
        # Total records = 20. (15 + 3*0.5) / 20 * 100 = 16.5 / 20 * 100 = 82.50% (plus any background seed data)
        assert nosql_subj["student_count"] >= 2
        print("  ✓ Subject attendance summary aggregation computed cleanly")

        # -------------------------------------------------------------
        # STEP 6: Edge Case Testing - Student with 0 Attendance & 0 Marks
        # -------------------------------------------------------------
        print("\n[Step 6] Testing Edge Cases: KNOWN03 (Zero Attendance, Zero Marks)...")
        unified = get_student_unified_analytics(student_id="KNOWN03")
        assert len(unified) == 1, "KNOWN03 must return exactly 1 document in unified analytics"
        k3 = unified[0]

        print(f"  KNOWN03 -> Total Classes: {k3['total_classes']}, Attendance %: {k3['attendance_percentage']}%, "
              f"Total Exams: {k3['total_exams']}, Marks %: {k3['marks_percentage']}%")
        assert k3["total_classes"] == 0
        assert k3["attendance_percentage"] == 0.0
        assert k3["total_exams"] == 0
        assert k3["marks_percentage"] == 0.0
        print("  ✓ Division-by-zero avoided: 0 classes / 0 exams evaluated safely to 0.00% without exceptions")

        # -------------------------------------------------------------
        # STEP 7: Cartesian Product Double-Counting Verification
        # -------------------------------------------------------------
        print("\n[Step 7] Testing Cartesian Product Double-Counting Prevention...")
        k1_unified = next((u for u in get_student_unified_analytics() if u["student_id"] == "KNOWN01"), None)
        assert k1_unified is not None, "KNOWN01 missing from unified analytics"

        # KNOWN01 has 10 attendance records and 2 marks records
        # If naive $lookup + $unwind were used, total_classes would become 10 * 2 = 20, or marks would duplicate!
        print(f"  KNOWN01 Unified -> Recorded Classes: {k1_unified['total_classes']} (Actual: 10), "
              f"Recorded Exams: {k1_unified['total_exams']} (Actual: 2), "
              f"Total Obtained: {k1_unified['total_obtained']} (Actual: 140.0)")

        assert k1_unified["total_classes"] == 10, f"Expected 10 classes, got {k1_unified['total_classes']} (Cartesian fanout error!)"
        assert k1_unified["total_exams"] == 2, f"Expected 2 exams, got {k1_unified['total_exams']} (Cartesian fanout error!)"
        assert k1_unified["total_obtained"] == 140.0, f"Expected 140.0 total marks, got {k1_unified['total_obtained']}"
        print("  ✓ ZERO double-counting: Subpipeline aggregation strictly preserves 1:1 cardinality")

        print("\n" + "=" * 70)
        print("🎉 ALL MATHEMATICAL AGGREGATION PIPELINE CHECKS PASSED! (7/7)")
        print("=" * 70)

    finally:
        # Cleanup known test data
        db.students.delete_many({"student_id": {"$regex": f"^{test_prefix}"}})
        db.attendance.delete_many({"student_id": {"$regex": f"^{test_prefix}"}})
        db.marks.delete_many({"student_id": {"$regex": f"^{test_prefix}"}})
        close_db()

if __name__ == "__main__":
    run_analytics_verification()
