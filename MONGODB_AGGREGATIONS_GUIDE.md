# CampusTrack — MongoDB Aggregation Pipelines & Analytics Guide
## Complete Technical Documentation for College NoSQL Practical & Viva Demonstration

---

## 1. Overview of MongoDB Aggregation Framework

In MongoDB, the **Aggregation Pipeline** is a framework for data processing modeled on the concept of data processing pipelines. Documents enter a multi-stage pipeline that transforms the documents into aggregated results.

In **CampusTrack**, rather than performing calculations in application memory (Python or Dart), all attendance statistics, grade averages, and rankings are calculated directly on the database engine using native aggregation operators. This provides maximum throughput, lower network latency, and demonstrates authentic NoSQL database capabilities.

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     $match      │ ───►  │     $group      │ ───►  │    $project     │ ───►  │  $lookup/$sort  │
│ Filter target   │       │ Group by key &  │       │ Compute %, late │       │ Join & order    │
│ records         │       │ accumulate sums │       │ credit, round   │       │ final results   │
└─────────────────┘       └─────────────────┘       └─────────────────┘       └─────────────────┘
```

---

## 2. Key Pipeline Stages & Operators Used

| Stage / Operator | Role in CampusTrack | SQL Equivalent |
| :--- | :--- | :--- |
| **`$match`** | Filters documents by course, semester, exam, or threshold. | `WHERE`, `HAVING` |
| **`$group`** | Groups documents by `student_id`, `subject`, or `status` and applies accumulators (`$sum`, `$avg`, `$max`, `$min`, `$addToSet`). | `GROUP BY` |
| **`$project`** | Shapes output documents, computes derived fields, rounds numbers, and renames identifiers. | `SELECT ... AS` |
| **`$sort`** | Orders documents by marks percentage (descending) or attendance percentage. | `ORDER BY` |
| **`$lookup`** | Performs a left outer join to another collection (e.g., joining `attendance` to `students`). | `LEFT JOIN` |
| **`$unwind`** | Deconstructs an array field from `$lookup` into individual documents. | Flat row expansion |
| **`$cond`** | Evaluates a boolean condition and returns one of two branches (crucial for division-by-zero protection). | `CASE WHEN ... THEN ... ELSE` |
| **`$divide` / `$multiply`** | Computes ratios and scales values into percentages. | `/`, `*` |
| **`$round`** | Rounds decimal percentages to 2 decimal places. | `ROUND(col, 2)` |
| **`$addToSet`** | Accumulates unique values into an array (used to count distinct students per subject). | `COUNT(DISTINCT col)` |
| **`$size`** | Measures array length (e.g., number of unique students). | `LENGTH` / `ARRAY_LENGTH` |
| **`$ifNull`** | Provides fallback defaults when fields are null or missing. | `COALESCE(col, default)` |

---

## 3. Core Business Logic & Attendance Calculation Rule

### The Attendance Calculation Rule
In academic institutions, students who arrive late typically receive partial attendance credit rather than full absence. CampusTrack implements the standard college weighting formula:

- **Present**: Awarded **1.0 credit** (100%)
- **Late**: Awarded **0.5 credit** (50% partial credit)
- **Absent**: Awarded **0.0 credit** (0% credit)

$$\text{Attendance Percentage} = \frac{\text{Present Count} + (\text{Late Count} \times 0.5)}{\text{Total Classes}} \times 100$$

### Low Attendance Defaulter Cutoff
- **Mandatory Threshold**: **75.0%**
- **Defaulter Condition**: $\text{Attendance Percentage} < 75.0\%$
- **Shortfall Calculation**: $\text{Shortfall} = 75.0 - \text{Attendance Percentage}$

---

## 4. Complete Aggregation Pipeline Implementations

### Pipeline 1: Student-Wise Attendance Percentage
**File**: `backend/services/aggregation_service.py` -> `get_attendance_report()`  
**Endpoint**: `GET /api/reports/attendance`

```javascript
db.attendance.aggregate([
  // Stage 1: Group attendance records by student_id and count statuses
  {
    $group: {
      _id: "$student_id",
      total_classes: { $sum: 1 },
      present_count: {
        $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] }
      },
      absent_count: {
        $sum: { $cond: [{ $eq: ["$status", "Absent"] }, 1, 0] }
      },
      late_count: {
        $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] }
      }
    }
  },

  // Stage 2: Calculate percentage with division-by-zero protection
  {
    $project: {
      student_id: "$_id",
      _id: 0,
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

  // Stage 3: Left Join to 'students' collection to retrieve student names & department
  {
    $lookup: {
      from: "students",
      localField: "student_id",
      foreignField: "student_id",
      as: "student"
    }
  },

  // Stage 4: Deconstruct joined student array
  {
    $unwind: {
      path: "$student",
      preserveNullAndEmptyArrays: true
    }
  },

  // Stage 5: Final projection and status tag
  {
    $project: {
      student_id: 1,
      name: { $ifNull: ["$student.name", "Unknown"] },
      course: { $ifNull: ["$student.course", "$student.department"] },
      semester: { $ifNull: ["$student.semester", 0] },
      email: { $ifNull: ["$student.email", ""] },
      total_classes: 1,
      present_count: 1,
      absent_count: 1,
      late_count: 1,
      attendance_pct: 1,
      status: {
        $cond: [{ $lt: ["$attendance_pct", 75.0] }, "Low Attendance", "Normal"]
      }
    }
  },

  // Stage 6: Sort by attendance percentage descending
  { $sort: { attendance_pct: -1, student_id: 1 } }
]);
```

---

### Pipeline 2: Low-Attendance Identification (< 75% Threshold)
**File**: `backend/services/aggregation_service.py` -> `get_low_attendance_report(threshold=75.0)`  
**Endpoint**: `GET /api/reports/low-attendance`

```javascript
db.attendance.aggregate([
  // Group by student_id
  {
    $group: {
      _id: "$student_id",
      total_classes: { $sum: 1 },
      present_count: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } },
      absent_count: { $sum: { $cond: [{ $eq: ["$status", "Absent"] }, 1, 0] } },
      late_count: { $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] } }
    }
  },
  // Calculate attendance %
  {
    $project: {
      student_id: "$_id",
      _id: 0,
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
  // Filter for students strictly below the 75% threshold
  {
    $match: {
      attendance_pct: { $lt: 75.0 }
    }
  },
  // Lookup student contact information for administrative notice
  {
    $lookup: {
      from: "students",
      localField: "student_id",
      foreignField: "student_id",
      as: "student_info"
    }
  },
  {
    $unwind: {
      path: "$student_info",
      preserveNullAndEmptyArrays: true
    }
  },
  {
    $project: {
      student_id: 1,
      name: { $ifNull: ["$student_info.name", "Unknown"] },
      course: { $ifNull: ["$student_info.course", "$student_info.department"] },
      semester: { $ifNull: ["$student_info.semester", 0] },
      email: { $ifNull: ["$student_info.email", "N/A"] },
      phone: { $ifNull: ["$student_info.phone", "N/A"] },
      total_classes: 1,
      attendance_pct: 1,
      shortfall: {
        $round: [{ $subtract: [75.0, "$attendance_pct"] }, 2]
      }
    }
  },
  { $sort: { attendance_pct: 1 } }
]);
```

---

### Pipeline 3: Student Academic Rankings Leaderboard
**File**: `backend/services/aggregation_service.py` -> `get_student_rankings()`  
**Endpoint**: `GET /api/reports/rankings`

```javascript
db.marks.aggregate([
  // Stage 1: Group marks by student_id and calculate overall averages
  {
    $group: {
      _id: "$student_id",
      total_exams: { $sum: 1 },
      total_obtained: { $sum: "$marks_obtained" },
      total_max: { $sum: "$max_marks" },
      avg_percentage: { $avg: "$percentage" }
    }
  },
  // Stage 2: Project with safe null checking
  {
    $project: {
      student_id: "$_id",
      _id: 0,
      total_exams: 1,
      total_obtained: { $round: ["$total_obtained", 2] },
      total_max: { $round: ["$total_max", 2] },
      avg_percentage: {
        $cond: [
          { $and: [{ $ne: ["$avg_percentage", null] }, { $gt: ["$total_exams", 0] }] },
          { $round: ["$avg_percentage", 2] },
          0.0
        ]
      }
    }
  },
  // Stage 3: Lookup student profile
  {
    $lookup: {
      from: "students",
      localField: "student_id",
      foreignField: "student_id",
      as: "student_info"
    }
  },
  {
    $unwind: {
      path: "$student_info",
      preserveNullAndEmptyArrays: true
    }
  },
  {
    $project: {
      student_id: 1,
      name: { $ifNull: ["$student_info.name", "Unknown"] },
      course: { $ifNull: ["$student_info.course", "$student_info.department"] },
      semester: { $ifNull: ["$student_info.semester", 0] },
      email: { $ifNull: ["$student_info.email", ""] },
      total_exams: 1,
      total_obtained: 1,
      total_max: 1,
      avg_percentage: 1
    }
  },
  // Stage 4: Order by average percentage descending (Highest first)
  { $sort: { avg_percentage: -1 } }
]);
```

---

### Pipeline 4: Subject-Wise Performance & Pass Percentage
**File**: `backend/services/aggregation_service.py` -> `get_performance_report()`  
**Endpoint**: `GET /api/reports/performance`

```javascript
db.marks.aggregate([
  {
    $group: {
      _id: "$subject",
      student_count: { $sum: 1 },
      avg_percentage: { $avg: "$percentage" },
      max_percentage: { $max: "$percentage" },
      min_percentage: { $min: "$percentage" },
      avg_obtained: { $avg: "$marks_obtained" },
      max_obtained: { $max: "$marks_obtained" },
      min_obtained: { $min: "$marks_obtained" },
      pass_count: {
        $sum: { $cond: [{ $gte: ["$percentage", 40.0] }, 1, 0] }
      }
    }
  },
  {
    $project: {
      subject: "$_id",
      _id: 0,
      student_count: 1,
      pass_count: 1,
      pass_percentage: {
        $cond: [
          { $gt: ["$student_count", 0] },
          { $round: [{ $multiply: [{ $divide: ["$pass_count", "$student_count"] }, 100] }, 2] },
          0.0
        ]
      },
      avg_percentage: { $round: ["$avg_percentage", 2] },
      max_percentage: { $round: ["$max_percentage", 2] },
      min_percentage: { $round: ["$min_percentage", 2] },
      avg_obtained: { $round: ["$avg_obtained", 2] },
      max_obtained: { $round: ["$max_obtained", 2] },
      min_obtained: { $round: ["$min_obtained", 2] }
    }
  },
  { $sort: { subject: 1 } }
]);
```

---

### Pipeline 5: Subject-Wise Attendance Summary
**File**: `backend/services/aggregation_service.py` -> `get_subject_attendance_report()`  
**Endpoint**: `GET /api/reports/subject-attendance`

```javascript
db.attendance.aggregate([
  {
    $group: {
      _id: "$subject",
      total_records: { $sum: 1 },
      unique_students: { $addToSet: "$student_id" },
      present_count: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } },
      absent_count: { $sum: { $cond: [{ $eq: ["$status", "Absent"] }, 1, 0] } },
      late_count: { $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] } }
    }
  },
  {
    $project: {
      subject: "$_id",
      _id: 0,
      total_records: 1,
      student_count: { $size: "$unique_students" },
      present_count: 1,
      absent_count: 1,
      late_count: 1,
      attendance_percentage: {
        $cond: [
          { $gt: ["$total_records", 0] },
          {
            $round: [
              {
                $multiply: [
                  {
                    $divide: [
                      { $add: ["$present_count", { $multiply: ["$late_count", 0.5] }] },
                      "$total_records"
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
  { $sort: { attendance_percentage: -1, subject: 1 } }
]);
```

---

## 5. Viva Defense: Avoiding Cartesian Product Double-Counting

### The Common Pitfall
When joining multiple 1-to-many collections in SQL or MongoDB (e.g., joining `students` with `attendance` and `marks`), a naive sequential join creates a **Cartesian Product**:

$$\text{Total Joined Rows} = N_{\text{attendance}} \times M_{\text{marks}}$$

*Example*: If a student has 10 attendance records and 4 exam scores:
- A naive join produces $10 \times 4 = 40$ documents!
- A subsequent `$sum: "$marks_obtained"` would sum each mark 10 times, double-counting marks and falsifying academic records!

### The CampusTrack Solution: Correlated Subpipelines (`$let` + `$expr`)
**File**: `backend/services/aggregation_service.py` -> `get_student_unified_analytics()`

Instead of joining raw collections and then grouping, CampusTrack uses **correlated subpipeline lookups**. The subqueries pre-aggregate each collection into exactly **one summary document per student** before joining:

```javascript
db.students.aggregate([
  // 1. Correlated lookup for Attendance (Pre-aggregated)
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
            late: { $sum: { $cond: [{ $eq: ["$status", "Late"] }, 1, 0] } },
            absent: { $sum: { $cond: [{ $eq: ["$status", "Absent"] }, 1, 0] } }
          }
        }
      ],
      as: "attendance_stats"
    }
  },

  // 2. Correlated lookup for Marks (Pre-aggregated)
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
            total_obtained: { $sum: "$marks_obtained" },
            total_max: { $sum: "$max_marks" },
            avg_percentage: { $avg: "$percentage" }
          }
        }
      ],
      as: "marks_stats"
    }
  },

  // 3. Unwind pre-grouped arrays (Cardinality is strictly 1:1, ZERO Cartesian fanout!)
  {
    $unwind: {
      path: "$attendance_stats",
      preserveNullAndEmptyArrays: true
    }
  },
  {
    $unwind: {
      path: "$marks_stats",
      preserveNullAndEmptyArrays: true
    }
  }
]);
```

**Key Advantages**:
1. Zero duplicate counts: 10 classes and 2 exams remain exactly 10 and 2.
2. `preserveNullAndEmptyArrays: true` ensures students with zero attendance or zero marks are preserved without errors.
3. Completely avoids Cartesian memory blowups.

---

## 6. Mathematical Verification with a Controlled Known Dataset

The accuracy of all formulas and pipelines was verified using a standalone automated test script:  
[`backend/test_analytics_calculations.py`](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/backend/test_analytics_calculations.py).

### Controlled Test Dataset

| Student ID | Name | Classes Attended | Exams & Scores |
| :--- | :--- | :--- | :--- |
| **`KNOWN01`** | Alpha Scholar | 9 Present, 1 Late, 0 Absent (10 total) | Mid-Term: 45/50 (90%), Final: 95/100 (95%) |
| **`KNOWN02`** | Beta Defaulter | 6 Present, 2 Late, 2 Absent (10 total) | Mid-Term: 35/50 (70%), Final: 60/100 (60%) |
| **`KNOWN03`** | Gamma Newbie | 0 sessions (Zero attendance edge case) | 0 tests (Zero marks edge case) |

### Mathematical Predictions vs Real MongoDB Aggregation Results

#### 1. Attendance Percentage
- **`KNOWN01` Expected**: $\frac{9 + (1 \times 0.5)}{10} \times 100 = 95.00\%$
  - **MongoDB Result**: `95.00%` (Match: Exact)
- **`KNOWN02` Expected**: $\frac{6 + (2 \times 0.5)}{10} \times 100 = 70.00\%$
  - **MongoDB Result**: `70.00%` (Match: Exact)

#### 2. Defaulter Flagging (< 75% Cutoff)
- **`KNOWN01` Expected**: Normal ($\ge 75\%$)
  - **MongoDB Result**: Normal (Excluded from defaulters list)
- **`KNOWN02` Expected**: Defaulter ($70\% < 75\%$, Shortfall $= 5.00\%$)
  - **MongoDB Result**: Flagged as Defaulter, Shortfall $= 5.00\%$ (Match: Exact)

#### 3. Academic Rankings
- **`KNOWN01` Average %**: $\frac{90.0 + 95.0}{2} = 92.50\%$
  - **MongoDB Result**: `92.50%` (Rank #1)
- **`KNOWN02` Average %**: $\frac{70.0 + 60.0}{2} = 65.00\%$
  - **MongoDB Result**: `65.00%` (Rank #2)

#### 4. Edge Case Handling (Division by Zero)
- **`KNOWN03` Input**: 0 classes, 0 marks
- **Expected Outcome**: `attendance_pct = 0.00%`, `marks_pct = 0.00%`, No division-by-zero crashes.
- **MongoDB Result**: Handled cleanly with `$cond`, zero errors thrown.

#### 5. Cartesian Double-Counting Prevention
- **`KNOWN01` Input**: 10 attendance records and 2 marks records (140.0 total marks).
- **Cartesian Fault Value**: If naive joins were used, total classes would evaluate to 20 and total marks would evaluate to 1400.0.
- **CampusTrack Subpipeline Result**: Exactly 10 classes, exactly 2 exams, exactly 140.0 marks. (0 duplicate counting).

### Command to Re-Run Verification
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\backend"
.\.venv\Scripts\Activate.ps1
python test_analytics_calculations.py
```
*(Returns 7/7 passing assertions).*

---

## 7. Flutter Visualizations (`fl_chart`)

In the Flutter frontend ([`frontend/lib/screens/reports/reports_screen.dart`](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/screens/reports/reports_screen.dart)), these aggregations are rendered using the `fl_chart` library:

1. **`AttendanceThresholdChart`** ([`attendance_threshold_chart.dart`](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/screens/reports/widgets/attendance_threshold_chart.dart)):
   - Visualizes student attendance percentages.
   - Highlights a distinct horizontal dashed cutoff line at $Y = 75.0\%$.
   - Bars $\ge 75\%$ are rendered in emerald green (`#10B981`); bars $< 75\%$ are rendered in alert red (`#EF4444`).
2. **`SubjectPerformanceChart`** ([`subject_performance_chart.dart`](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/frontend/lib/screens/reports/widgets/subject_performance_chart.dart)):
   - Dual-rod bar chart comparing **Average Score %** against **Pass Rate %** across academic subjects.
   - Interactive touch tooltips showing exact values matching the MongoDB backend.
3. **KPI Cards & Defaulter Notice**:
   - Immediate feedback displaying Total Students, Overall Attendance, Class Average Marks, and Low Attendance count.
   - Clean empty states with custom icons and guidance when no records are found.
