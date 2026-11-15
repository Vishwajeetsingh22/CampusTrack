from flask import Blueprint, request
from services.attendance_service import (
    record_attendance,
    batch_record_attendance,
    get_attendance_records,
    update_attendance_by_id,
    delete_attendance_by_id,
    get_attendance_summary
)
from utils.serializers import success_response, error_response

attendance_bp = Blueprint("attendance", __name__, url_prefix="/api/attendance")

@attendance_bp.route("", methods=["GET"])
def list_attendance():
    """
    List attendance records.
    Query parameters: student_id, date, subject, status, page, limit.
    """
    student_id = request.args.get("student_id")
    date_str = request.args.get("date")
    subject = request.args.get("subject")
    status = request.args.get("status")
    limit = request.args.get("limit", 100)
    skip = request.args.get("skip", 0)
    page = request.args.get("page")

    try:
        result = get_attendance_records(
            student_id=student_id,
            date=date_str,
            subject=subject,
            status=status,
            limit=limit,
            skip=skip,
            page=page
        )
        return success_response(
            data=result["records"],
            message="Attendance records retrieved successfully",
            total=result["total"],
            count=result["count"],
            page=result["page"],
            limit=result["limit"]
        )
    except Exception as e:
        return error_response(f"Failed to fetch attendance: {str(e)}", status_code=500)

@attendance_bp.route("/summary", methods=["GET"])
def attendance_summary():
    """
    Get aggregated attendance summary.
    Query parameters: student_id, subject, date.
    Uses MongoDB aggregation pipeline.
    """
    student_id = request.args.get("student_id")
    subject = request.args.get("subject")
    date_str = request.args.get("date")

    try:
        summary = get_attendance_summary(
            student_id=student_id,
            subject=subject,
            date=date_str
        )
        return success_response(
            data=summary,
            message="Attendance summary computed successfully"
        )
    except Exception as e:
        return error_response(f"Failed to compute attendance summary: {str(e)}", status_code=500)

@attendance_bp.route("", methods=["POST"])
def mark_attendance_endpoint():
    """
    Mark attendance for a student (Present, Absent, Late).
    Prevents duplicate entries for the same student_id, date, and subject.
    """
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    record, errors, status_code = record_attendance(data)
    if errors:
        return error_response("Failed to record attendance", status_code=status_code, details=errors)

    return success_response(
        data=record,
        message="Attendance recorded successfully",
        status_code=status_code
    )

@attendance_bp.route("/batch", methods=["POST"])
def batch_attendance_endpoint():
    """Batch mark attendance for an entire class/subject for a specific date."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    result, errors, status_code = batch_record_attendance(data)
    if errors:
        return error_response("Batch recording error", status_code=status_code, details=errors)

    return success_response(
        data=result,
        message="Batch attendance recorded successfully",
        status_code=status_code
    )

@attendance_bp.route("/<record_id>", methods=["PUT"])
def modify_attendance(record_id):
    """Update status, remarks, date, or subject of an existing attendance record."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    record, errors, status_code = update_attendance_by_id(record_id, data)
    if errors:
        return error_response("Failed to update attendance", status_code=status_code, details=errors)

    return success_response(data=record, message="Attendance updated successfully")

@attendance_bp.route("/<record_id>", methods=["DELETE"])
def remove_attendance(record_id):
    """Delete an attendance record."""
    success, message, status_code = delete_attendance_by_id(record_id)
    if not success:
        return error_response(message, status_code=status_code)

    return success_response(message=message)
