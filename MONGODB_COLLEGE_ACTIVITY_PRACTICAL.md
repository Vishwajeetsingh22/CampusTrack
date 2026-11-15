# CampusTrack — MongoDB NoSQL Activity Practical & Viva Manual
## Comprehensive College Demonstration Guide for MongoDB Compass & Flask-Flutter Architecture

---

## 1. Quick Reference: Seed Dataset Overview

The seed script (`python -m db.seed_data`) creates a controlled, predictable, and verifiable dataset designed specifically for viva defense.

| Metric | Target Value | Student / Reason |
| :--- | :--- | :--- |
| **Total Enrolled Students** | **12** | `STU1001` through `STU1012` |
| **Active Students** | **11** | `STU1012` is inactive (on medical leave) |
| **Total Attendance Records** | **110** | 11 students $\times$ 5 dates $\times$ 2 subjects |
| **Total Exam Marks Records** | **96** | 12 students $\times$ 2 exams $\times$ 4 subjects |
| **Overall Class Attendance** | **86.36%** | Present: 94, Absent: 14, Late: 2 |
| **Class Average Marks** | **78.19%** | Realistic academic distribution |
| **Students Below 75% Cutoff** | **2 Defaulters** | **`STU1004`** (20.0%, shortfall 55%), **`STU1007`** (40.0%, shortfall 35%) |
| **Zero-Attendance Student** | **1 Student** | **`STU1012`** (Tanvi Gupta) — Verifies edge-case division-by-zero protection |
| **Top Academic Ranker** | **`STU1006`** | Sneha Reddy (91.75% cumulative average) |

### Idempotency & Safety Policy
- **Non-destructive seeding**: `python -m db.seed_data` (uses `update_one(..., upsert=True)`. Can be executed repeatedly without generating duplicate documents or deleting user-created data).
- **Destructive reset**: `python -m db.seed_data --reset` (requires the explicit `--reset` CLI flag to drop and re-seed collections from scratch).

---

## 2. The 9 Core MongoDB Demonstration Operations

Each operation below includes:
1. **MongoDB Shell / Compass Code**: Directly executable in Compass `_mongosh_` or terminal.
2. **MongoDB Compass GUI Steps**: Step-by-step instructions for clicking through Compass tabs.
3. **Application Integration**: How the Flutter frontend and Flask REST backend run this operation.

---

### Operation 1: Insert Documents (CRUD: Create)

#### MongoDB Shell / Compass Command
```javascript
// Switch to campustrack database
use campustrack;

// Insert a student document
db.students.insertOne({
  student_id: "DEMO2001",
  name: "Ishaan Verma",
  course: "Computer Science",
  department: "Computer Science",
  semester: 6,
  email: "ishaan.verma@campus.edu",
  phone: "+91-9876500099",
  active: true,
  created_at: new Date(),
  updated_at: new Date()
});

// Insert an attendance document for the student
db.attendance.insertOne({
  student_id: "DEMO2001",
  date: "2026-10-25",
  subject: "NoSQL Databases",
  status: "Present",
  remarks: "On time for viva demo",
  created_at: new Date(),
  updated_at: new Date()
});
```

#### MongoDB Compass GUI Demonstration
1. In the left navigation pane, click on the **`campustrack`** database.
2. Select the **`students`** collection.
3. In the top right of the documents panel, click **"Add Data"** -> **"Insert Document"**.
4. Paste the JSON document or enter field-by-field, then click **"Insert"**.

#### Application Execution
- **Flutter UI**: "Register New Student" (`student_form_screen.dart`) and "Mark Attendance" (`mark_attendance_screen.dart`).
- **Flask REST Endpoints**: `POST /api/students` and `POST /api/attendance`.

---

### Operation 2: Find and Filter Documents (CRUD: Read)

#### MongoDB Shell / Compass Command
```javascript
// Example 2A: Query by department and active status
db.students.find(
  { course: "Computer Science", active: true },
  { student_id: 1, name: 1, semester: 1, _id: 0 }
);

// Example 2B: Range query on numerical scores (percentage >= 85%)
db.marks.find(
  { percentage: { $gte: 85.0 } },
  { student_id: 1, subject: 1, exam: 1, percentage: 1, _id: 0 }
);

// Example 2C: Logical $or filter for problematic attendance
db.attendance.find(
  { $or: [{ status: "Late" }, { status: "Absent" }] },
  { student_id: 1, date: 1, subject: 1, status: 1, remarks: 1, _id: 0 }
);
```

#### MongoDB Compass GUI Demonstration
1. Open the **`marks`** collection.
2. In the top **"Filter"** bar, enter: `{ percentage: { $gte: 85.0 } }`.
3. In the **"Project"** dropdown, enter: `{ student_id: 1, subject: 1, percentage: 1, _id: 0 }`.
4. Click **"Find"** to display filtered distinction records.

#### Application Execution
- **Flutter UI**: Search bar on the student list screen and status chips on the attendance list.
- **Flask REST Endpoints**: `GET /api/students?course=Computer+Science`, `GET /api/marks?exam=Final`.

---

### Operation 3: Update Documents (CRUD: Update)

#### MongoDB Shell / Compass Command
```javascript
// Example 3A: Update semester and contact phone with $set
db.students.updateOne(
  { student_id: "DEMO2001" },
  {
    $set: {
      semester: 7,
      phone: "+91-9876500000",
      updated_at: new Date()
    }
  }
);

// Example 3B: Increment marks obtained with $inc operator
db.marks.updateOne(
  { student_id: "DEMO2001", exam: "Mid-Term", subject: "NoSQL Databases" },
  {
    $inc: { marks_obtained: 1.5 },
    $set: { percentage: 96.0, updated_at: new Date() }
  }
);
```

#### MongoDB Compass GUI Demonstration
1. In the **`students`** collection, find `student_id: "DEMO2001"`.
2. Hover over the document and click the **Pencil (Edit Document)** icon.
3. Change `semester` from `6` to `7` and click **"Update"**.

#### Application Execution
- **Flutter UI**: "Edit Student Profile" and "Edit Exam Marks" screens.
- **Flask REST Endpoints**: `PUT /api/students/<id>` and `PUT /api/marks/<id>`.

---

### Operation 4: Delete a Test Document (CRUD: Delete)

#### MongoDB Shell / Compass Command
```javascript
// Safely delete student and cascade child logs to prevent broken references
db.attendance.deleteMany({ student_id: "DEMO2001" });
db.marks.deleteMany({ student_id: "DEMO2001" });
db.students.deleteOne({ student_id: "DEMO2001" });
```

#### MongoDB Compass GUI Demonstration
1. Locate the document with `student_id: "DEMO2001"`.
2. Hover over the document and click the **Trash Can (Delete)** icon.
3. In the confirmation dialog, click **"Delete"**.

#### Application Execution
- **Flutter UI**: Popup menu on student cards with confirmation dialog warning about cascading cleanup.
- **Flask REST Endpoint**: `DELETE /api/students/<id>`.

---

### Operation 5: Create and Inspect Indexes (Performance & Uniqueness)

#### MongoDB Shell / Compass Command
```javascript
// Inspect all indexes on students
db.students.getIndexes();

// Compound unique index inspection on attendance
db.attendance.getIndexes();

// Run explain() on query to verify index usage (IXSCAN vs COLLSCAN)
db.students.find({ student_id: "STU1001" }).explain("executionStats");
```

#### MongoDB Compass GUI Demonstration
1. Open the **`students`** collection and select the **"Indexes"** tab.
2. Observe index `idx_students_student_id_unique` with property **Unique: True**.
3. Select the **"Explain Plan"** tab, enter `{ student_id: "STU1001" }`, and click **"Explain"**.
4. Compass displays a visual query execution tree showing stage **`IXSCAN`** / **`EXPRESS_IXSCAN`**, examining only 1 document instead of scanning the full collection.

#### Application Execution
- **Flask Backend**: Initialized at server launch via [`backend/db/indexes.py`](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/backend/db/indexes.py).
- **Demo Route**: `GET /api/demo/indexes` and `GET /api/demo/explain`.

---

### Operation 6: Validate Document Structure (`$jsonSchema`)

#### MongoDB Shell / Compass Command
```javascript
// Attempt to insert an invalid student (invalid semester, invalid email)
try {
  db.students.insertOne({
    student_id: "INVALID99",
    name: "Bad Record",
    semester: 12,          // REJECTED: Enforces 1 <= semester <= 8
    email: "not-an-email", // REJECTED: Enforces regex pattern ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$
    course: "Computer Science"
  });
} catch (e) {
  print("Document rejected by $jsonSchema validator: " + e.message);
}
```

#### MongoDB Compass GUI Demonstration
1. Open the **`students`** collection and click the **"Validation"** tab.
2. Inspect the JSON Schema rules: `required: ["student_id", "name", "email", "course", "semester"]`, `minimum: 1`, `maximum: 8`.
3. Try inserting an invalid document in Compass; observe the instant validation error modal.

#### Application Execution
- **Flask Backend**: Enforced at collection creation time via [`backend/db/schema_validator.py`](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/backend/db/schema_validator.py).
- **Demo Route**: `GET /api/demo/schemas`.

---

### Operation 7: Aggregate Attendance Percentages (Late Rule & Cutoff)

#### MongoDB Shell / Compass Command
```javascript
db.attendance.aggregate([
  {
    $group: {
      _id: "$student_id",
      total_classes: { $sum: 1 },
      present_count: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } },
      late_count: { $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] } },
      absent_count: { $sum: { $cond: [{ $eq: ["$status", "Absent"] }, 1, 0] } }
    }
  },
  {
    $project: {
      student_id: "$_id",
      _id: 0,
      total_classes: 1,
      present_count: 1,
      late_count: 1,
      absent_count: 1,
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
  { $sort: { attendance_pct: 1 } }
]);
```

#### MongoDB Compass GUI Demonstration
1. Open the **`attendance`** collection and click the **"Aggregations"** tab.
2. Select stage **`$group`** and enter the group document.
3. Click **"Add Stage"**, select **`$project`**, and enter the percentage calculation.
4. Click **"Add Stage"**, select **`$sort`**, and enter `{ attendance_pct: 1 }`.
5. Observe live document previews after each stage on the right-hand panel.

#### Application Execution
- **Flutter UI**: Attendance Roster and Defaulters tabs in `reports_screen.dart`.
- **Flask REST Endpoints**: `GET /api/reports/attendance` and `GET /api/reports/low-attendance`.

---

### Operation 8: Calculate Average Marks and Rankings

#### MongoDB Shell / Compass Command
```javascript
db.marks.aggregate([
  {
    $group: {
      _id: "$student_id",
      total_exams: { $sum: 1 },
      total_obtained: { $sum: "$marks_obtained" },
      total_max: { $sum: "$max_marks" },
      avg_percentage: { $avg: "$percentage" }
    }
  },
  {
    $project: {
      student_id: "$_id",
      _id: 0,
      total_exams: 1,
      total_obtained: { $round: ["$total_obtained", 2] },
      total_max: { $round: ["$total_max", 2] },
      avg_percentage: { $round: ["$avg_percentage", 2] }
    }
  },
  { $sort: { avg_percentage: -1 } }
]);
```

#### MongoDB Compass GUI Demonstration
1. Open the **`marks`** collection and click the **"Aggregations"** tab.
2. Add stage **`$group`** with accumulator `$avg: "$percentage"`.
3. Add stage **`$sort`** with `{ avg_percentage: -1 }`.
4. Observe top ranker `STU1006` (Sneha Reddy, 91.75%) displayed at the top.

#### Application Execution
- **Flutter UI**: Rankings Leaderboard tab with Gold/Silver/Bronze medals.
- **Flask REST Endpoint**: `GET /api/reports/rankings`.

---

### Operation 9: Join Student Data with Attendance/Marks Using `$lookup`

#### MongoDB Shell / Compass Command
```javascript
db.attendance.aggregate([
  {
    $group: {
      _id: "$student_id",
      total_classes: { $sum: 1 },
      present_count: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } }
    }
  },
  // Left outer join to students collection
  {
    $lookup: {
      from: "students",
      localField: "_id",
      foreignField: "student_id",
      as: "student_profile"
    }
  },
  { $unwind: "$student_profile" },
  {
    $project: {
      student_id: "$_id",
      _id: 0,
      name: "$student_profile.name",
      course: "$student_profile.course",
      total_classes: 1,
      present_count: 1
    }
  },
  { $limit: 5 }
]);
```

#### MongoDB Compass GUI Demonstration
1. In the **`attendance`** collection's **"Aggregations"** tab, add a **`$lookup`** stage:
   - `from`: `"students"`
   - `localField`: `"_id"`
   - `foreignField`: `"student_id"`
   - `as`: `"student_profile"`
2. Add an **`$unwind`** stage: `"$student_profile"`.
3. Observe how student profile data is embedded into attendance records.

#### Application Execution
- **Flutter UI**: Student detail screens, 360-degree summaries, and unified reports.
- **Flask REST Endpoints**: `GET /api/reports/attendance` and `GET /api/reports/unified`.

---

## 3. How to Demonstrate During College Evaluation

### Step 1: Reset and Seed the Database
In PowerShell:
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\backend"
.\.venv\Scripts\Activate.ps1
python -m db.seed_data --reset
```
*Result: 12 students, 110 attendance records, 96 marks, 2 defaulters, 1 zero-attendance student.*

### Step 2: Run the Automated Demonstration Test
```powershell
python test_mongodb_viva_examples.py
```
*Result: Verifies all 9 MongoDB operations pass (7/7 assertions).*

### Step 3: Run the Mathematical Analytics Test
```powershell
python test_analytics_calculations.py
```
*Result: Verifies the Late = 0.5 rule, 75% cutoff, and Cartesian product double-counting prevention.*

### Step 4: Show MongoDB Compass
1. Connect Compass to `mongodb://localhost:27017/`.
2. Open database **`campustrack`**.
3. Show the 3 collections: `students`, `attendance`, `marks`.
4. Open the **"Indexes"** tab to highlight unique compound indexes.
5. Open the **"Validation"** tab to show `$jsonSchema` constraints.
6. Open the bottom **`_mongosh_`** tab and run `load("mongodb_demo_examples.js")` to execute all 9 queries live.

### Step 5: Show the Flutter Application
In a separate terminal:
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"
flutter run -d windows
```
- **Dashboard**: Highlights Total Students (12), Attendance (86.4%), Average Marks (78.2%), and 2 Defaulters.
- **Attendance**: Shows attendance cutoff bar chart with red 75% cutoff line.
- **Subject Stats**: Shows dual-rod bar chart comparing Average Marks vs Pass Rate.
- **Rankings**: Leaderboard displaying top rankers.
- **Defaulters**: Lists `STU1004` (20%) and `STU1007` (40%) with shortfalls.
