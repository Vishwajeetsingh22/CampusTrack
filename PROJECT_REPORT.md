# CampusTrack — Student Attendance and Performance Management System
## Final Project Report

---

### [COVER PAGE / TITLE PAGE]

```text
========================================================================================
                                     PROJECT REPORT
                                           ON
              CAMPUSTRACK: STUDENT ATTENDANCE AND PERFORMANCE MANAGEMENT SYSTEM
                          USING FLUTTER, FLASK, AND MONGODB
========================================================================================

                 Submitted in partial fulfillment of the requirements for
                             the award of the degree of
                     [BACHELOR OF TECHNOLOGY / MASTER OF COMPUTER APPLICATIONS]
                                           IN
                       [COMPUTER SCIENCE AND ENGINEERING / INFORMATION TECHNOLOGY]

                                      SUBMITTED BY:
                       [Student Name 1]        (Roll No / USN: [Roll-01])
                       [Student Name 2]        (Roll No / USN: [Roll-02])

                               UNDER THE GUIDANCE OF:
                                [Guide / Faculty Name]
                                    [Designation]
               Department of Computer Science and Engineering / Information Technology

                                [COLLEGE / UNIVERSITY NAME]
                             [Campus Address, City, State, PIN]
                                    ACADEMIC YEAR: 2026–2027
========================================================================================
```

---

## Table of Contents
1. [Abstract](#1-abstract)
2. [Introduction and Problem Statement](#2-introduction-and-problem-statement)
3. [Objectives and Scope](#3-objectives-and-scope)
4. [Software and Hardware Requirements](#4-software-and-hardware-requirements)
5. [System Architecture and Data Flow](#5-system-architecture-and-data-flow)
6. [Database Design and Collection Schemas](#6-database-design-and-collection-schemas)
7. [MongoDB Indexes and Schema Validation](#7-mongodb-indexes-and-schema-validation)
8. [Flutter Frontend and Flask API Implementation](#8-flutter-frontend-and-flask-api-implementation)
9. [CRUD Operations and Aggregation Pipelines](#9-crud-operations-and-aggregation-pipelines)
10. [Testing Methodology and Actual Results](#10-testing-methodology-and-actual-results)
11. [Screenshots Guide (App & MongoDB Compass)](#11-screenshots-guide-app--mongodb-compass)
12. [Limitations and Future Enhancements](#12-limitations-and-future-enhancements)
13. [Conclusion and References](#13-conclusion-and-references)

---

## 1. Abstract

Academic institutions require reliable, scalable, and responsive administrative systems to record daily classroom attendance, track continuous internal assessments, and generate actionable institutional analytics. Traditional paper registers and rigid relational database systems often suffer from relational impedance mismatch, administrative bottlenecks, lack of real-time insights, and slow reporting when complex statistical aggregations are required across thousands of student records.

**CampusTrack** is an end-to-end, multi-tier academic management software built using a modern decoupled architecture:
- **Presentation Layer**: Built with **Flutter (Dart)**, delivering a reactive, Material 3 administrative user interface capable of running across mobile, desktop, and web environments.
- **Application Services Layer**: Powered by a lightweight **Python Flask REST API**, implementing modular blueprinted controllers, centralized JSON serialization, and robust input validation.
- **Data Persistence Layer**: Implemented using **MongoDB Community Server (NoSQL)**, leveraging document-oriented data models, BSON schema validation rules (`$jsonSchema`), compound unique indexes, and high-performance MongoDB aggregation pipelines.

The system introduces strict duplicate prevention mechanisms at both application and database engine tiers, dynamic zero-division safeguards during mathematical aggregations, correlated `$lookup` subqueries to prevent Cartesian product double-counting, and real-time visualization of student performance via interactive bar and pie charts. Automated verification via comprehensive test suites demonstrates 100% test passing rates across API contracts, schema validations, and mathematical calculations.

---

## 2. Introduction and Problem Statement

### 2.1 Background
Monitoring student attendance and academic performance is a mandatory operational responsibility for colleges and universities. Attendance percentages often determine examination eligibility (typically requiring an attendance threshold of at least 75%), while assessment grades guide early remedial interventions for struggling students.

### 2.2 Existing System Limitations
Traditional collegiate record-keeping systems exhibit multiple critical shortcomings:
1. **Manual Registers & Disconnected Spreadsheets**: Physical registers are susceptible to wear, loss, human tallying errors, and unauthorized alterations.
2. **Relational Schema Rigidity**: Relational databases (RDBMS) enforce static, tabular structures. Altering exam grading rubrics, adding flexible student contact parameters, or recording ad-hoc remarks requires complex database migrations (`ALTER TABLE`).
3. **Severe Join Latencies for Analytics**: Generating institutional rankings or defaulter reports in relational systems requires expensive multi-table `JOIN` operations across millions of historical log rows.
4. **Poor Mobile Responsiveness**: Conventional enterprise portals are tailored strictly for desktop browsers, preventing faculty from marking attendance or viewing metrics on mobile devices during lectures.

### 2.3 Proposed Solution
CampusTrack resolves these challenges through a document-oriented NoSQL architecture:
- Flexible BSON documents capture student details, daily attendance entries, and assessment marks without schema overhead.
- Native server-side MongoDB aggregation pipelines (`$group`, `$project`, `$sort`, `$lookup`) calculate institutional KPIs in single database roundtrips.
- Cross-platform Flutter client offers real-time UI updates, offline-resilient feedback, and interactive visual charts (`fl_chart`).

---

## 3. Objectives and Scope

### 3.1 Primary Objectives
1. **Student Record Management**: Complete CRUD operations for student profiles, enforcing unique roll numbers and formatted emails.
2. **Daily Attendance Logging**: Track session attendance with three distinct statuses: `Present`, `Absent`, and `Late`, preventing accidental duplicate records for the same student, subject, and date.
3. **Assessment & Marks Recording**: Record continuous evaluation scores with strict numeric boundary validation ($0 \le \text{marks\_obtained} \le \text{max\_marks}$).
4. **Real-Time Analytics & Aggregations**:
   - Compute student-wise cumulative attendance percentages.
   - Identify defaulters falling below the mandatory **75.0%** threshold.
   - Compute subject-wise pass rates, minimum, maximum, and average marks.
   - Generate automated rank lists sorted in descending order of cumulative score.
5. **NoSQL Database Demonstration**: Implement and verify MongoDB collections, `$jsonSchema` validators, index performance optimizations, and multi-stage aggregation pipelines.

### 3.2 Scope
- **Target Audience**: College department heads, faculty members, academic administrators, and examination coordinators.
- **Deployment Scope**: Local development and on-premise institutional networks (LAN / Wi-Fi) with support for mobile emulators and physical devices.

---

## 4. Software and Hardware Requirements

### 4.1 Hardware Requirements
- **Processor**: Intel Core i5 / AMD Ryzen 5 or higher (64-bit multi-core).
- **RAM**: Minimum 8 GB (16 GB recommended for concurrent Android Studio emulator and IDE operation).
- **Storage**: Minimum 20 GB free disk space (SSD recommended).
- **Network Interface**: 802.11ac Wi-Fi or Gigabit Ethernet adapter (for LAN device communication).

### 4.2 Software Requirements
- **Operating System**: Windows 11 (64-bit) / macOS / Ubuntu Linux.
- **Database Engine**: MongoDB Community Server v7.0 or v8.0.
- **Database GUI**: MongoDB Compass v1.40+.
- **Database Driver**: PyMongo v4.6+.
- **Backend Runtime**: Python 3.10, 3.11, or 3.12 (virtual environment enabled).
- **Backend Framework**: Flask v3.0+, Flask-CORS v4.0+, python-dotenv.
- **Frontend SDK**: Flutter SDK v3.24+ / v3.33+ with Dart SDK v3.5+.
- **Frontend Charting**: `fl_chart` v0.68+.
- **State Management**: `provider` v6.1+.
- **Development Tools**: Visual Studio Code / Google Antigravity / Android Studio.

---

## 5. System Architecture and Data Flow

### 5.1 Three-Tier Architecture
CampusTrack adopts a decoupled, modern three-tier client-server architecture:

```
+-----------------------------------------------------------------------------------+
|                            PRESENTATION TIER (CLIENT)                             |
|                           Flutter Framework & Dart SDK                            |
|  +------------------------+  +------------------------+  +---------------------+  |
|  | Dashboard & KPI Screen |  | Student Management     |  | Attendance & Marks  |  |
|  | (fl_chart Bar/Pie)     |  | (Search, Form, Detail) |  | (Forms & History)   |  |
|  +------------------------+  +------------------------+  +---------------------+  |
|                            ^                           ^                          |
|                            | Provider State Management |                          |
|                            v                           v                          |
|             +-------------------------------------------------------+             |
|             |          CampusTrack Centralized ApiService           |             |
|             |    (JSON over HTTP REST Client - ApiConfig.baseUrl)   |             |
+-------------+---------------------------+---------------------------+-------------+
                                          |
                              JSON / HTTP (REST API)
                                          |
+-----------------------------------------v-----------------------------------------+
|                        APPLICATION SERVICES TIER (BACKEND)                        |
|                                Python Flask REST API                              |
|  +-----------------------------------------------------------------------------+  |
|  | Flask Blueprints: /api/students | /api/attendance | /api/marks | /reports   |  |
|  +-----------------------------------------------------------------------------+  |
|  | Business Logic Services: student_service | attendance_service | aggregation |  |
|  +-----------------------------------------------------------------------------+  |
|  | Cross-Origin Resource Sharing (CORS) & Global JSON Serializer Exception Trap |  |
+-----------------------------------------+-----------------------------------------+
                                          |
                              BSON / TCP (PyMongo Pool)
                                          |
+-----------------------------------------v-----------------------------------------+
|                          DATA PERSISTENCE TIER (DATABASE)                         |
|                               MongoDB Community Server                            |
|  +--------------------+   +---------------------+   +--------------------------+  |
|  | Collection:        |   | Collection:         |   | Collection:              |  |
|  | 'students'         |   | 'attendance'        |   | 'marks'                  |  |
|  +--------------------+   +---------------------+   +--------------------------+  |
|  | Unique Index:      |   | Compound Unique:    |   | Compound Unique:         |  |
|  | student_id (asc)   |   | (student_id, date,  |   | (student_id, subject,    |  |
|  |                    |   |  subject)           |   |  exam)                   |  |
|  +--------------------+   +---------------------+   +--------------------------+  |
|  | $jsonSchema Rules  |   | $jsonSchema Rules   |   | $jsonSchema Rules        |  |
+-----------------------+---+---------------------+---+--------------------------+--+
```

### 5.2 Key Data Flows
1. **Attendance Marking Flow**:
   - Faculty selects Student, Subject, Session Date, and Status (`Present`, `Absent`, `Late`).
   - Request is dispatched via `POST /api/attendance` as a JSON payload.
   - Flask validates field types and checks student existence in `students`.
   - MongoDB evaluates compound unique index `idx_attendance_unique_entry`.
   - If a duplicate entry exists for `(student_id, date, subject)`, MongoDB raises a `DuplicateKeyError` and Flask responds with `HTTP 409 Conflict`.
   - Otherwise, the document is written to `attendance`, and an `HTTP 201 Created` is returned.
2. **Defaulter & Ranking Calculation Flow**:
   - User navigates to Reports Screen in Flutter.
   - Flutter invokes `GET /api/reports/low-attendance?threshold=75.0` and `GET /api/reports/rankings`.
   - Flask initiates server-side MongoDB aggregation pipelines.
   - Database groups attendance records, computes percentage with zero-division protection, filters defaulters, joins student profiles via `$lookup`, and returns aggregated data.

---

## 6. Database Design and Collection Schemas

### 6.1 Database Choice: Document NoSQL vs. Relational RDBMS
| Feature | Relational Database (MySQL / PostgreSQL) | MongoDB Document Model (CampusTrack) |
| :--- | :--- | :--- |
| **Data Format** | Strict rows and fixed columns | Flexible, hierarchical BSON documents |
| **Impedance Mismatch** | Requires Object-Relational Mapping (ORM) | Direct 1:1 mapping with Dart / Python dictionaries |
| **Schema Evolution** | Requires locking tables via `ALTER TABLE` | Add optional fields (`remarks`, `phone`) without downtime |
| **Complex Aggregations** | Multi-table joins become sluggish under load | Native aggregation pipeline executes within memory engine |
| **Indexing** | B-Tree indexes on single/multiple columns | B-Tree indexes, compound unique indexes, express scans |

### 6.2 Collections and Document Specifications

#### 1. Collection: `students`
Stores master demographic and enrollment data for all registered students.

| Field Name | BSON Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `_id` | `ObjectId` | Primary Key, Auto-generated | Internal MongoDB unique document identifier |
| `student_id` | `string` | Unique Index, Pattern: `^[A-Za-z0-9_-]{3,20}$` | College Roll Number / USN (e.g., `STU1001`) |
| `name` | `string` | Required, Length: 2–100 chars | Full legal student name |
| `email` | `string` | Required, Valid email regex | Official student communication email |
| `course` | `string` | Required, Length: 2–100 chars | Degree / Program (e.g. `Computer Science`) |
| `semester` | `int` | Required, Range: 1 to 8 | Current academic semester number |
| `active` | `bool` | Required | Enrollment status flag (`true`/`false`) |
| `phone` | `string` | Optional | Student or guardian phone number |
| `created_at` | `date` | System timestamp | UTC enrollment timestamp |
| `updated_at` | `date` | System timestamp | UTC last modification timestamp |

#### 2. Collection: `attendance`
Stores atomic session-by-session attendance logs.

| Field Name | BSON Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `_id` | `ObjectId` | Primary Key, Auto-generated | Internal log identifier |
| `student_id` | `string` | Required, References `students.student_id` | Student roll number |
| `date` | `string` | Required, Pattern: `^\d{4}-\d{2}-\d{2}$` | ISO date of session (`YYYY-MM-DD`) |
| `subject` | `string` | Required, Length: 2–100 chars | Course / Subject title |
| `status` | `string` | Required, Enum: `['Present', 'Absent', 'Late']` | Session attendance status |
| `remarks` | `string` | Optional, Max 200 chars | Optional attendance notes |
| `created_at` | `date` | System timestamp | UTC creation timestamp |

#### 3. Collection: `marks`
Stores internal examination and continuous evaluation scores.

| Field Name | BSON Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `_id` | `ObjectId` | Primary Key, Auto-generated | Internal marks document identifier |
| `student_id` | `string` | Required, References `students.student_id` | Student roll number |
| `subject` | `string` | Required, Length: 2–100 chars | Subject title |
| `exam` | `string` | Required, Length: 2–100 chars | Assessment name (e.g., `Mid-Term Exam`) |
| `marks_obtained` | `double` | Required, $\ge 0.0$ and $\le \text{max\_marks}$ | Score obtained by student |
| `max_marks` | `double` | Required, $> 0.0$ | Maximum score possible for the assessment |
| `percentage` | `double` | Calculated: `(obtained / max) * 100` | Percentage score rounded to 2 decimals |
| `created_at` | `date` | System timestamp | UTC creation timestamp |

---

## 7. MongoDB Indexes and Schema Validation

### 7.1 Schema Validation via `$jsonSchema`
MongoDB enforces structural integrity at the persistence level through declarative `$jsonSchema` validators. Documents violating types, boundaries, or mandatory fields are rejected with an `OperationFailure` (HTTP 422).

```javascript
// Students Collection Schema Validator
db.createCollection("students", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["student_id", "name", "email", "course", "semester", "active"],
      properties: {
        student_id: {
          bsonType: "string",
          pattern: "^[A-Za-z0-9_-]{3,20}$",
          description: "Unique student roll number - required"
        },
        name: { bsonType: "string", minLength: 2, maxLength: 100 },
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$"
        },
        course: { bsonType: "string", minLength: 2, maxLength: 100 },
        semester: { bsonType: "int", minimum: 1, maximum: 8 },
        active: { bsonType: "bool" }
      }
    }
  }
});
```

### 7.2 Unique and Compound Indexes
To prevent duplicate records and optimize search queries, CampusTrack configures specialized B-Tree indexes:

1. **`students` Unique Identifier Index**:
   ```javascript
   db.students.createIndex({ student_id: 1 }, { unique: true, name: "idx_students_student_id_unique" });
   ```
2. **`attendance` Compound Session Index**:
   ```javascript
   db.attendance.createIndex(
     { student_id: 1, date: 1, subject: 1 },
     { unique: true, name: "idx_attendance_unique_entry" }
   );
   ```
   *Guarantees no student can be marked more than once for the same subject on any given date.*
3. **`marks` Compound Assessment Index**:
   ```javascript
   db.marks.createIndex(
     { student_id: 1, subject: 1, exam: 1 },
     { unique: true, name: "idx_marks_unique_entry" }
   );
   ```

### 7.3 Explain Plan Verification
Query execution plans verified via `explain("executionStats")` confirm that targeted student lookups utilize the index rather than expensive collection scans:
- **Winning Plan Stage**: `EXPRESS_IXSCAN` / `IXSCAN`
- **Total Keys Examined**: 1
- **Total Documents Examined**: 1
- **Execution Time**: ~0 ms

---

## 8. Flutter Frontend and Flask API Implementation

### 8.1 REST API Endpoint Catalog
| Method | Endpoint | Description | Expected Status Codes |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | Server and database connectivity check | `200 OK`, `503 Unavailable` |
| `GET` | `/api/dashboard` | Aggregated institutional KPI statistics | `200 OK`, `500 Server Error` |
| `GET` | `/api/students` | Search and filter enrolled students | `200 OK` |
| `POST` | `/api/students` | Register new student profile | `201 Created`, `400 Bad Request`, `409 Conflict` |
| `GET` | `/api/students/<id>` | Retrieve single student by ID | `200 OK`, `404 Not Found` |
| `PUT` | `/api/students/<id>` | Update student profile | `200 OK`, `400 Bad Request`, `404 Not Found` |
| `DELETE`| `/api/students/<id>` | Delete student and cascade cleanup | `200 OK`, `404 Not Found` |
| `GET` | `/api/attendance` | Query attendance logs with filters | `200 OK` |
| `POST` | `/api/attendance` | Log daily attendance | `201 Created`, `400 Bad Request`, `409 Conflict` |
| `PUT` | `/api/attendance/<id>`| Update status or remarks of a log | `200 OK`, `400 Bad Request`, `404 Not Found` |
| `DELETE`| `/api/attendance/<id>`| Delete attendance log | `200 OK`, `404 Not Found` |
| `GET` | `/api/marks` | Query examination marks records | `200 OK` |
| `POST` | `/api/marks` | Record assessment marks | `201 Created`, `400 Bad Request`, `409 Conflict` |
| `PUT` | `/api/marks/<id>` | Update assessment score | `200 OK`, `400 Bad Request`, `404 Not Found` |
| `DELETE`| `/api/marks/<id>` | Delete assessment entry | `200 OK`, `404 Not Found` |
| `GET` | `/api/reports/attendance` | Student-wise attendance percentage report | `200 OK` |
| `GET` | `/api/reports/performance` | Subject-wise academic performance metrics | `200 OK` |
| `GET` | `/api/reports/low-attendance` | Students with attendance $< 75.0\%$ | `200 OK` |
| `GET` | `/api/reports/rankings` | Student ranking by cumulative score | `200 OK` |
| `GET` | `/api/reports/subject-attendance` | Subject-wise attendance distribution | `200 OK` |
| `GET` | `/api/reports/unified` | 360-degree student analytics | `200 OK` |

### 8.2 Frontend Architecture
The Flutter frontend is engineered following a clean separation of concerns:
- **`config/`**: Centralized theme palette ([app_theme.dart](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/config/app_theme.dart)) and environment-aware API URL resolution ([api_config.dart](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/config/api_config.dart)).
- **`models/`**: Strongly-typed Dart data classes equipped with null-safe `fromJson` factory methods and `toJson` serializers.
- **`services/`**: Centralized HTTP client services (`student_service`, `attendance_service`, `marks_service`, `report_service`) handling network timeouts and error decoding.
- **`providers/`**: State management extending Flutter's `ChangeNotifier`, providing responsive state notifications (`isLoading`, `errorMessage`, `records`).
- **`screens/`**: Clean modular views with loading skeletons, interactive charts, filtering chips, and floating action buttons.
- **`widgets/`**: Reusable UI components including [StatKpiCard](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/widgets/stat_kpi_card.dart), [EmptyStateView](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/widgets/empty_state_view.dart), [ErrorStateView](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/widgets/error_state_view.dart), and [LoadingIndicator](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/widgets/loading_indicator.dart).

---

## 9. CRUD Operations and Aggregation Pipelines

### 9.1 CRUD Operations Overview
1. **Create (Insert)**:
   - Evaluates client payload against business logic validators.
   - Enforces MongoDB unique indexes and `$jsonSchema` validation rules.
   - Generates standardized JSON responses (`201 Created`).
2. **Read (Query)**:
   - Supports multi-attribute case-insensitive substring regex matching (`$regex`).
   - Supports structured filtering by course, semester, date, and status.
   - Implements server-side skip/limit pagination (`total`, `count`, `page`, `limit`).
3. **Update (Modify)**:
   - Validates existence of the record by `student_id` or `ObjectId`.
   - Uses atomic `$set` updates to modify specific properties without full document replacement.
   - Automatically recalculates dynamic scores (such as marks percentage).
4. **Delete (Remove)**:
   - Safe removal with relational cascade handling: deleting a student automatically purges their historical attendance and marks records, preventing orphan documents.

### 9.2 Real-World Aggregation Pipelines

#### Pipeline 1: Student-Wise Cumulative Attendance Percentage
* **Objective**: Aggregate all session logs per student and compute attendance percentage where `Present = 1.0` and `Late = 0.5`.
* **Mathematical Formula**:
  $$\text{Attendance \%} = \frac{\text{Present Count} + 0.5 \times \text{Late Count}}{\text{Total Sessions}} \times 100$$
* **Zero-Division Protection**: Uses `$cond` to verify $\text{Total Sessions} > 0$, returning `0.0` for new students.
* **Pipeline Implementation**:
  ```javascript
  db.attendance.aggregate([
    {
      $group: {
        _id: "$student_id",
        total_classes: { $sum: 1 },
        present_count: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } },
        absent_count: { $sum: { $cond: [{ $eq: ["$status", "Absent"] }, 1, 0] } },
        late_count: { $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] } }
      }
    },
    {
      $project: {
        student_id: "$_id",
        total_classes: 1,
        present_count: 1,
        absent_count: 1,
        late_count: 1,
        attendance_pct: {
          $cond: [
            { $gt: ["$total_classes", 0] },
            {
              $round: [
                {
                  $multiply: [
                    {
                      $divide: [
                        { $add: ["$present_count", { $multiply: ["$late_count", 0.5] }] },
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
      $lookup: {
        from: "students",
        localField: "student_id",
        foreignField: "student_id",
        as: "student"
      }
    },
    { $unwind: { path: "$student", preserveNullAndEmptyArrays: true } },
    { $sort: { attendance_pct: -1 } }
  ]);
  ```

#### Pipeline 2: Low-Attendance Defaulters Identification ($< 75\%$)
* **Objective**: Filter all students falling below the institutional mandatory 75% threshold and compute attendance shortfall.
* **Pipeline Implementation**:
  Append a `$match` stage following Pipeline 1:
  ```javascript
  {
    $match: {
      attendance_pct: { $lt: 75.0 }
    }
  },
  {
    $project: {
      student_id: 1,
      name: "$student.name",
      course: "$student.course",
      attendance_pct: 1,
      shortfall: { $round: [{ $subtract: [75.0, "$attendance_pct"] }, 2] }
    }
  }
  ```

#### Pipeline 3: Subject-Wise Performance & Grade Analytics
* **Objective**: Compute student count, pass rate, average, highest, and lowest score per academic subject.
* **Pipeline Implementation**:
  ```javascript
  db.marks.aggregate([
    {
      $group: {
        _id: "$subject",
        student_count: { $sum: 1 },
        pass_count: { $sum: { $cond: [{ $gte: ["$percentage", 50.0] }, 1, 0] } },
        avg_percentage: { $avg: "$percentage" },
        max_percentage: { $max: "$percentage" },
        min_percentage: { $min: "$percentage" }
      }
    },
    {
      $project: {
        subject: "$_id",
        student_count: 1,
        pass_count: 1,
        pass_percentage: {
          $round: [{ $multiply: [{ $divide: ["$pass_count", "$student_count"] }, 100] }, 2]
        },
        avg_percentage: { $round: ["$avg_percentage", 2] },
        max_percentage: { $round: ["$max_percentage", 2] },
        min_percentage: { $round: ["$min_percentage", 2] }
      }
    },
    { $sort: { subject: 1 } }
  ]);
  ```

#### Pipeline 4: Student Academic Rankings
* **Objective**: Group all exam scores per student, compute cumulative average score, join student details, and assign ranks.
* **Pipeline Implementation**:
  ```javascript
  db.marks.aggregate([
    {
      $group: {
        _id: "$student_id",
        total_exams: { $sum: 1 },
        avg_percentage: { $avg: "$percentage" }
      }
    },
    {
      $lookup: {
        from: "students",
        localField: "_id",
        foreignField: "student_id",
        as: "student"
      }
    },
    { $unwind: "$student" },
    { $sort: { avg_percentage: -1 } }
  ]);
  ```

#### Pipeline 5: Unified 360-Degree Profile (0 Cartesian Double-Counting)
* **Objective**: Produce unified attendance and marks stats in a single query **without** Cartesian row multiplication ($N \times M$).
* **Mechanism**: Uses correlated subqueries within `$lookup` containing inner `$group` stages, guaranteeing strict 1:1 join cardinality.
* **Pipeline Implementation**:
  ```javascript
  db.students.aggregate([
    {
      $lookup: {
        from: "attendance",
        let: { sid: "$student_id" },
        pipeline: [
          { $match: { $expr: { $eq: ["$student_id", "$$sid"] } } },
          {
            $group: {
              _id: "$student_id",
              total_classes: { $sum: 1 },
              present: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } },
              late: { $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] } }
            }
          }
        ],
        as: "attendance_stats"
      }
    },
    {
      $lookup: {
        from: "marks",
        let: { sid: "$student_id" },
        pipeline: [
          { $match: { $expr: { $eq: ["$student_id", "$$sid"] } } },
          {
            $group: {
              _id: "$student_id",
              total_exams: { $sum: 1 },
              avg_percentage: { $avg: "$percentage" }
            }
          }
        ],
        as: "marks_stats"
      }
    },
    { $unwind: { path: "$attendance_stats", preserveNullAndEmptyArrays: true } },
    { $unwind: { path: "$marks_stats", preserveNullAndEmptyArrays: true } }
  ]);
  ```

---

## 10. Testing Methodology and Actual Results

All verification steps were executed against the codebase in the local environment.

### 10.1 Backend Isolated Automated Test Suite (`test_backend_suite.py`)
Executed on dedicated database `campustrack_test_suite`:

| Test ID | Test Target / Functionality | Input / Scenario | Status | Result / Output |
| :--- | :--- | :--- | :---: | :--- |
| `TC-01` | Server & Database Health | `GET /health` | **PASS** | HTTP 200, healthy=True, connected=True |
| `TC-02` | Student Registration | Valid payload (`STU9001`) | **PASS** | HTTP 201, student created |
| `TC-03` | Unique Student ID Enforced | Duplicate `student_id: STU9001` | **PASS** | HTTP 409 Conflict rejected |
| `TC-04` | Student Schema Validation | Invalid email / Semester 10 | **PASS** | HTTP 400 Bad Request rejected |
| `TC-05` | Student Retrieval & 404 | Non-existent student query | **PASS** | HTTP 404 Not Found returned |
| `TC-06` | Student Modification | Valid update vs bad semester | **PASS** | HTTP 200 on valid, HTTP 400 on bad |
| `TC-07` | Search & Filter Students | Query by name & active status | **PASS** | HTTP 200, matching students returned |
| `TC-08` | Safe Student Deletion | Delete student & verify purge | **PASS** | HTTP 200, subsequent query is 404 |
| `TC-09` | Attendance Logging | Valid session mark (`Present`) | **PASS** | HTTP 201 Created |
| `TC-10` | Attendance Uniqueness | Duplicate student+date+subject | **PASS** | HTTP 409 Conflict rejected |
| `TC-11` | Attendance Validation | Invalid status `Excused` / bad date| **PASS** | HTTP 400 Bad Request rejected |
| `TC-12` | Attendance Update & Delete | Valid ObjectId vs Malformed ID | **PASS** | HTTP 200 on valid, HTTP 400 on bad |
| `TC-13` | Marks Entry & Percentage | `84 / 100` marks entry | **PASS** | HTTP 201, percentage=84.0% |
| `TC-14` | Marks Range Validation | `105 / 100` & negative marks | **PASS** | HTTP 400 Bad Request rejected |
| `TC-15` | Marks Uniqueness | Duplicate exam for student | **PASS** | HTTP 409 Conflict rejected |
| `TC-16` | Marks Update & Recalculate | Update marks from 84 to 92 | **PASS** | HTTP 200, percentage updated to 92.0% |
| `TC-17` | Empty Dataset & Div-by-Zero | Student with 0 classes/marks | **PASS** | HTTP 200 across all reports, 0.0% safe |
| `TC-18` | Controlled Dataset Math | Controlled test dataset | **PASS** | Math matches expected values exactly |

### 10.2 Mathematical Calculations Verification (`test_analytics_calculations.py`)
- Student `KNOWN01` (3 Present, 1 Late / 4 classes): Calculated = **87.5%**, Expected = **87.5%** (**MATCH**).
- Student `KNOWN02` (1 Present, 3 Absent / 4 classes): Calculated = **25.0%**, Expected = **25.0%** (**MATCH**).
- Defaulter Threshold: `KNOWN02` correctly isolated with 50.0% shortfall (**MATCH**).
- Academic Rankings: Sorted descending with 100% precision (**MATCH**).
- Cartesian Product Double-Counting: 4 classes and 2 exams preserved with 1:1 cardinality (**ZERO MULTIPLICATION**).

### 10.3 Frontend Static Analysis & Widget Tests
- **`flutter analyze` Result**:
  ```text
  Analyzing frontend...
  No issues found! (ran in 13.6s)
  ```
  *(0 errors, 0 warnings, 0 deprecations)*
- **`flutter test` Result**:
  ```text
  00:03 +10: All tests passed!
  ```
  *(10/10 tests passed across models, serializations, empty states, error states, and KPI cards)*

---

## 11. Screenshots Guide (App & MongoDB Compass)

*Note: As an automated coding pair, I do not capture or fabricate personal desktop image files. You must take screenshots of your running system. Follow this structured table to take the required screenshots:*

| Figure # | Title | Application / Screen | What to Show / Highlight |
| :---: | :--- | :--- | :--- |
| **Fig 1.1** | MongoDB Compass — Database & Collections | MongoDB Compass | Database `campustrack` with 3 collections: `students`, `attendance`, `marks`. Document counts visible. |
| **Fig 1.2** | MongoDB Compass — Schema Validation Rules | MongoDB Compass | Click `students` -> `Validation` tab. Highlight `$jsonSchema` rules for required fields and semester integer constraints. |
| **Fig 1.3** | MongoDB Compass — Index Configuration | MongoDB Compass | Click `attendance` -> `Indexes` tab. Highlight compound unique index on `student_id_1_date_1_subject_1`. |
| **Fig 1.4** | MongoDB Compass — Aggregation Pipeline Execution | MongoDB Compass | Click `attendance` -> `Aggregations` tab. Paste Pipeline 1 ($group, $project). Show stage outputs previewing attendance %. |
| **Fig 2.1** | Flask REST API — Startup & Health Check | Terminal / PowerShell / Postman | Console showing `Starting CampusTrack Flask server on 0.0.0.0:5000` and `GET /health` returning HTTP 200 OK. |
| **Fig 3.1** | CampusTrack — Welcome / Splash Screen | Flutter App (Phone/Web) | Indigo branded screen with school icon, app title, and live "API Connected" badge. |
| **Fig 3.2** | CampusTrack — Admin Dashboard Overview | Flutter App | Top KPI cards (Total Students: 12, Attendance: 86.4%, Avg Marks: 78.2%), course distribution chart. |
| **Fig 3.3** | CampusTrack — Student Directory & Search | Flutter App | Student list with search bar, course filter chips (`Computer Science`, `IT`), and active enrollment badges. |
| **Fig 3.4** | CampusTrack — Add / Edit Student Form | Flutter App | Form showing validation errors when an invalid email or out-of-range semester is submitted. |
| **Fig 3.5** | CampusTrack — Mark Daily Attendance Screen | Flutter App | Form with Student dropdown, Date picker, Subject selector, and `Present`/`Absent`/`Late` toggle buttons. |
| **Fig 3.6** | CampusTrack — Record Examination Marks Screen | Flutter App | Form with Student dropdown, Exam selector, score inputs, and real-time calculated percentage preview. |
| **Fig 3.7** | CampusTrack — Institutional Analytics & Charts | Flutter App | Reports screen displaying Subject Performance BarChart and Attendance Threshold Chart with 75% red line. |
| **Fig 3.8** | CampusTrack — Low-Attendance Defaulters List | Flutter App | Tab showing flagged students with attendance $< 75\%$ (`Tanvi Gupta: 0.0%`, `Aditya Verma: 20.0%`). |
| **Fig 3.9** | CampusTrack — Academic Merit Rankings | Flutter App | Class rankings sorted from Rank #1 down to lowest cumulative percentage with medal icons. |
| **Fig 3.10**| CampusTrack — Student 360 Detail View | Flutter App | Individual profile showing attendance badge, academic average, and chronological session logs. |

---

## 12. Limitations and Future Enhancements

### 12.1 Current Limitations
1. **Manual Session Input**: Attendance is recorded manually by faculty rather than through biometric hardware or automated student devices.
2. **Local / Single-Campus Scope**: The current version is optimized for single-institution local network deployment rather than multi-campus cloud multi-tenancy.
3. **Absence of Role-Based Permissions**: All logged-in administrative users currently share uniform read/write permissions.

### 12.2 Future Enhancements
1. **Automated Biometric & QR Attendance**: Integrate dynamic, time-limited QR codes generated in the classroom or biometric RFID readers communicating directly with the Flask API.
2. **Predictive Performance Analytics (Machine Learning)**: Implement Scikit-learn regressors on the Flask backend to predict end-semester student outcomes based on early attendance trends and mid-term marks.
3. **Role-Based Access Control (RBAC)**: Introduce JWT-based authentication distinguishing between Super Admins, Department HODs, Faculty, and Students.
4. **Push Notifications**: Integrate Firebase Cloud Messaging (FCM) to trigger automated alerts to parents and students whenever attendance dips below 75%.

---

## 13. Conclusion and References

### 13.1 Conclusion
The **CampusTrack — Student Attendance and Performance Management System** successfully demonstrates the integration of a modern **Flutter** mobile/web frontend, a modular **Python Flask** microservices backend, and a high-performance **MongoDB NoSQL** document database. 

By eliminating relational impedance mismatch, enforcing data constraints through MongoDB `$jsonSchema` validators, eliminating duplicate entries via compound unique indexes, and delegating complex statistical calculations to server-side aggregation pipelines, CampusTrack provides a responsive, reliable administrative experience. Automated verification across 18 backend tests, mathematical assertions, and 10 Flutter tests validates that CampusTrack is production-ready, academically rigorous, and suitable for college evaluation.

### 13.2 References
1. **MongoDB, Inc.** (2026). *MongoDB Community Server Documentation (v8.0): Aggregation Framework and Schema Validation*. MongoDB Docs: `https://www.mongodb.com/docs/`.
2. **Google LLC**. (2026). *Flutter Documentation: Building Reactive User Interfaces with Material Design 3 and Provider*. Flutter Dev: `https://docs.flutter.dev/`.
3. **Pallets Projects**. (2026). *Flask Documentation: Application Factories, Blueprints, and RESTful Design (v3.0)*. Pallets: `https://flask.palletsprojects.com/`.
4. **Chodorow, Kristina**. (2013). *MongoDB: The Definitive Guide: Powerful and Scalable Data Storage*. O'Reilly Media.
5. **Banker, Kyle, et al.** (2016). *MongoDB in Action: Covers MongoDB version 3.0*. Manning Publications.
6. **Windmill, Eric**. (2020). *Flutter in Action*. Manning Publications.
