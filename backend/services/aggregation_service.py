import logging
from db.connection import get_db

logger = logging.getLogger("campustrack.aggregations")

def get_dashboard_stats():
    """
    Computes summary metrics and chart data using MongoDB Aggregation Pipelines.
    - Total students and active student counts
    - Average overall attendance %
    - Average overall marks %
    - Attendance status breakdown (Present, Absent, Late)
    - Course & department distribution
    - Number of students with low attendance (< 75%)
    """
    db = get_db()
    total_students = db.students.count_documents({})
    active_students = db.students.count_documents({"active": True})
    total_attendance_records = db.attendance.count_documents({})
    total_marks_records = db.marks.count_documents({})

    # 1. Overall Attendance Percentage Pipeline
    att_pipeline = [
        {
            "$group": {
                "_id": "$status",
                "count": {"$sum": 1}
            }
        }
    ]
    att_results = list(db.attendance.aggregate(att_pipeline))
    att_counts = {item["_id"]: item["count"] for item in att_results if item.get("_id")}
    
    present_count = att_counts.get("Present", 0)
    absent_count = att_counts.get("Absent", 0)
    late_count = att_counts.get("Late", 0)
    
    # Present = 100%, Late = 50%
    overall_attendance_pct = 0.0
    if total_attendance_records > 0:
        overall_attendance_pct = round(((present_count + (late_count * 0.5)) / total_attendance_records) * 100.0, 2)

    # 2. Overall Average Marks Percentage Pipeline
    marks_pipeline = [
        {
            "$group": {
                "_id": None,
                "avg_percentage": {"$avg": "$percentage"}
            }
        }
    ]
    marks_results = list(db.marks.aggregate(marks_pipeline))
    avg_marks_pct = round(marks_results[0]["avg_percentage"], 2) if marks_results and marks_results[0].get("avg_percentage") is not None else 0.0

    # 3. Course / Department distribution for Pie/Bar charts
    course_pipeline = [
        {
            "$group": {
                "_id": {"$ifNull": ["$course", "$department"]},
                "student_count": {"$sum": 1}
            }
        },
        {"$sort": {"student_count": -1}}
    ]
    course_results = list(db.students.aggregate(course_pipeline))
    course_distribution = [
        {"course": d["_id"] or "Unassigned", "department": d["_id"] or "Unassigned", "count": d["student_count"]}
        for d in course_results if d.get("_id")
    ]

    # 4. Status breakdown
    status_breakdown = [
        {"status": "Present", "count": present_count},
        {"status": "Absent", "count": absent_count},
        {"status": "Late", "count": late_count}
    ]

    # 5. Low attendance count (< 75%)
    low_attendance_students = get_low_attendance_report(threshold=75.0)
    low_attendance_count = len(low_attendance_students)

    return {
        "total_students": total_students,
        "active_students": active_students,
        "total_attendance_records": total_attendance_records,
        "total_marks_records": total_marks_records,
        "overall_attendance_pct": overall_attendance_pct,
        "avg_marks_pct": avg_marks_pct,
        "low_attendance_count": low_attendance_count,
        "department_distribution": course_distribution,
        "course_distribution": course_distribution,
        "status_breakdown": status_breakdown
    }

def get_attendance_report(course=None, semester=None):
    """
    MongoDB Aggregation Pipeline for comprehensive student-by-student attendance reporting.
    Calculates total classes, present, absent, late, and attendance percentage.
    """
    db = get_db()
    pipeline = [
        {
            "$group": {
                "_id": "$student_id",
                "total_classes": {"$sum": 1},
                "present_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "Present"]}, 1, 0]}
                },
                "absent_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "Absent"]}, 1, 0]}
                },
                "late_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "Late"]}, 1, 0]}
                }
            }
        },
        {
            "$project": {
                "student_id": "$_id",
                "_id": 0,
                "total_classes": 1,
                "present_count": 1,
                "absent_count": 1,
                "late_count": 1,
                "attendance_pct": {
                    "$cond": [
                        {"$gt": ["$total_classes", 0]},
                        {
                            "$round": [
                                {
                                    "$multiply": [
                                        {
                                            "$divide": [
                                                {"$add": ["$present_count", {"$multiply": ["$late_count", 0.5]}]},
                                                "$total_classes"
                                            ]
                                        },
                                        100
                                    ]
                                },
                                2
                            ]
                        },
                        0.0
                    ]
                }
            }
        },
        {
            "$lookup": {
                "from": "students",
                "localField": "student_id",
                "foreignField": "student_id",
                "as": "student"
            }
        },
        {
            "$unwind": {
                "path": "$student",
                "preserveNullAndEmptyArrays": True
            }
        }
    ]

    # Optional match on student course/department/semester
    match_conditions = {}
    if course:
        match_conditions["$or"] = [
            {"student.course": course.strip()},
            {"student.department": course.strip()}
        ]
    if semester:
        try:
            match_conditions["student.semester"] = int(semester)
        except (ValueError, TypeError):
            pass

    if match_conditions:
        pipeline.append({"$match": match_conditions})

    pipeline.extend([
        {
            "$project": {
                "student_id": 1,
                "name": {"$ifNull": ["$student.name", "Unknown"]},
                "course": {"$ifNull": ["$student.course", "$student.department"]},
                "department": {"$ifNull": ["$student.department", "$student.course"]},
                "semester": {"$ifNull": ["$student.semester", 0]},
                "email": {"$ifNull": ["$student.email", ""]},
                "total_classes": 1,
                "present_count": 1,
                "absent_count": 1,
                "late_count": 1,
                "attendance_pct": 1,
                "status": {
                    "$cond": [{"$lt": ["$attendance_pct", 75.0]}, "Low Attendance", "Normal"]
                }
            }
        },
        {"$sort": {"attendance_pct": -1, "student_id": 1}}
    ])

    return list(db.attendance.aggregate(pipeline))

def get_performance_report(course=None, exam=None):
    """
    MongoDB Aggregation Pipeline for subject performance analytics and grade summary.
    """
    db = get_db()
    pipeline = []
    if exam:
        pipeline.append({"$match": {"exam": exam.strip()}})

    pipeline.extend([
        {
            "$group": {
                "_id": "$subject",
                "student_count": {"$sum": 1},
                "avg_percentage": {"$avg": "$percentage"},
                "max_percentage": {"$max": "$percentage"},
                "min_percentage": {"$min": "$percentage"},
                "avg_obtained": {"$avg": "$marks_obtained"},
                "max_obtained": {"$max": "$marks_obtained"},
                "min_obtained": {"$min": "$marks_obtained"},
                "pass_count": {
                    "$sum": {"$cond": [{"$gte": ["$percentage", 40.0]}, 1, 0]}
                }
            }
        },
        {
            "$project": {
                "subject": "$_id",
                "_id": 0,
                "student_count": 1,
                "pass_count": 1,
                "pass_percentage": {
                    "$cond": [
                        {"$gt": ["$student_count", 0]},
                        {
                            "$round": [
                                {"$multiply": [{"$divide": ["$pass_count", "$student_count"]}, 100]},
                                2
                            ]
                        },
                        0.0
                    ]
                },
                "avg_percentage": {"$round": ["$avg_percentage", 2]},
                "max_percentage": {"$round": ["$max_percentage", 2]},
                "min_percentage": {"$round": ["$min_percentage", 2]},
                "avg_obtained": {"$round": ["$avg_obtained", 2]},
                "max_obtained": {"$round": ["$max_obtained", 2]},
                "min_obtained": {"$round": ["$min_obtained", 2]}
            }
        },
        {"$sort": {"subject": 1}}
    ])

    subject_stats = list(db.marks.aggregate(pipeline))

    # Overall marks stats
    overall_pipeline = []
    if exam:
        overall_pipeline.append({"$match": {"exam": exam.strip()}})
    overall_pipeline.append({
        "$group": {
            "_id": None,
            "overall_avg": {"$avg": "$percentage"},
            "highest_score": {"$max": "$percentage"},
            "lowest_score": {"$min": "$percentage"},
            "total_assessments": {"$sum": 1}
        }
    })
    overall_res = list(db.marks.aggregate(overall_pipeline))
    overall_metric = overall_res[0] if overall_res else {
        "overall_avg": 0.0,
        "highest_score": 0.0,
        "lowest_score": 0.0,
        "total_assessments": 0
    }

    return {
        "subjects": subject_stats,
        "overall_summary": {
            "overall_avg": round(overall_metric.get("overall_avg", 0.0), 2),
            "highest_score": round(overall_metric.get("highest_score", 0.0), 2),
            "lowest_score": round(overall_metric.get("lowest_score", 0.0), 2),
            "total_assessments": overall_metric.get("total_assessments", 0)
        }
    }

def get_low_attendance_report(threshold=75.0):
    """
    MongoDB Aggregation Pipeline to identify students below attendance threshold (< 75%).
    Uses: $group, $project, $match, and $lookup.
    """
    db = get_db()
    pipeline = [
        {
            "$group": {
                "_id": "$student_id",
                "total_classes": {"$sum": 1},
                "present_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "Present"]}, 1, 0]}
                },
                "absent_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "Absent"]}, 1, 0]}
                },
                "late_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "Late"]}, 1, 0]}
                }
            }
        },
        {
            "$project": {
                "student_id": "$_id",
                "_id": 0,
                "total_classes": 1,
                "present_count": 1,
                "absent_count": 1,
                "late_count": 1,
                "attendance_pct": {
                    "$cond": [
                        {"$gt": ["$total_classes", 0]},
                        {
                            "$round": [
                                {
                                    "$multiply": [
                                        {
                                            "$divide": [
                                                {"$add": ["$present_count", {"$multiply": ["$late_count", 0.5]}]},
                                                "$total_classes"
                                            ]
                                        },
                                        100
                                    ]
                                },
                                2
                            ]
                        },
                        0.0
                    ]
                }
            }
        },
        {
            "$match": {
                "attendance_pct": {"$lt": float(threshold)}
            }
        },
        {
            "$lookup": {
                "from": "students",
                "localField": "student_id",
                "foreignField": "student_id",
                "as": "student_info"
            }
        },
        {
            "$unwind": {
                "path": "$student_info",
                "preserveNullAndEmptyArrays": True
            }
        },
        {
            "$project": {
                "student_id": 1,
                "name": {"$ifNull": ["$student_info.name", "Unknown"]},
                "course": {"$ifNull": ["$student_info.course", "$student_info.department"]},
                "department": {"$ifNull": ["$student_info.department", "$student_info.course"]},
                "semester": {"$ifNull": ["$student_info.semester", 0]},
                "email": {"$ifNull": ["$student_info.email", "N/A"]},
                "phone": {"$ifNull": ["$student_info.phone", "N/A"]},
                "total_classes": 1,
                "present_count": 1,
                "absent_count": 1,
                "late_count": 1,
                "attendance_pct": 1,
                "shortfall": {
                    "$round": [{"$subtract": [float(threshold), "$attendance_pct"]}, 2]
                }
            }
        },
        {"$sort": {"attendance_pct": 1}}
    ]

    return list(db.attendance.aggregate(pipeline))

# Alias for backwards-compatibility
get_defaulters_report = get_low_attendance_report

def get_student_rankings(course=None, department=None, semester=None):
    """
    MongoDB Aggregation Pipeline to calculate student rankings based on average marks percentage.
    Uses: $group, $sort, $lookup, and $project.
    """
    db = get_db()
    pipeline = [
        {
            "$group": {
                "_id": "$student_id",
                "total_exams": {"$sum": 1},
                "total_obtained": {"$sum": "$marks_obtained"},
                "total_max": {"$sum": "$max_marks"},
                "avg_percentage": {"$avg": "$percentage"}
            }
        },
        {
            "$project": {
                "student_id": "$_id",
                "_id": 0,
                "total_exams": 1,
                "total_obtained": {"$round": ["$total_obtained", 2]},
                "total_max": {"$round": ["$total_max", 2]},
                "avg_percentage": {
                    "$cond": [
                        {"$and": [{"$ne": ["$avg_percentage", None]}, {"$gt": ["$total_exams", 0]}]},
                        {"$round": ["$avg_percentage", 2]},
                        0.0
                    ]
                }
            }
        },
        {
            "$lookup": {
                "from": "students",
                "localField": "student_id",
                "foreignField": "student_id",
                "as": "student_info"
            }
        },
        {
            "$unwind": {
                "path": "$student_info",
                "preserveNullAndEmptyArrays": True
            }
        }
    ]

    academic_course = course or department
    match_conditions = {}
    if academic_course:
        match_conditions["$or"] = [
            {"student_info.course": academic_course.strip()},
            {"student_info.department": academic_course.strip()}
        ]
    if semester:
        try:
            match_conditions["student_info.semester"] = int(semester)
        except (ValueError, TypeError):
            pass

    if match_conditions:
        pipeline.append({"$match": match_conditions})

    pipeline.extend([
        {
            "$project": {
                "student_id": 1,
                "name": {"$ifNull": ["$student_info.name", "Unknown"]},
                "course": {"$ifNull": ["$student_info.course", "$student_info.department"]},
                "department": {"$ifNull": ["$student_info.department", "$student_info.course"]},
                "semester": {"$ifNull": ["$student_info.semester", 0]},
                "email": {"$ifNull": ["$student_info.email", ""]},
                "total_exams": 1,
                "total_obtained": 1,
                "total_max": 1,
                "avg_percentage": 1
            }
        },
        {"$sort": {"avg_percentage": -1}}
    ])

    results = list(db.marks.aggregate(pipeline))
    
    # Assign sequential ranks
    for rank, item in enumerate(results, start=1):
        item["rank"] = rank

    return results

# Backwards compatible alias
get_subject_performance = lambda exam=None: get_performance_report(exam=exam)["subjects"]

def get_student_full_summary(student_id):
    """Generates a consolidated 360-degree report for a single student."""
    db = get_db()
    student = db.students.find_one({"student_id": student_id})
    if not student:
        return None

    # Attendance summary
    att_pipeline = [
        {"$match": {"student_id": student_id}},
        {
            "$group": {
                "_id": "$status",
                "count": {"$sum": 1}
            }
        }
    ]
    att_results = list(db.attendance.aggregate(att_pipeline))
    counts = {r["_id"]: r["count"] for r in att_results if r.get("_id")}
    total_classes = sum(counts.values())
    present = counts.get("Present", 0)
    absent = counts.get("Absent", 0)
    late = counts.get("Late", 0)
    att_pct = round(((present + (late * 0.5)) / total_classes) * 100.0, 2) if total_classes > 0 else 0.0

    # Marks summary
    marks_pipeline = [
        {"$match": {"student_id": student_id}},
        {
            "$group": {
                "_id": None,
                "total_exams": {"$sum": 1},
                "avg_percentage": {"$avg": "$percentage"}
            }
        }
    ]
    marks_summary = list(db.marks.aggregate(marks_pipeline))
    avg_marks = round(marks_summary[0]["avg_percentage"], 2) if marks_summary and marks_summary[0].get("avg_percentage") is not None else 0.0

    return {
        "student": student,
        "attendance": {
            "total_classes": total_classes,
            "present": present,
            "absent": absent,
            "late": late,
            "percentage": att_pct,
            "is_defaulter": att_pct < 75.0 if total_classes > 0 else False
        },
        "academics": {
            "total_assessments": marks_summary[0]["total_exams"] if marks_summary else 0,
            "average_percentage": avg_marks
        }
    }

def explain_query_execution(collection_name, query_filter):
    """Runs explain('executionStats') on a MongoDB query for viva demonstration."""
    db = get_db()
    if collection_name not in ["students", "attendance", "marks"]:
        raise ValueError("Invalid collection name for demonstration")

    cursor = db[collection_name].find(query_filter)
    explanation = cursor.explain()["executionStats"]
    
    stage = explanation.get("executionStages", {}).get("stage")
    index_name = explanation.get("executionStages", {}).get("indexName")
    total_docs_examined = explanation.get("totalDocsExamined")
    total_keys_examined = explanation.get("totalKeysExamined")
    n_returned = explanation.get("nReturned")
    execution_time_ms = explanation.get("executionTimeMillis")

    return {
        "collection": collection_name,
        "query": query_filter,
        "execution_stage": stage,
        "index_used": index_name,
        "is_indexed_scan": stage in ["IXSCAN", "FETCH"],
        "n_returned": n_returned,
        "total_docs_examined": total_docs_examined,
        "total_keys_examined": total_keys_examined,
        "execution_time_ms": execution_time_ms,
        "performance_note": "Indexed scan (IXSCAN) avoids scanning entire collection!" if stage in ["IXSCAN", "FETCH"] else "Collection scan (COLLSCAN) checked all documents."
    }

def get_subject_attendance_report(course=None):
    """
    MongoDB Aggregation Pipeline for Subject-wise Attendance Summaries.
    Calculates total sessions, present, absent, late, unique student count, and attendance percentage.
    Pipeline stages: $match (optional), $group, $project, $sort.
    Attendance rule: Present = 1.0, Late = 0.5, Absent = 0.0.
    """
    db = get_db()
    pipeline = []

    if course:
        # Filter attendance logs belonging to students in this course via $lookup
        pipeline.extend([
            {
                "$lookup": {
                    "from": "students",
                    "localField": "student_id",
                    "foreignField": "student_id",
                    "as": "student"
                }
            },
            {"$unwind": "$student"},
            {
                "$match": {
                    "$or": [
                        {"student.course": course.strip()},
                        {"student.department": course.strip()}
                    ]
                }
            }
        ])

    pipeline.extend([
        {
            "$group": {
                "_id": "$subject",
                "total_records": {"$sum": 1},
                "unique_students": {"$addToSet": "$student_id"},
                "present_count": {"$sum": {"$cond": [{"$eq": ["$status", "Present"]}, 1, 0]}},
                "absent_count": {"$sum": {"$cond": [{"$eq": ["$status", "Absent"]}, 1, 0]}},
                "late_count": {"$sum": {"$cond": [{"$eq": ["$status", "Late"]}, 1, 0]}}
            }
        },
        {
            "$project": {
                "subject": "$_id",
                "_id": 0,
                "total_records": 1,
                "student_count": {"$size": "$unique_students"},
                "present_count": 1,
                "absent_count": 1,
                "late_count": 1,
                "attendance_percentage": {
                    "$cond": [
                        {"$gt": ["$total_records", 0]},
                        {
                            "$round": [
                                {
                                    "$multiply": [
                                        {
                                            "$divide": [
                                                {"$add": ["$present_count", {"$multiply": ["$late_count", 0.5]}]},
                                                "$total_records"
                                            ]
                                        },
                                        100
                                    ]
                                },
                                2
                            ]
                        },
                        0.0
                    ]
                }
            }
        },
        {"$sort": {"attendance_percentage": -1, "subject": 1}}
    ])

    return list(db.attendance.aggregate(pipeline))

def get_student_unified_analytics(student_id=None):
    """
    MongoDB Aggregation Pipeline demonstrating prevention of Cartesian product double-counting.
    
    PROBLEM:
    Joining multiple 1-to-many collections (Students -> Attendance, Students -> Marks) via
    naive $lookup and $unwind multiplies documents (Cartesian product: N attendance * M marks = N*M docs).
    Summing marks or classes on that joined set causes massive duplicate counting!
    
    SOLUTION:
    We use correlated subpipeline $lookup with internal $group. Each subquery groups attendance
    and marks separately before returning at most ONE summary document per student.
    Unwinding these pre-grouped documents maintains strict 1:1 cardinality with zero double-counting!
    """
    db = get_db()
    match_stage = {}
    if student_id:
        match_stage["student_id"] = student_id.strip().upper()

    pipeline = [
        {"$match": match_stage} if match_stage else {"$match": {}},
        # Correlated subpipeline lookup for attendance
        {
            "$lookup": {
                "from": "attendance",
                "let": {"sid": "$student_id"},
                "pipeline": [
                    {"$match": {"$expr": {"$eq": ["$student_id", "$$sid"]}}},
                    {
                        "$group": {
                            "_id": "$student_id",
                            "total_classes": {"$sum": 1},
                            "present": {"$sum": {"$cond": [{"$eq": ["$status", "Present"]}, 1, 0]}},
                            "absent": {"$sum": {"$cond": [{"$eq": ["$status", "Absent"]}, 1, 0]}},
                            "late": {"$sum": {"$cond": [{"$eq": ["$status", "Late"]}, 1, 0]}}
                        }
                    }
                ],
                "as": "attendance_stats"
            }
        },
        # Correlated subpipeline lookup for marks
        {
            "$lookup": {
                "from": "marks",
                "let": {"sid": "$student_id"},
                "pipeline": [
                    {"$match": {"$expr": {"$eq": ["$student_id", "$$sid"]}}},
                    {
                        "$group": {
                            "_id": "$student_id",
                            "total_exams": {"$sum": 1},
                            "total_obtained": {"$sum": "$marks_obtained"},
                            "total_max": {"$sum": "$max_marks"},
                            "avg_percentage": {"$avg": "$percentage"}
                        }
                    }
                ],
                "as": "marks_stats"
            }
        },
        # Unwind with preserveNullAndEmptyArrays to handle students with 0 attendance or 0 marks without crashing
        {
            "$unwind": {
                "path": "$attendance_stats",
                "preserveNullAndEmptyArrays": True
            }
        },
        {
            "$unwind": {
                "path": "$marks_stats",
                "preserveNullAndEmptyArrays": True
            }
        },
        # Project clean metrics with zero-division protection
        {
            "$project": {
                "student_id": 1,
                "name": 1,
                "course": {"$ifNull": ["$course", "$department"]},
                "semester": 1,
                "email": 1,
                "active": 1,
                "total_classes": {"$ifNull": ["$attendance_stats.total_classes", 0]},
                "present_count": {"$ifNull": ["$attendance_stats.present", 0]},
                "late_count": {"$ifNull": ["$attendance_stats.late", 0]},
                "absent_count": {"$ifNull": ["$attendance_stats.absent", 0]},
                "attendance_percentage": {
                    "$cond": [
                        {"$gt": [{"$ifNull": ["$attendance_stats.total_classes", 0]}, 0]},
                        {
                            "$round": [
                                {
                                    "$multiply": [
                                        {
                                            "$divide": [
                                                {
                                                    "$add": [
                                                        {"$ifNull": ["$attendance_stats.present", 0]},
                                                        {"$multiply": [{"$ifNull": ["$attendance_stats.late", 0]}, 0.5]}
                                                    ]
                                                },
                                                "$attendance_stats.total_classes"
                                            ]
                                        },
                                        100
                                    ]
                                },
                                2
                            ]
                        },
                        0.0
                    ]
                },
                "total_exams": {"$ifNull": ["$marks_stats.total_exams", 0]},
                "total_obtained": {"$round": [{"$ifNull": ["$marks_stats.total_obtained", 0.0]}, 2]},
                "total_max": {"$round": [{"$ifNull": ["$marks_stats.total_max", 0.0]}, 2]},
                "marks_percentage": {
                    "$cond": [
                        {"$and": [
                            {"$ne": ["$marks_stats.avg_percentage", None]},
                            {"$gt": [{"$ifNull": ["$marks_stats.total_exams", 0]}, 0]}
                        ]},
                        {"$round": ["$marks_stats.avg_percentage", 2]},
                        0.0
                    ]
                }
            }
        },
        {"$sort": {"marks_percentage": -1, "attendance_percentage": -1}}
    ]

    return list(db.students.aggregate(pipeline))

