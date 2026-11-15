# CampusTrack — 25 Comprehensive Viva Questions & Answers
## College Practical Examination & Oral Evaluation Guide

This document contains 25 high-probability viva questions organized by category, with concise, academically rigorous answers.

---

### Category A: MongoDB & NoSQL Core Concepts

#### Q1. What is a NoSQL database, and why is MongoDB classified as a document store?
**Answer**:  
A NoSQL (Not Only SQL) database provides non-relational, flexible data models designed for horizontal scalability, high write throughput, and schema flexibility. MongoDB is a document store because it stores data records as BSON (Binary JSON) documents inside collections rather than static tabular rows inside fixed tables.

#### Q2. What is BSON, and how does it differ from standard JSON?
**Answer**:  
BSON stands for Binary JSON. While JSON only supports text strings, numbers, booleans, arrays, and null, BSON extends this format by encoding data in a compact binary representation and supporting additional types including `ObjectId`, `Date`, `int32`, `int64`, `double`, and binary data buffers.

#### Q3. What is an `ObjectId` in MongoDB, and what does it consist of?
**Answer**:  
`ObjectId` is a 12-byte unique BSON identifier automatically generated as the default primary key (`_id`) for every document. It consists of:
- **4 bytes**: Unix epoch timestamp representing document creation time.
- **5 bytes**: Random value unique to the machine and process.
- **3 bytes**: Incrementing counter initialized to a random value.

#### Q4. Why did you choose MongoDB over a relational database (RDBMS) like MySQL for CampusTrack?
**Answer**:  
1. **Direct Object Mapping**: Student documents map directly to Dart and Python object representations with zero impedance mismatch.
2. **Schema Agility**: Academic attributes (such as remarks, flexible contact details, or new grading rubrics) can evolve without costly `ALTER TABLE` locks.
3. **High-Speed Analytics**: MongoDB's native aggregation pipeline performs complex statistics (average attendance, class rankings, defaulters) inside the database memory engine much faster than multi-table SQL joins.

#### Q5. What is the difference between embedding documents and referencing documents in MongoDB?
**Answer**:  
- **Embedding**: Nesting child documents directly within a parent document (1:1 or small 1:N). Best for tightly coupled data read together (e.g., student addresses).
- **Referencing**: Storing child documents in a separate collection with a foreign key reference (`student_id`). Best for unbounded 1:N or M:N relationships (such as hundreds of daily attendance logs) to avoid exceeding MongoDB's 16 MB document size limit. CampusTrack uses referencing for `attendance` and `marks`.

---

### Category B: Indexes & Performance Optimization

#### Q6. What is an index in MongoDB, and what data structure does it use?
**Answer**:  
An index is a specialized data structure that holds a small, sorted portion of the collection's data set to allow fast traversals. MongoDB uses **B-Tree (Balanced Tree)** data structures for standard and compound indexes.

#### Q7. What compound indexes did you create in CampusTrack, and what operational constraints do they enforce?
**Answer**:  
1. **`attendance`**: `{ student_id: 1, date: 1, subject: 1 }` with `{ unique: true }`.  
   *Constraint*: Prevents recording multiple attendance logs for the same student on the same date and subject.
2. **`marks`**: `{ student_id: 1, subject: 1, exam: 1 }` with `{ unique: true }`.  
   *Constraint*: Prevents entering duplicate exam scores for the same student and subject.

#### Q8. What is the difference between a `COLLSCAN` and an `IXSCAN` in MongoDB query execution?
**Answer**:  
- **`COLLSCAN` (Collection Scan)**: MongoDB inspects every single document in the collection from start to finish ($O(N)$ time complexity). Extremely inefficient for large datasets.
- **`IXSCAN` (Index Scan)**: MongoDB navigates the B-Tree index directly to locate matching document pointers ($O(\log N)$ time complexity). CampusTrack's winning explain plan confirms `EXPRESS_IXSCAN` / `IXSCAN` with `docsExamined: 1`.

#### Q9. Can you create a unique index on a field that already has duplicate records?
**Answer**:  
No. In MongoDB, creating a unique index on a collection containing pre-existing duplicate keys will fail with a `DuplicateKeyError`. All duplicates must be cleaned up or merged before the unique index can be built.

---

### Category C: Schema Validation (`$jsonSchema`)

#### Q10. What is `$jsonSchema` in MongoDB, and at what layer is it enforced?
**Answer**:  
`$jsonSchema` is a declarative schema validation rule configured on a collection using the standard JSON Schema draft-04 specification. It is enforced directly at the **database engine level** on all `insert` and `update` commands.

#### Q11. What happens if a client attempts to insert a document violating `$jsonSchema`?
**Answer**:  
MongoDB immediately rejects the operation and raises an `OperationFailure` with error message `"Document failed validation"`. The Flask backend catches this exception and converts it into a clean client-facing `HTTP 422 Unprocessable Entity` or `HTTP 400 Bad Request`.

#### Q12. Give an example of a validation rule you implemented in CampusTrack.
**Answer**:  
In the `students` collection, `semester` is restricted to integer values between 1 and 8:
```json
"semester": {
  "bsonType": "int",
  "minimum": 1,
  "maximum": 8,
  "description": "Semester must be an integer between 1 and 8 - required"
}
```

---

### Category D: MongoDB Aggregation Framework

#### Q13. What is the MongoDB Aggregation Pipeline?
**Answer**:  
The Aggregation Pipeline is a multi-stage framework for data processing and transformation. Documents enter a multi-stage pipeline where each stage (such as filtering `$match`, grouping `$group`, reshaping `$project`, or sorting `$sort`) transforms the documents before passing them to the next stage.

#### Q14. Explain the difference between `$match` and `$filter`.
**Answer**:  
- **`$match`**: A pipeline stage that acts like a query filter, selecting which documents enter the pipeline or pass to subsequent stages.
- **`$filter`**: An array expression operator used inside `$project` or `$addFields` to select a subset of elements within an embedded array based on a condition.

#### Q15. How does CampusTrack compute attendance percentages in MongoDB while preventing division-by-zero crashes?
**Answer**:  
CampusTrack weights attendance as: $\text{Present} = 1.0$, $\text{Late} = 0.5$, $\text{Absent} = 0.0$.  
To avoid fatal division-by-zero errors when a student has 0 recorded classes, we wrap the calculation in a `$cond` expression:
```javascript
"attendance_pct": {
  "$cond": [
    { "$gt": ["$total_classes", 0] },
    { "$round": [{ "$multiply": [{ "$divide": [{ "$add": ["$present", { "$multiply": ["$late", 0.5] }] }, "$total_classes"] }, 100] }, 2] },
    0.0
  ]
}
```

#### Q16. What is the Cartesian product problem during `$lookup`, and how did you resolve it?
**Answer**:  
When joining `students` with `attendance` and `marks` via naive sequential `$lookup` stages, MongoDB produces an $N \times M$ Cartesian product, duplicating rows and distorting total sums.  
CampusTrack resolves this by using **correlated subqueries with inner `$group` stages** inside each `$lookup`. This groups attendance and marks logs into summary metrics *before* joining with the student profile, preserving strict 1:1 join cardinality with **zero double-counting**.

#### Q17. How do `$lookup` and `$unwind` work together?
**Answer**:  
`$lookup` performs a left outer join and stores matching foreign documents in an array field. `$unwind` deconstructs that array, outputting a separate document for each array element. Setting `preserveNullAndEmptyArrays: true` ensures that students with zero matching records are not dropped from the report.

---

### Category E: Python Flask REST API & Architecture

#### Q18. What is a REST API, and what HTTP methods are used in CampusTrack?
**Answer**:  
A REST (Representational State Transfer) API is a stateless architectural style for web services communicating over HTTP with JSON payloads. CampusTrack uses:
- **`GET`**: Retrieve students, attendance logs, marks, and reports.
- **`POST`**: Create students, record attendance, and add exam marks.
- **`PUT`**: Modify student details, update attendance status, or edit scores.
- **`DELETE`**: Remove students and cascade delete associated records.

#### Q19. What HTTP status codes does CampusTrack return and why?
**Answer**:  
- **`200 OK`**: Successful query, update, or deletion.
- **`201 Created`**: Successful document insertion.
- **`400 Bad Request`**: Validation errors, negative marks, or malformed IDs.
- **`404 Not Found`**: Non-existent student, attendance log, or marks ID.
- **`409 Conflict`**: Duplicate unique keys (`student_id` or compound index collision).
- **`500 Internal Server Error`**: Unexpected database connectivity failures.

#### Q20. What is CORS, and why is it necessary in CampusTrack?
**Answer**:  
CORS (Cross-Origin Resource Sharing) is a browser security mechanism that restricts web applications from making HTTP requests to a different domain, port, or protocol. Flask-CORS is configured on `/api/*` to allow the Flutter web and mobile clients (running on localhost or Android emulator `10.0.2.2`) to access the Flask server on port 5000.

#### Q21. How do you prevent broken relational references when deleting a student?
**Answer**:  
CampusTrack implements **application-level cascade deletion** in `student_service.py`. When `DELETE /api/students/<id>` is invoked, the service first deletes the student from `students`, and then executes `db.attendance.delete_many({"student_id": id})` and `db.marks.delete_many({"student_id": id})`, eliminating all orphan records.

---

### Category F: Flutter Frontend & State Management

#### Q22. What is the difference between `StatelessWidget` and `StatefulWidget` in Flutter?
**Answer**:  
- **`StatelessWidget`**: Immutable widget whose configuration does not change over time (e.g., `StatKpiCard`, `EmptyStateView`).
- **`StatefulWidget`**: Widget accompanied by a mutable `State` object that can trigger UI rebuilds via `setState()` when user input or data changes (e.g., `MarkAttendanceScreen`, `StudentFormScreen`).

#### Q23. Why did you use Provider for state management in Flutter?
**Answer**:  
`Provider` wraps `ChangeNotifier` to implement the Observer pattern. It cleanly decouples business logic and HTTP service calls from presentation widgets. When new data arrives or an entity is modified, calling `notifyListeners()` automatically rebuilds only the subscribed widgets without redrawing the entire screen.

#### Q24. How does the Flutter app communicate with Flask on the Android Emulator?
**Answer**:  
The Android Emulator runs in an isolated virtual network where `127.0.0.1` refers to the emulator itself. To connect to the host Windows machine running Flask, Android routes requests to special IP alias **`10.0.2.2`**. CampusTrack's `ApiConfig.baseUrl` handles this automatically.

#### Q25. How do you handle UI states when loading, on network errors, or when a list is empty?
**Answer**:  
CampusTrack defines dedicated reusable widgets for each state:
- **Loading State**: Displays a branded `LoadingIndicator` with custom message.
- **Empty State**: Renders `EmptyStateView` with an icon, title, description, and an action button (e.g. "Enroll First Student").
- **Error State**: Displays `ErrorStateView` with the error reason and a "Try Again" retry button that re-fetches the endpoint.
- **Success State**: Renders the populated `ListView.separated` or `fl_chart` view.
