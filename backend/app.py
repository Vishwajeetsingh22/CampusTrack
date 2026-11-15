import logging
from flask import Flask, jsonify
from flask_cors import CORS
from pymongo.errors import DuplicateKeyError, OperationFailure

from config import Config
from db.connection import check_db_health, init_db
from routes import student_bp, attendance_bp, marks_bp, report_bp, demo_bp, auth_bp
from services.auth_service import seed_default_users
from utils.serializers import error_response, success_response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("campustrack.app")

def create_app(config_class=Config):
    """Application factory for CampusTrack Flask API."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Configure CORS for Flutter development:
    # Allows requests from Flutter Web, Android Studio Emulator (10.0.2.2), iOS simulator, and localhost
    CORS(
        app,
        resources={r"/api/*": {"origins": "*"}},
        supports_credentials=True,
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "Accept"]
    )

    # Register API Blueprints
    app.register_blueprint(student_bp)
    app.register_blueprint(attendance_bp)
    app.register_blueprint(marks_bp)
    app.register_blueprint(report_bp)
    app.register_blueprint(demo_bp)
    app.register_blueprint(auth_bp)

    # Health check endpoint (Required by user)
    @app.route("/health", methods=["GET"])
    @app.route("/api/health", methods=["GET"])
    def health_check():
        """Verifies MongoDB database connectivity and collection statistics."""
        is_healthy, details = check_db_health()
        status_code = 200 if is_healthy else 503
        return jsonify({
            "service": "CampusTrack API",
            "version": "1.0.0",
            "healthy": is_healthy,
            "database_details": details
        }), status_code

    # Top-level Dashboard endpoint (Required by user)
    @app.route("/api/dashboard", methods=["GET"])
    def dashboard_overview():
        """Top-level dashboard metrics endpoint."""
        from services.aggregation_service import get_dashboard_stats
        try:
            stats = get_dashboard_stats()
            return success_response(data=stats, message="Dashboard metrics generated successfully")
        except Exception as e:
            return error_response(f"Failed to generate dashboard metrics: {str(e)}", status_code=500)

    # Root welcome / API discovery endpoint
    @app.route("/", methods=["GET"])
    def root():
        return jsonify({
            "project": "CampusTrack — Student Attendance and Performance Management System",
            "technology_stack": "Flask + PyMongo + MongoDB + Flutter",
            "endpoints": {
                "health": "/health",
                "dashboard": "/api/dashboard",
                "students": "/api/students",
                "attendance": "/api/attendance",
                "attendance_summary": "/api/attendance/summary",
                "marks": "/api/marks",
                "marks_summary": "/api/marks/summary",
                "reports_attendance": "/api/reports/attendance",
                "reports_performance": "/api/reports/performance",
                "reports_low_attendance": "/api/reports/low-attendance",
                "reports_rankings": "/api/reports/rankings",
                "demo_indexes": "/api/demo/indexes",
                "demo_schemas": "/api/demo/schemas",
                "demo_explain": "/api/demo/explain",
                "demo_seed": "/api/demo/seed [POST]",
                "auth_register": "/api/auth/register [POST]",
                "auth_login": "/api/auth/login [POST]",
                "auth_verify_email": "/api/auth/verify-email [POST]",
                "auth_forgot_password": "/api/auth/forgot-password [POST]",
                "auth_reset_password": "/api/auth/reset-password [POST]",
                "auth_me": "/api/auth/me [GET]"
            }
        }), 200

    # Global Error Handlers
    @app.errorhandler(400)
    def handle_bad_request(e):
        return error_response(f"Bad Request: {str(e.description if hasattr(e, 'description') else e)}", status_code=400)

    @app.errorhandler(404)
    def handle_not_found(e):
        return error_response("Endpoint or resource not found.", status_code=404)

    @app.errorhandler(405)
    def handle_method_not_allowed(e):
        return error_response("HTTP method not allowed for this route.", status_code=405)

    @app.errorhandler(DuplicateKeyError)
    def handle_duplicate_key(e):
        logger.warning(f"DuplicateKeyError encountered: {e}")
        return error_response("Duplicate entry: A record with this unique identifier already exists in MongoDB.", status_code=409)

    @app.errorhandler(OperationFailure)
    def handle_mongo_operation_failure(e):
        logger.error(f"MongoDB OperationFailure: {e}")
        if "Document failed validation" in str(e):
            return error_response(
                "Document failed MongoDB $jsonSchema validation rules. Please check data types, required fields, and ranges.",
                status_code=422,
                details=str(e)
            )
        return error_response(f"Database operation failed: {str(e)}", status_code=500)

    @app.errorhandler(500)
    def handle_internal_error(e):
        logger.error(f"Internal Server Error: {e}")
        return error_response("Internal server error. Please check server logs.", status_code=500)

    # Initialize MongoDB schemas, indexes, and demo auth accounts
    with app.app_context():
        try:
            init_db(app)
            seed_default_users()
        except Exception as err:
            logger.warning(f"Initial MongoDB index/schema setup notice: {err}")

    return app

if __name__ == "__main__":
    app = create_app()
    logger.info(f"Starting CampusTrack Flask server on {Config.HOST}:{Config.PORT}...")
    app.run(host=Config.HOST, port=Config.PORT, debug=Config.DEBUG)
