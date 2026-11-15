from flask import Blueprint, request
from db.connection import get_db
from db.schema_validator import STUDENTS_SCHEMA, ATTENDANCE_SCHEMA, MARKS_SCHEMA
from services.aggregation_service import explain_query_execution
from utils.serializers import success_response, error_response

demo_bp = Blueprint("demo", __name__, url_prefix="/api/demo")

@demo_bp.route("/indexes", methods=["GET"])
def list_indexes():
    """Lists all active MongoDB indexes across collections for viva demonstration."""
    db = get_db()
    try:
        index_report = {}
        for col_name in ["students", "attendance", "marks"]:
            if col_name in db.list_collection_names():
                index_info = db[col_name].index_information()
                index_report[col_name] = [
                    {
                        "name": idx_name,
                        "key": idx_details.get("key"),
                        "unique": idx_details.get("unique", False)
                    }
                    for idx_name, idx_details in index_info.items()
                ]
            else:
                index_report[col_name] = []

        return success_response(
            data=index_report,
            message="Database indexes inspected successfully"
        )
    except Exception as e:
        return error_response(f"Failed to inspect indexes: {str(e)}", status_code=500)

@demo_bp.route("/schemas", methods=["GET"])
def get_schemas():
    """Returns collection JSON schema validation specifications for demonstration."""
    return success_response(
        data={
            "students": STUDENTS_SCHEMA["$jsonSchema"],
            "attendance": ATTENDANCE_SCHEMA["$jsonSchema"],
            "marks": MARKS_SCHEMA["$jsonSchema"]
        },
        message="MongoDB collection schemas retrieved successfully"
    )

@demo_bp.route("/explain", methods=["GET"])
def explain_query():
    """
    Runs explain('executionStats') for college demonstration.
    Demonstrates IXSCAN (indexed query) vs COLLSCAN (unindexed query).
    """
    collection = request.args.get("collection", "students")
    field = request.args.get("field", "student_id")
    value = request.args.get("value", "STU1001")

    query = {field: value}
    try:
        explanation = explain_query_execution(collection, query)
        return success_response(
            data=explanation,
            message="Query execution plan analyzed successfully"
        )
    except Exception as e:
        return error_response(f"Explain query failed: {str(e)}", status_code=400)

@demo_bp.route("/seed", methods=["POST"])
def run_seed():
    """Seeds the database with realistic sample college data."""
    from db.seed_data import seed_database
    try:
        result = seed_database()
        return success_response(data=result, message="Sample college data seeded successfully")
    except Exception as e:
        return error_response(f"Database seeding failed: {str(e)}", status_code=500)
