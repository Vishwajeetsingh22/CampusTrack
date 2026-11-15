from flask import Blueprint, request
from services.aggregation_service import (
    get_dashboard_stats,
    get_attendance_report,
    get_performance_report,
    get_low_attendance_report,
    get_student_rankings,
    get_subject_attendance_report,
    get_student_unified_analytics
)
from utils.serializers import success_response, error_response

report_bp = Blueprint("reports", __name__, url_prefix="/api/reports")

@report_bp.route("/dashboard", methods=["GET"])
def dashboard_metrics():
    """Returns aggregated high-level metrics for dashboard cards and charts."""
    try:
        stats = get_dashboard_stats()
        return success_response(data=stats, message="Dashboard metrics generated successfully")
    except Exception as e:
        return error_response(f"Failed to generate dashboard metrics: {str(e)}", status_code=500)

@report_bp.route("/attendance", methods=["GET"])
def attendance_report():
    """
    Comprehensive student-by-student attendance report.
    Query parameters: course, department, semester.
    Uses MongoDB aggregation pipeline ($group, $project, $lookup).
    """
    course = request.args.get("course") or request.args.get("department")
    semester = request.args.get("semester")

    try:
        report = get_attendance_report(course=course, semester=semester)
        return success_response(
            data=report,
            message="Attendance report generated successfully",
            count=len(report)
        )
    except Exception as e:
        return error_response(f"Failed to generate attendance report: {str(e)}", status_code=500)

@report_bp.route("/performance", methods=["GET"])
def performance_report():
    """
    Subject-wise and overall examination performance report.
    Query parameters: course, exam.
    Uses MongoDB aggregation pipeline ($group, $project).
    """
    course = request.args.get("course")
    exam = request.args.get("exam")

    try:
        report = get_performance_report(course=course, exam=exam)
        return success_response(
            data=report,
            message="Performance report generated successfully"
        )
    except Exception as e:
        return error_response(f"Failed to generate performance report: {str(e)}", status_code=500)

@report_bp.route("/low-attendance", methods=["GET"])
@report_bp.route("/defaulters", methods=["GET"])
def low_attendance_list():
    """
    Returns students whose attendance percentage is below threshold (default 75%).
    Query parameters: threshold (default 75.0).
    Uses MongoDB aggregation pipeline ($match: { attendance_pct: { $lt: 75 } }).
    """
    threshold = request.args.get("threshold", 75.0)
    try:
        thresh_val = float(threshold)
    except ValueError:
        thresh_val = 75.0

    try:
        students = get_low_attendance_report(threshold=thresh_val)
        return success_response(
            data=students,
            message=f"Found {len(students)} students below {thresh_val}% attendance threshold",
            threshold=thresh_val,
            count=len(students)
        )
    except Exception as e:
        return error_response(f"Failed to fetch low attendance report: {str(e)}", status_code=500)

@report_bp.route("/rankings", methods=["GET"])
def class_rankings():
    """
    Student rankings sorted by cumulative marks percentage.
    Query parameters: course, department, semester.
    Uses MongoDB aggregation pipeline ($group, $lookup, $sort).
    """
    course = request.args.get("course") or request.args.get("department")
    semester = request.args.get("semester")

    try:
        rankings = get_student_rankings(course=course, semester=semester)
        return success_response(
            data=rankings,
            message="Student rankings computed successfully",
            count=len(rankings)
        )
    except Exception as e:
        return error_response(f"Failed to calculate rankings: {str(e)}", status_code=500)

@report_bp.route("/subject-attendance", methods=["GET"])
def subject_attendance():
    """
    Subject-wise attendance summary report.
    Query parameters: course.
    Uses MongoDB aggregation pipeline ($group by subject, $addToSet, $project).
    """
    course = request.args.get("course")
    try:
        report = get_subject_attendance_report(course=course)
        return success_response(
            data=report,
            message="Subject attendance summary computed successfully",
            count=len(report)
        )
    except Exception as e:
        return error_response(f"Failed to generate subject attendance: {str(e)}", status_code=500)

@report_bp.route("/unified", methods=["GET"])
def unified_student_analytics():
    """
    360-degree student analytics preventing Cartesian double-counting.
    Demonstrates correlated subquery $lookup with internal $group.
    Query parameters: student_id.
    """
    student_id = request.args.get("student_id")
    try:
        analytics = get_student_unified_analytics(student_id=student_id)
        return success_response(
            data=analytics,
            message="Unified student analytics computed successfully (0 double counting)",
            count=len(analytics)
        )
    except Exception as e:
        return error_response(f"Failed to compute unified analytics: {str(e)}", status_code=500)

