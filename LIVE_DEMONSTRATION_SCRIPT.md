# CampusTrack — Step-by-Step Live Demonstration Script
## Practical College Evaluation & Viva Guide

This script provides an exact, step-by-step procedure to showcase your **CampusTrack** project to professors, evaluators, and external examiners. Follow the steps sequentially for a smooth presentation.

---

## 0. Pre-Demonstration Setup Checklist (Before Examiner Arrives)

1. **Verify MongoDB Service is Running**:
   ```powershell
   Get-Service MongoDB
   ```
   *(Ensure Status is `Running`)*.
2. **Verify Database Seed Data in MongoDB Compass**:
   - Open **MongoDB Compass** and connect to `mongodb://localhost:27017/`.
   - Open the `campustrack` database.
   - Verify collections exist: `students` (12), `attendance` (110), `marks` (96).
3. **Start Flask REST API Backend**:
   ```powershell
   cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\backend"
   .\.venv\Scripts\python.exe app.py
   ```
   *(Wait until you see: `Starting CampusTrack Flask server on 0.0.0.0:5000`)*.
4. **Launch Flutter Frontend**:
   ```powershell
   cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"
   flutter run -d chrome     # Or: flutter run -d windows
   ```

---

## 1. Opening Statement (30 Seconds)

> *"Good morning / afternoon, respected examiners. Today I am presenting **CampusTrack — Student Attendance and Academic Performance Management System**.*  
> *The application is built using a modern decoupled architecture: a cross-platform **Flutter** presentation frontend, a modular **Python Flask REST API**, and a **MongoDB NoSQL Community Server** persistence layer.*  
> *Rather than treating MongoDB merely as key-value storage, CampusTrack demonstrates core NoSQL database engineering: declarative `$jsonSchema` validators, compound unique indexes, and server-side multi-stage aggregation pipelines that compute attendance percentages, defaulter lists, and student rankings with zero Cartesian double-counting."*

---

## 2. Step-by-Step Demonstration Walkthrough

### Step 1: Health Check & Database Discovery (1 Minute)
* **Action in Browser / Postman**:
  - Open: `http://127.0.0.1:5000/health`
* **What to Show**:
  - Show the JSON output:
    ```json
    {
      "healthy": true,
      "service": "CampusTrack API",
      "database_details": {
        "connected": true,
        "database": "campustrack",
        "collections": {
          "students": 12,
          "attendance": 110,
          "marks": 96
        }
      }
    }
    ```
* **What to Say**:
  > *"Here we verify that the Flask backend is actively connected to our local MongoDB instance at port 27017, and our collections are populated with consistent seed data."*

---

### Step 2: Show MongoDB Compass Architecture (1.5 Minutes)
* **Action in MongoDB Compass**:
  1. Open database `campustrack`.
  2. Click on the `students` collection -> Navigate to **Validation** tab.
     - **Explain**: Point out the `$jsonSchema` rules enforcing required fields (`student_id`, `name`, `email`, `semester`), email regex, and integer semester boundaries (1 to 8).
  3. Click on the `attendance` collection -> Navigate to **Indexes** tab.
     - **Explain**: Highlight the compound unique index `idx_attendance_unique_entry` on `(student_id, date, subject)`.
     - *Say: "This database-level index physically prevents duplicate attendance records for the same student on the same date and subject."*
  4. Click on `marks` collection -> Navigate to **Indexes** tab.
     - **Explain**: Highlight compound index on `(student_id, subject, exam)`.

---

### Step 3: Admin Dashboard & KPI Cards in Flutter (1 Minute)
* **Action in Flutter App**:
  - Open the **Dashboard** screen.
* **What to Show**:
  - Top 3 KPI Cards:
    - **Total Students**: `12`
    - **Overall Attendance**: `~86.4%`
    - **Average Marks**: `~78.2%`
  - Course Distribution Bar/Pie Chart (showing Computer Science, Information Technology, Electronics).
  - Status Breakdown Pill Indicators (`Present`, `Absent`, `Late`).
* **What to Say**:
  > *"Notice that none of these values are hardcoded. Each metric is fetched dynamically from MongoDB through our `/api/dashboard` endpoint, computed by server-side aggregations."*

---

### Step 4: Student Management CRUD Demonstration (2 Minutes)
* **Action in Flutter App**:
  1. Click **Students** in the navigation bar.
  2. Test Search: Type `Aarav` or `Sharma` in the search bar. Show real-time filtering.
  3. Filter by Course: Tap `Information Technology` chip. Show list updates.
  4. Add a New Student:
     - Tap **Add Student** (`+` button).
     - Enter Student ID: `STU2026`
     - Enter Name: `Demo Candidate`
     - Select Course: `Computer Science`
     - Select Semester: `6`
     - Enter Email: `demo.candidate@campus.edu`
     - Tap **Save Student**.
  5. **Show Proof in MongoDB Compass**:
     - Switch to Compass -> Click `students` -> Click **Refresh**.
     - Point out the newly inserted document: `STU2026`.
  6. **Demonstrate Duplicate Unique Constraint**:
     - In Flutter, tap **Add Student** again.
     - Re-enter the same ID: `STU2026` with another name.
     - Tap **Save Student**.
     - Show the red error alert: *"Student with ID 'STU2026' already exists (HTTP 409 Conflict)"*.
     - *Say: "Both our application service and MongoDB's unique index reject duplicate IDs."*

---

### Step 5: Daily Attendance Logging (1.5 Minutes)
* **Action in Flutter App**:
  1. Navigate to **Attendance** screen.
  2. Tap **Mark Attendance** (`+` button).
  3. Select Student: `Demo Candidate (STU2026)`
  4. Date: Leave as today's date.
  5. Select Subject: `NoSQL Systems`
  6. Tap Status: **Present**
  7. Tap **Record Attendance**. Show success snackbar.
  8. **Demonstrate Attendance Duplicate Rejection**:
     - Tap **Mark Attendance** again for `STU2026`, same subject `NoSQL Systems`, same date.
     - Choose **Late**.
     - Tap **Record Attendance**.
     - Show error message: *"Duplicate attendance entry rejected (HTTP 409 Conflict)"*.

---

### Step 6: Examination Marks Entry & Boundary Validation (1.5 Minutes)
* **Action in Flutter App**:
  1. Navigate to **Marks** screen.
  2. Tap **Record Marks** (`+` button).
  3. Select Student: `Demo Candidate (STU2026)`
  4. Select Subject: `NoSQL Systems`
  5. Select Exam: `Mid-Term Exam`
  6. **Test Validation Failure**:
     - Enter Marks Obtained: `110` (out of Max Marks `100`).
     - Show real-time validation error: *"Marks obtained cannot exceed max marks"*.
  7. **Enter Valid Score**:
     - Enter Marks Obtained: `88` (Max: `100`).
     - Point out the automatically previewed percentage: **88.0%**.
     - Tap **Save Marks**. Show success feedback.

---

### Step 7: Advanced Reports & Aggregation Visualizations (2 Minutes)
* **Action in Flutter App**:
  1. Navigate to **Reports** screen.
  2. **Low Attendance Defaulters Tab (< 75%)**:
     - Point out the defaulters list: `Tanvi Gupta (0.0%)`, `Aditya Verma (20.0%)`.
     - Point out the calculated shortfall (e.g., `55.0% shortfall`).
     - Show the **Attendance Threshold Chart** with the dashed red 75% cutoff line.
  3. **Class Merit Rankings Tab**:
     - Switch to the **Rankings** tab.
     - Show the class rank order sorted strictly by descending percentage (#1, #2, #3).
  4. **Subject Performance Tab**:
     - Show the dual-bar chart comparing Average Marks vs. Pass Rate across subjects.

---

### Step 8: Safe Deletion & Cascade Verification (1 Minute)
* **Action in Flutter App**:
  1. Open the student list -> Find `Demo Candidate (STU2026)`.
  2. Tap the student card -> Student Detail view opens.
  3. Tap the **Delete (Trash)** icon -> Confirm in the dialog.
  4. **Show in MongoDB Compass**:
     - Refresh `students`: `STU2026` is gone.
     - Filter `attendance` for `{ student_id: "STU2026" }`: **0 records found** (cascaded).
     - Filter `marks` for `{ student_id: "STU2026" }`: **0 records found** (cascaded).
  5. *Say: "CampusTrack prevents orphan records by automatically cascading deletions to all child collections."*

---

## 3. Concluding Summary (30 Seconds)

> *"In summary, CampusTrack fulfills every academic NoSQL project criterion: full CRUD functionality, declarative `$jsonSchema` validation, B-Tree index optimization, automated cascade cleanup, multi-stage aggregations without Cartesian double-counting, and a responsive Flutter user interface. Thank you."*
