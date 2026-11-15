"""Routes package for CampusTrack Flask API."""
from .student_routes import student_bp
from .attendance_routes import attendance_bp
from .marks_routes import marks_bp
from .report_routes import report_bp
from .demo_routes import demo_bp
from .auth_routes import auth_bp

__all__ = ["student_bp", "attendance_bp", "marks_bp", "report_bp", "demo_bp", "auth_bp"]
