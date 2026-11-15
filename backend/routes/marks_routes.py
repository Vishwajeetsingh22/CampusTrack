from flask import Blueprint, request
from services.marks_service import (
    add_marks,
    get_marks_records,
    update_marks_by_id,
    delete_marks_by_id,
    get_marks_summary
)
from utils.serializers import success_response, error_response

marks_bp = Blueprint("marks", __name__, url_prefix="/api/marks")

@marks_bp.route("", methods=["GET"])
def list_marks():
    """
    List examination marks records with student details and filters.
    Query parameters: student_id, subject, exam, page, limit.
    """
    student_id = request.args.get("student_id")
    subject = request.args.get("subject")
    exam = request.args.get("exam")
    limit = request.args.get("limit", 100)
    skip = request.args.get("skip", 0)
    page = request.args.get("page")

    try:
        result = get_marks_records(
            student_id=student_id,
            subject=subject,
            exam=exam,
            limit=limit,
            skip=skip,
            page=page
        )
        return success_response(
            data=result["records"],
            message="Marks records retrieved successfully",
            total=result["total"],
            count=result["count"],
            page=result["page"],
            limit=result["limit"]
        )
    except Exception as e:
        return error_response(f"Failed to fetch marks: {str(e)}", status_code=500)

@marks_bp.route("/summary", methods=["GET"])
def marks_summary():
    """
    Get aggregated marks summary.
    Query parameters: student_id, subject, exam.
    Uses MongoDB aggregation pipeline.
    """
    student_id = request.args.get("student_id")
    subject = request.args.get("subject")
    exam = request.args.get("exam")

    try:
        summary = get_marks_summary(
            student_id=student_id,
            subject=subject,
            exam=exam
        )
        return success_response(
            data=summary,
            message="Marks summary computed successfully"
        )
    except Exception as e:
        return error_response(f"Failed to compute marks summary: {str(e)}", status_code=500)

@marks_bp.route("", methods=["POST"])
def record_marks():
    """
    Add exam marks for a student and calculate percentage.
    Validates: 0 <= marks_obtained <= max_marks and max_marks > 0.
    Prevents duplicate entries for the same student_id, subject, and exam.
    """
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    record, errors, status_code = add_marks(data)
    if errors:
        return error_response("Failed to record marks", status_code=status_code, details=errors)

    return success_response(
        data=record,
        message="Marks recorded and percentage calculated successfully",
        status_code=status_code
    )

@marks_bp.route("/<record_id>", methods=["PUT"])
def modify_marks(record_id):
    """
    Update exam marks and recalculate percentage.
    Validates: 0 <= marks_obtained <= max_marks.
    """
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    record, errors, status_code = update_marks_by_id(record_id, data)
    if errors:
        return error_response("Failed to update marks", status_code=status_code, details=errors)

    return success_response(data=record, message="Marks updated successfully")

@marks_bp.route("/<record_id>", methods=["DELETE"])
def remove_marks(record_id):
    """Delete an exam marks entry."""
    success, message, status_code = delete_marks_by_id(record_id)
    if not success:
        return error_response(message, status_code=status_code)

    return success_response(message=message)
