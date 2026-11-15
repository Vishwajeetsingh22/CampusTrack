# CampusTrack — Flask REST API & MongoDB Backend

The backend for **CampusTrack (Student Attendance and Performance Management System)** is built using Python Flask, PyMongo, and MongoDB Community Server. It provides high-performance RESTful APIs backed by native MongoDB aggregation pipelines, collection-level schema validation (`$jsonSchema`), and indexing strategies.

---

## 1. Quick Start & Setup (Windows PowerShell)

```powershell
# Navigate to backend directory
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\backend"

# Activate Python Virtual Environment
.\.venv\Scripts\Activate.ps1

# Install Dependencies
pip install -r requirements.txt

# Run Unit & Integration Tests (100% Passing)
python test_api_endpoints.py

# Re-seed Database with Realistic College Sample Data
python -m db.seed_data --reset

# Start the Flask API Server (port 5000)
python app.py
```

---

## 2. Environment Configuration (`.env`)

```ini
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=1
PORT=5000

# MongoDB Configuration
MONGO_URI=mongodb://localhost:27017/
MONGO_DB_NAME=campustrack
```

---

## 3. MongoDB Schema & Indexing Strategy

### Collections
1. **`students`**
   - **Fields**: `student_id`, `name`, `course`, `department`, `semester`, `email`, `active`, `phone`, `created_at`, `updated_at`.
   - **Indexes**:
     - `student_id`: Unique index (`{"student_id": 1}, unique=True`).
     - `course`: Secondary index for course-wise queries.
     - `active`: Secondary index for enrolled student filtering.
   - **Validation**: Enforces email regex, semester range ($1 \le \text{semester} \le 8$), and required fields.

2. **`attendance`**
   - **Fields**: `student_id`, `date` (YYYY-MM-DD), `subject`, `status` (`Present`, `Absent`, `Late`), `remarks`, `created_at`, `updated_at`.
   - **Compound Index**: `{"student_id": 1, "date": 1, "subject": 1}` with `unique=True` (strictly prevents duplicate attendance on the same day for a subject).

3. **`marks`**
   - **Fields**: `student_id`, `subject`, `exam`, `marks_obtained`, `max_marks`, `percentage`, `created_at`, `updated_at`.
   - **Compound Index**: `{"student_id": 1, "subject": 1, "exam": 1}` with `unique=True` (strictly prevents duplicate marks for the same assessment).
   - **Validation**: Enforces $0 \le \text{marks\_obtained} \le \text{max\_marks}$ and $\text{max\_marks} \ge 1$.

---

## 4. REST API Endpoint Reference

### System & Health

#### `GET /health`
Verifies database ping and reports collection statistics.
- **Response `200 OK`**:
```json
{
  "healthy": true,
  "service": "CampusTrack API",
  "version": "1.0.0",
  "database_details": {
    "status": "healthy",
    "connected": true,
    "database": "campustrack",
    "collections": {
      "students": 12,
      "attendance": 120,
      "marks": 96
    }
  }
}
```

---

### Dashboard

#### `GET /api/dashboard`
Returns high-level statistics and distribution arrays for charts.
- **Response `200 OK`**:
```json
{
  "success": true,
  "message": "Dashboard metrics generated successfully",
  "data": {
    "total_students": 12,
    "active_students": 11,
    "overall_attendance_pct": 87.5,
    "avg_marks_pct": 78.19,
    "low_attendance_count": 2,
    "total_attendance_records": 120,
    "total_marks_records": 96,
    "course_distribution": [
      { "course": "Computer Science", "count": 6 },
      { "course": "Information Technology", "count": 4 },
      { "course": "Electronics", "count": 2 }
    ],
    "status_breakdown": [
      { "status": "Present", "count": 104 },
      { "status": "Absent", "count": 14 },
      { "status": "Late", "count": 2 }
    ]
  }
}
```

---

### Students Module

#### `GET /api/students`
List and search students with filters and pagination.
- **Query Parameters**:
  - `search` (string): Search in `name`, `student_id`, `email`, `course`.
  - `course` (string): Filter by course (e.g. `Computer Science`).
  - `semester` (int): Filter by semester number ($1-8$).
  - `active` (bool): `true` or `false`.
  - `page` (int): Page number (starts at 1).
  - `limit` (int): Number of items per page (default 100).
- **Response `200 OK`**:
```json
{
  "success": true,
  "count": 1,
  "total": 12,
  "page": 1,
  "limit": 100,
  "data": [
    {
      "id": "671ad000...",
      "student_id": "STU1001",
      "name": "Aarav Sharma",
      "course": "Computer Science",
      "department": "Computer Science",
      "semester": 6,
      "email": "aarav.sharma@campus.edu",
      "active": true,
      "phone": "+91-9876543210",
      "created_at": "2026-10-25T02:40:00Z",
      "updated_at": "2026-10-25T02:40:00Z"
    }
  ]
}
```

#### `GET /api/students/<id>`
Retrieve one student by `student_id` (e.g. `STU1001`) or MongoDB `ObjectId`.
- **Response `200 OK`**:
```json
{
  "success": true,
  "data": {
    "student_id": "STU1001",
    "name": "Aarav Sharma",
    "course": "Computer Science",
    "semester": 6,
    "email": "aarav.sharma@campus.edu",
    "active": true
  }
}
```

#### `POST /api/students`
Create a new student.
- **Request Body**:
```json
{
  "student_id": "STU2001",
  "name": "Rajesh Kumar",
  "course": "Computer Science",
  "semester": 4,
  "email": "rajesh.kumar@campus.edu",
  "active": true,
  "phone": "+91-9876543299"
}
```
- **Response `201 Created`**:
```json
{
  "success": true,
  "message": "Student registered successfully",
  "data": {
    "student_id": "STU2001",
    "name": "Rajesh Kumar",
    "course": "Computer Science",
    "semester": 4,
    "email": "rajesh.kumar@campus.edu",
    "active": true,
    "created_at": "2026-10-25T02:45:00Z",
    "updated_at": "2026-10-25T02:45:00Z"
  }
}
```

#### `PUT /api/students/<id>`
Update student details.
- **Request Body**:
```json
{
  "name": "Rajesh K.",
  "semester": 5,
  "active": true
}
```
- **Response `200 OK`**:
```json
{
  "success": true,
  "message": "Student updated successfully",
  "data": { "student_id": "STU2001", "name": "Rajesh K.", "semester": 5 }
}
```

#### `DELETE /api/students/<id>`
Safely deletes student and cascades removal of related attendance and marks records to prevent orphaned documents.
- **Response `200 OK`**:
```json
{
  "success": true,
  "message": "Student and related records deleted successfully",
  "data": {
    "deleted_student_id": "STU2001",
    "cascade_deleted": {
      "attendance_records": 10,
      "marks_records": 8
    }
  }
}
```

---

### Attendance Module

#### `GET /api/attendance`
List attendance records with filters and resolved student information.
- **Query Parameters**: `student_id`, `date`, `subject`, `status`, `page`, `limit`.
- **Response `200 OK`**:
```json
{
  "success": true,
  "total": 120,
  "count": 1,
  "data": [
    {
      "id": "671ad000...",
      "student_id": "STU1001",
      "student_name": "Aarav Sharma",
      "course": "Computer Science",
      "date": "2026-10-24",
      "subject": "NoSQL Databases",
      "status": "Present",
      "remarks": "On time",
      "created_at": "2026-10-25T02:40:00Z"
    }
  ]
}
```

#### `POST /api/attendance`
Record attendance for a student. Prevents duplicate records for the same student, date, and subject.
- **Request Body**:
```json
{
  "student_id": "STU1001",
  "date": "2026-10-25",
  "subject": "Cloud Computing",
  "status": "Present",
  "remarks": "On time"
}
```
- **Response `201 Created`**:
```json
{
  "success": true,
  "message": "Attendance recorded successfully",
  "data": {
    "student_id": "STU1001",
    "date": "2026-10-25",
    "subject": "Cloud Computing",
    "status": "Present"
  }
}
```
*(If already recorded on that date and subject, returns `409 Conflict`)*.

#### `GET /api/attendance/summary`
Calculates aggregated attendance statistics using MongoDB aggregation pipelines.
- **Query Parameters**: `student_id` (optional), `subject` (optional), `date` (optional).
- **Response `200 OK`**:
```json
{
  "success": true,
  "message": "Attendance summary computed successfully",
  "data": {
    "total_classes": 120,
    "present_count": 104,
    "absent_count": 14,
    "late_count": 2,
    "attendance_percentage": 87.5,
    "subject_breakdown": [
      {
        "subject": "Cloud Computing",
        "total": 60,
        "present": 52,
        "absent": 7,
        "late": 1,
        "percentage": 87.5
      }
    ]
  }
}
```

#### `PUT /api/attendance/<id>`
Update status or remarks of an attendance record by ObjectId.
- **Request Body**: `{ "status": "Late", "remarks": "Bus delay" }`
- **Response `200 OK`**.

#### `DELETE /api/attendance/<id>`
Delete an attendance entry by ObjectId.
- **Response `200 OK`**.

---

### Marks Module

#### `GET /api/marks`
List marks entries with resolved student profiles.
- **Query Parameters**: `student_id`, `subject`, `exam`, `page`, `limit`.
- **Response `200 OK`**:
```json
{
  "success": true,
  "total": 96,
  "data": [
    {
      "id": "671ad000...",
      "student_id": "STU1001",
      "student_name": "Aarav Sharma",
      "course": "Computer Science",
      "subject": "NoSQL Databases",
      "exam": "Final",
      "marks_obtained": 92.0,
      "max_marks": 100.0,
      "percentage": 92.0,
      "created_at": "2026-10-25T02:40:00Z"
    }
  ]
}
```

#### `POST /api/marks`
Add exam marks. Automatically computes percentage and requires $0 \le \text{marks\_obtained} \le \text{max\_marks}$.
- **Request Body**:
```json
{
  "student_id": "STU1001",
  "subject": "Mobile App Dev",
  "exam": "Mid-Term",
  "marks_obtained": 46.0,
  "max_marks": 50.0
}
```
- **Response `201 Created`**:
```json
{
  "success": true,
  "message": "Marks recorded and percentage calculated successfully",
  "data": {
    "student_id": "STU1001",
    "subject": "Mobile App Dev",
    "exam": "Mid-Term",
    "marks_obtained": 46.0,
    "max_marks": 50.0,
    "percentage": 92.0
  }
}
```
*(If `marks_obtained > max_marks`, returns `400 Bad Request`)*.

#### `GET /api/marks/summary`
Calculates cumulative marks statistics using MongoDB aggregation pipelines.
- **Query Parameters**: `student_id` (optional), `subject` (optional), `exam` (optional).
- **Response `200 OK`**:
```json
{
  "success": true,
  "data": {
    "total_records": 96,
    "avg_percentage": 78.19,
    "max_percentage": 95.0,
    "min_percentage": 48.0,
    "subject_breakdown": [
      {
        "subject": "NoSQL Databases",
        "assessments_count": 24,
        "avg_percentage": 78.17,
        "max_percentage": 94.0,
        "min_percentage": 52.0
      }
    ]
  }
}
```

#### `PUT /api/marks/<id>`
Update score or max marks and automatically recompute percentage.
- **Request Body**: `{ "marks_obtained": 48.0 }`
- **Response `200 OK`**.

#### `DELETE /api/marks/<id>`
Delete a marks entry by ObjectId.
- **Response `200 OK`**.

---

### Dashboard and Reports Module

#### `GET /api/reports/attendance`
Student-by-student attendance percentage report.
- **Query Parameters**: `course`, `semester`.
- **Response `200 OK`**:
```json
{
  "success": true,
  "count": 12,
  "data": [
    {
      "student_id": "STU1001",
      "name": "Aarav Sharma",
      "course": "Computer Science",
      "semester": 6,
      "total_classes": 10,
      "present_count": 10,
      "absent_count": 0,
      "late_count": 0,
      "attendance_pct": 100.0,
      "status": "Normal"
    }
  ]
}
```

#### `GET /api/reports/performance`
Subject-wise analytics (average score, highest score, pass percentage).
- **Query Parameters**: `course`, `exam`.
- **Response `200 OK`**:
```json
{
  "success": true,
  "data": {
    "subjects": [
      {
        "subject": "NoSQL Databases",
        "student_count": 24,
        "pass_count": 24,
        "pass_percentage": 100.0,
        "avg_percentage": 78.17,
        "max_percentage": 94.0,
        "min_percentage": 52.0
      }
    ],
    "overall_summary": {
      "overall_avg": 78.19,
      "highest_score": 95.0,
      "lowest_score": 48.0,
      "total_assessments": 96
    }
  }
}
```

#### `GET /api/reports/low-attendance`
Students below attendance threshold (defaulter list).
- **Query Parameters**: `threshold` (default `75.0`).
- **Response `200 OK`**:
```json
{
  "success": true,
  "threshold": 75.0,
  "count": 2,
  "data": [
    {
      "student_id": "STU1004",
      "name": "Ananya Sen",
      "course": "Computer Science",
      "semester": 6,
      "total_classes": 10,
      "attendance_pct": 20.0,
      "shortfall": 55.0,
      "email": "ananya.sen@campus.edu",
      "phone": "+91-9876543213"
    },
    {
      "student_id": "STU1007",
      "name": "Karan Verma",
      "course": "Information Technology",
      "semester": 6,
      "total_classes": 10,
      "attendance_pct": 40.0,
      "shortfall": 35.0,
      "email": "karan.verma@campus.edu",
      "phone": "+91-9876543216"
    }
  ]
}
```

#### `GET /api/reports/rankings`
Student academic leaderboard dynamically ranked by overall percentage.
- **Query Parameters**: `course`, `semester`.
- **Response `200 OK`**:
```json
{
  "success": true,
  "count": 12,
  "data": [
    {
      "rank": 1,
      "student_id": "STU1006",
      "name": "Sneha Reddy",
      "course": "Information Technology",
      "semester": 6,
      "avg_percentage": 91.75
    },
    {
      "rank": 2,
      "student_id": "STU1001",
      "name": "Aarav Sharma",
      "course": "Computer Science",
      "semester": 6,
      "avg_percentage": 91.25
    }
  ]
}
```

---

### MongoDB Demonstration / Viva Endpoints

- `GET /api/demo/indexes` — Lists active single & compound indexes.
- `GET /api/demo/schemas` — Returns MongoDB collection `$jsonSchema` validators.
- `GET /api/demo/explain?collection=students&field=student_id&value=STU1001` — Runs `.explain("executionStats")` demonstrating `IXSCAN` index usage.
- `POST /api/demo/seed` — Resets or re-seeds sample college data on demand.
