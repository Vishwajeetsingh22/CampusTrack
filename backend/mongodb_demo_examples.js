/**
 * CampusTrack — MongoDB Demonstration & Viva Practical Script
 * 
 * Target Database: campustrack
 * Connection URI: mongodb://localhost:27017/campustrack
 * 
 * This file contains documented examples for all 9 core MongoDB operations required
 * for the college NoSQL demonstration. You can execute these commands in:
 * 1. MongoDB Compass (Embedded mongosh tab at the bottom)
 * 2. Standalone Mongo Shell (mongosh "mongodb://localhost:27017/campustrack")
 * 3. VS Code MongoDB Extension
 */

// Switch to campustrack database
use campustrack;

print("==================================================================");
print("CampusTrack — Student Attendance & Performance Management System");
print("MongoDB NoSQL Demonstration Script");
print("==================================================================");

// ==================================================================
// 1. INSERT DOCUMENTS (CRUD: Create)
// ==================================================================
// How Application Uses It:
// - Triggered by Flutter's "Add Student", "Mark Attendance", and "Record Marks" screens
// - Backend routes: POST /api/students, POST /api/attendance, POST /api/marks
// Compass Demonstration:
// - Navigate to 'campustrack' -> 'students' -> Click "Add Data" -> "Insert Document"

print("\n--- 1. INSERT DOCUMENTS ---");

// Insert a sample viva student
const insertStudentResult = db.students.insertOne({
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
print("Student inserted with _id: " + insertStudentResult.insertedId);

// Insert an attendance record for the student
const insertAttResult = db.attendance.insertOne({
  student_id: "DEMO2001",
  date: "2026-10-25",
  subject: "NoSQL Databases",
  status: "Present",
  remarks: "On time for viva demo",
  created_at: new Date(),
  updated_at: new Date()
});
print("Attendance record inserted with _id: " + insertAttResult.insertedId);

// Insert an examination marks record for the student
const insertMarksResult = db.marks.insertOne({
  student_id: "DEMO2001",
  subject: "NoSQL Databases",
  exam: "Mid-Term",
  marks_obtained: 46.5,
  max_marks: 50.0,
  percentage: 93.0,
  created_at: new Date(),
  updated_at: new Date()
});
print("Marks record inserted with _id: " + insertMarksResult.insertedId);


// ==================================================================
// 2. FIND AND FILTER DOCUMENTS (CRUD: Read)
// ==================================================================
// How Application Uses It:
// - Search bar on Student List screen, department dropdown filters, exam score lists
// - Backend routes: GET /api/students?course=Computer+Science, GET /api/marks?exam=Final
// Compass Demonstration:
// - In collection view, paste the filter into the "Filter" bar and click "Find"

print("\n--- 2. FIND AND FILTER DOCUMENTS ---");

// Example 2A: Simple filter by course and active status
print("\n[2A] Students in Computer Science who are active:");
printjson(db.students.find(
  { course: "Computer Science", active: true },
  { student_id: 1, name: 1, semester: 1, _id: 0 }
).limit(3).toArray());

// Example 2B: Range filter — Exam scores >= 85%
print("\n[2B] High distinction scores (percentage >= 85%):");
printjson(db.marks.find(
  { percentage: { $gte: 85.0 } },
  { student_id: 1, subject: 1, exam: 1, percentage: 1, _id: 0 }
).limit(3).toArray());

// Example 2C: Logical $or filter — Attendance flagged as Late or Absent
print("\n[2C] Attendance logs where status is Late or Absent:");
printjson(db.attendance.find(
  { $or: [{ status: "Late" }, { status: "Absent" }] },
  { student_id: 1, date: 1, subject: 1, status: 1, remarks: 1, _id: 0 }
).limit(3).toArray());


// ==================================================================
// 3. UPDATE DOCUMENTS (CRUD: Update)
// ==================================================================
// How Application Uses It:
// - Flutter's "Edit Profile" screen (PUT /api/students/<id>)
// - Flutter's "Edit Score" dialog (PUT /api/marks/<id>)
// Compass Demonstration:
// - Hover over document, click the Pencil icon, change values, click "Update"

print("\n--- 3. UPDATE DOCUMENTS ---");

// Example 3A: Update student semester and phone using $set
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
print("Updated DEMO2001 semester to 7.");

// Example 3B: Increment marks obtained using $inc and update percentage
db.marks.updateOne(
  { student_id: "DEMO2001", exam: "Mid-Term", subject: "NoSQL Databases" },
  {
    $inc: { marks_obtained: 1.5 },
    $set: { percentage: 96.0, updated_at: new Date() }
  }
);
print("Incremented DEMO2001 marks obtained by 1.5.");


// ==================================================================
// 4. DELETE A TEST DOCUMENT (CRUD: Delete)
// ==================================================================
// How Application Uses It:
// - Delete button on student card with cascading cleanup of attendance and marks
// - Backend route: DELETE /api/students/<id>
// Compass Demonstration:
// - Click Trash Can icon on a document, confirm deletion

print("\n--- 4. DELETE TEST DOCUMENT ---");

// Remove the demo student and its child attendance/marks records (Cascade cleanup)
const delAtt = db.attendance.deleteMany({ student_id: "DEMO2001" });
const delMarks = db.marks.deleteMany({ student_id: "DEMO2001" });
const delStu = db.students.deleteOne({ student_id: "DEMO2001" });

print(`Cascade delete summary: Students deleted=${delStu.deletedCount}, Attendance=${delAtt.deletedCount}, Marks=${delMarks.deletedCount}`);


// ==================================================================
// 5. CREATE AND INSPECT INDEXES (Performance & Uniqueness)
// ==================================================================
// How Application Uses It:
// - Enforces database uniqueness on roll numbers and compound assessment keys
// - Accelerates search queries from O(N) COLLSCAN down to O(log N) IXSCAN
// Compass Demonstration:
// - Click the "Indexes" tab in Compass to view index names, memory sizes, and uniqueness

print("\n--- 5. INDEX INSPECTION & QUERY EXPLAIN ---");

// List all active indexes on the students collection
print("\nActive indexes on 'students':");
printjson(db.students.getIndexes());

// List compound unique index on 'attendance'
print("\nActive indexes on 'attendance':");
printjson(db.attendance.getIndexes());

// Explain execution plan: Demonstrating IXSCAN (Index Scan) vs COLLSCAN
print("\nQuery Explain Plan for indexed lookup by student_id:");
const explainPlan = db.students.find({ student_id: "STU1001" }).explain("executionStats");
print("Execution Stage: " + explainPlan.executionStats.executionStages.stage);
print("Index Used: " + explainPlan.executionStats.executionStages.indexName);
print("Total Documents Examined: " + explainPlan.executionStats.totalDocsExamined);
print("Returned Documents: " + explainPlan.executionStats.nReturned);


// ==================================================================
// 6. VALIDATE DOCUMENT STRUCTURE ($jsonSchema)
// ==================================================================
// How Application Uses It:
// - Enforces collection governance at database level, preventing corrupted data
// - Blocks invalid emails, out-of-range semesters, or negative marks
// Compass Demonstration:
// - Click the "Validation" tab in Compass to view rules and JSON Schema

print("\n--- 6. SCHEMA VALIDATION TESTING ---");

// Demonstrate that MongoDB rejects an invalid document
try {
  db.students.insertOne({
    student_id: "INVALID99",
    name: "Bad Record",
    semester: 12, // Invalid: validator requires 1 <= semester <= 8
    email: "not-an-email", // Invalid email regex
    course: "Computer Science"
  });
  print("WARNING: Invalid document was unexpectedly accepted!");
} catch (e) {
  print("SUCCESS: MongoDB $jsonSchema rejected invalid document as expected!");
  print("Error code: " + e.code + " (" + e.codeName + ")");
}


// ==================================================================
// 7. AGGREGATE ATTENDANCE PERCENTAGES (Pipeline with Late Rule)
// ==================================================================
// How Application Uses It:
// - Generates attendance analytics and defaulter identification (<75%)
// - Backend route: GET /api/reports/attendance
// Compass Demonstration:
// - Go to 'attendance' collection -> "Aggregations" tab -> Paste pipeline stages

print("\n--- 7. ATTENDANCE AGGREGATION PIPELINE ---");

const attendanceAgg = db.attendance.aggregate([
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
]).toArray();

print("Attendance Aggregation Summary (Bottom 3 showing defaulters):");
printjson(attendanceAgg.slice(0, 3));


// ==================================================================
// 8. CALCULATE AVERAGE MARKS AND RANKINGS (Pipeline)
// ==================================================================
// How Application Uses It:
// - Powers the College Leaderboard in Flutter
// - Backend route: GET /api/reports/rankings
// Compass Demonstration:
// - Go to 'marks' collection -> "Aggregations" tab

print("\n--- 8. ACADEMIC RANKINGS AGGREGATION PIPELINE ---");

const rankingsAgg = db.marks.aggregate([
  {
    $group: {
      _id: "$student_id",
      total_exams: { $sum: 1 },
      avg_percentage: { $avg: "$percentage" }
    }
  },
  {
    $project: {
      student_id: "$_id",
      _id: 0,
      total_exams: 1,
      avg_percentage: { $round: ["$avg_percentage", 2] }
    }
  },
  { $sort: { avg_percentage: -1 } }
]).toArray();

print("Top 3 Academic Rankers:");
printjson(rankingsAgg.slice(0, 3));


// ==================================================================
// 9. JOIN COLLECTIONS USING $lookup (Without Double-Counting)
// ==================================================================
// How Application Uses It:
// - Combines student names with attendance and marks in unified dashboard metrics
// - Backend routes: GET /api/reports/attendance, GET /api/reports/unified
// Compass Demonstration:
// - Build stage with $lookup operator, specify localField and foreignField

print("\n--- 9. $lookup JOIN PIPELINE ---");

const joinResult = db.attendance.aggregate([
  {
    $group: {
      _id: "$student_id",
      total_classes: { $sum: 1 },
      present_count: { $sum: { $cond: [{ $eq: ["$status", "Present"] }, 1, 0] } }
    }
  },
  {
    $lookup: {
      from: "students",
      localField: "_id",
      foreignField: "student_id",
      as: "student_profile"
    }
  },
  {
    $unwind: "$student_profile"
  },
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
  { $limit: 3 }
]).toArray();

print("Joined Student Data ($lookup result):");
printjson(joinResult);

print("\n==================================================================");
print("✅ ALL 9 MONGODB DEMONSTRATION EXAMPLES EXECUTED SUCCESSFULLY!");
print("==================================================================");
