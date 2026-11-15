"""
CampusTrack — Automated Test for the 9 MongoDB Viva Practical Examples
Verifies that all 9 demonstrated operations execute cleanly against the real database.
"""

import sys
from datetime import datetime, timezone
from pymongo.errors import WriteError
from db.connection import get_db, close_db

if sys.platform.startswith("win"):
    sys.stdout.reconfigure(encoding="utf-8")

def run_viva_examples_test():
    print("=" * 70)
    print("🎓 CAMPUS TRACK - TESTING 9 MONGODB VIVA EXAMPLES")
    print("=" * 70)

    db = get_db()
    test_id = "VIVA_TEST_101"
    now = datetime.now(timezone.utc)

    # 1. Insert documents
    print("\n[1] Testing Document Insertion...")
    stu_res = db.students.insert_one({
        "student_id": test_id,
        "name": "Viva Candidate",
        "course": "Computer Science",
        "department": "Computer Science",
        "semester": 6,
        "email": "viva.candidate@campus.edu",
        "phone": "+91-9999888877",
        "active": True,
        "created_at": now,
        "updated_at": now
    })
    assert stu_res.inserted_id is not None
    print(f"  ✓ Inserted student document (_id: {stu_res.inserted_id})")

    att_res = db.attendance.insert_one({
        "student_id": test_id,
        "date": "2026-10-25",
        "subject": "NoSQL Databases",
        "status": "Present",
        "remarks": "Viva live test",
        "created_at": now,
        "updated_at": now
    })
    assert att_res.inserted_id is not None
    print(f"  ✓ Inserted attendance document (_id: {att_res.inserted_id})")

    marks_res = db.marks.insert_one({
        "student_id": test_id,
        "subject": "NoSQL Databases",
        "exam": "Mid-Term",
        "marks_obtained": 48.0,
        "max_marks": 50.0,
        "percentage": 96.0,
        "created_at": now,
        "updated_at": now
    })
    assert marks_res.inserted_id is not None
    print(f"  ✓ Inserted marks document (_id: {marks_res.inserted_id})")

    # 2. Find and filter documents
    print("\n[2] Testing Find & Filter Queries...")
    doc = db.students.find_one({"student_id": test_id})
    assert doc is not None and doc["name"] == "Viva Candidate"
    print(f"  ✓ Filter by student_id returned: {doc['name']} ({doc['course']})")

    range_matches = list(db.marks.find({"student_id": test_id, "percentage": {"$gte": 90.0}}))
    assert len(range_matches) == 1
    print(f"  ✓ Range filter ($gte: 90.0) returned {len(range_matches)} score document")

    # 3. Update documents
    print("\n[3] Testing Document Updates ($set & $inc)...")
    db.students.update_one({"student_id": test_id}, {"$set": {"semester": 7}})
    updated_stu = db.students.find_one({"student_id": test_id})
    assert updated_stu["semester"] == 7
    print(f"  ✓ $set updated semester to: {updated_stu['semester']}")

    db.marks.update_one(
        {"student_id": test_id, "exam": "Mid-Term"},
        {"$inc": {"marks_obtained": 1.0}, "$set": {"percentage": 98.0}}
    )
    updated_mark = db.marks.find_one({"student_id": test_id})
    assert updated_mark["marks_obtained"] == 49.0
    print(f"  ✓ $inc updated marks_obtained to: {updated_mark['marks_obtained']}")

    # 4. Delete test document
    print("\n[4] Testing Document Deletion & Cascade...")
    db.attendance.delete_many({"student_id": test_id})
    db.marks.delete_many({"student_id": test_id})
    del_res = db.students.delete_one({"student_id": test_id})
    assert del_res.deleted_count == 1
    assert db.students.find_one({"student_id": test_id}) is None
    assert db.attendance.find_one({"student_id": test_id}) is None
    assert db.marks.find_one({"student_id": test_id}) is None
    print("  ✓ Document and cascaded references deleted cleanly (0 orphans)")

    # 5. Create and inspect indexes
    print("\n[5] Testing Index Inspection & Explain Plan...")
    indexes = db.students.index_information()
    unique_idx = next((v for k, v in indexes.items() if v.get("key") == [("student_id", 1)]), None)
    assert unique_idx is not None and unique_idx.get("unique") is True, f"Unique index on student_id not found: {indexes}"
    print(f"  ✓ Unique index verified: key={unique_idx['key']} (unique=True)")

    explanation = db.students.find({"student_id": "STU1001"}).explain()
    stage = explanation["executionStats"]["executionStages"]["stage"]
    assert "IXSCAN" in stage or stage in ["FETCH", "PROJECTION_COVERED"], f"Unexpected stage: {stage}"
    print(f"  ✓ Execution plan confirmed index utilization: stage='{stage}', "
          f"docsExamined={explanation['executionStats']['totalDocsExamined']}")

    # 6. Validate document structure ($jsonSchema)
    print("\n[6] Testing MongoDB $jsonSchema Validation...")
    try:
        db.students.insert_one({
            "student_id": "ERR_TEST",
            "name": "Invalid Candidate",
            "semester": 15,  # Out of range (1-8 allowed)
            "email": "not-valid",
            "course": "Computer Science"
        })
        print("  ❌ Expected validation error, but document was inserted!")
        sys.exit(1)
    except WriteError as e:
        print(f"  ✓ MongoDB $jsonSchema rejected invalid document: {e.details.get('errmsg', 'Validation failed')}")

    # 7. Aggregate attendance percentages
    print("\n[7] Testing Attendance Aggregation Pipeline...")
    att_pipe = [
        {"$group": {
            "_id": "$student_id",
            "total": {"$sum": 1},
            "present": {"$sum": {"$cond": [{"$eq": ["$status", "Present"]}, 1, 0]}},
            "late": {"$sum": {"$cond": [{"$eq": ["$status", "Late"]}, 1, 0]}}
        }},
        {"$project": {
            "attendance_pct": {
                "$round": [
                    {"$multiply": [{"$divide": [{"$add": ["$present", {"$multiply": ["$late", 0.5]}]}, "$total"]}, 100]},
                    2
                ]
            }
        }},
        {"$limit": 2}
    ]
    att_results = list(db.attendance.aggregate(att_pipe))
    assert len(att_results) > 0
    print(f"  ✓ Aggregated {len(att_results)} attendance metrics: {att_results[0]}")

    # 8. Calculate average marks and rankings
    print("\n[8] Testing Academic Rankings Pipeline...")
    marks_pipe = [
        {"$group": {
            "_id": "$student_id",
            "avg_pct": {"$avg": "$percentage"}
        }},
        {"$sort": {"avg_pct": -1}},
        {"$limit": 3}
    ]
    ranks = list(db.marks.aggregate(marks_pipe))
    assert len(ranks) == 3
    print(f"  ✓ Top Ranker from aggregation: {ranks[0]['_id']} with avg {round(ranks[0]['avg_pct'], 2)}%")

    # 9. Join student data with attendance or marks using $lookup
    print("\n[9] Testing $lookup Left Outer Join...")
    join_pipe = [
        {"$limit": 2},
        {"$lookup": {
            "from": "students",
            "localField": "student_id",
            "foreignField": "student_id",
            "as": "student"
        }},
        {"$unwind": "$student"},
        {"$project": {
            "student_id": 1,
            "subject": 1,
            "student_name": "$student.name",
            "course": "$student.course"
        }}
    ]
    joined = list(db.attendance.aggregate(join_pipe))
    assert len(joined) > 0
    print(f"  ✓ $lookup successfully joined attendance log to student '{joined[0]['student_name']}'")

    print("\n" + "=" * 70)
    print("🎉 ALL 9 MONGODB DEMONSTRATION EXAMPLES VERIFIED 100% OPERATIONAL!")
    print("=" * 70)

if __name__ == "__main__":
    try:
        run_viva_examples_test()
    finally:
        close_db()
