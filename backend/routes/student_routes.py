from flask import Blueprint, request
from services.student_service import (
    create_student,
    get_students,
    get_student_by_id,
    update_student,
    delete_student
)
from services.aggregation_service import get_student_full_summary
from utils.serializers import success_response, error_response

student_bp = Blueprint("students", __name__, url_prefix="/api/students")

@student_bp.route("", methods=["GET"])
def list_students():
    """
    List and search students.
    Query parameters: search, course, department, semester, active, page, limit.
    """
    search = request.args.get("search")
    course = request.args.get("course")
    department = request.args.get("department")
    semester = request.args.get("semester")
    active = request.args.get("active")
    limit = request.args.get("limit", 100)
    skip = request.args.get("skip", 0)
    page = request.args.get("page")

    try:
        result = get_students(
            search=search,
            course=course,
            department=department,
            semester=semester,
            active=active,
            limit=limit,
            skip=skip,
            page=page
        )
        return success_response(
            data=result["students"],
            message="Students retrieved successfully",
            total=result["total"],
            count=result["count"],
            page=result["page"],
            limit=result["limit"]
        )
    except Exception as e:
        return error_response(f"Failed to fetch students: {str(e)}", status_code=500)

@student_bp.route("", methods=["POST"])
def add_student():
    """Create a new student."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    student, errors, status_code = create_student(data)
    if errors:
        return error_response("Validation error", status_code=status_code, details=errors)

    return success_response(
        data=student,
        message="Student registered successfully",
        status_code=201
    )

@student_bp.route("/<identifier>", methods=["GET"])
def get_single_student(identifier):
    """Retrieve one student by student_id or ObjectId."""
    try:
        student = get_student_by_id(identifier)
        if not student:
            return error_response(f"Student with identifier '{identifier}' not found.", status_code=404)
        return success_response(data=student, message="Student retrieved successfully")
    except Exception as e:
        return error_response(f"Error fetching student: {str(e)}", status_code=500)

@student_bp.route("/<identifier>", methods=["PUT"])
def modify_student(identifier):
    """Update student profile details."""
    data = request.get_json()
    if not data or not isinstance(data, dict):
        return error_response("Request body must be a valid JSON object.", status_code=400)

    student, errors, status_code = update_student(identifier, data)
    if errors:
        return error_response("Failed to update student", status_code=status_code, details=errors)

    return success_response(data=student, message="Student updated successfully")

@student_bp.route("/<identifier>", methods=["DELETE"])
def remove_student(identifier):
    """Safely delete a student and cascade cleanup related records to prevent broken references."""
    success, result, status_code = delete_student(identifier)
    if not success:
        return error_response(result, status_code=status_code)

    return success_response(data=result, message="Student and related records deleted successfully")

@student_bp.route("/<identifier>/summary", methods=["GET"])
def get_student_summary(identifier):
    """Get complete 360-degree student profile including attendance and academic standing."""
    student = get_student_by_id(identifier)
    if not student:
        return error_response(f"Student '{identifier}' not found.", status_code=404)

    summary = get_student_full_summary(student["student_id"])
    if not summary:
        return error_response("Failed to generate summary.", status_code=500)

    return success_response(data=summary, message="Student profile summary retrieved successfully")
