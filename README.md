# 🎓 CampusTrack – Student Attendance & Performance Management System

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Python-Flask-3776AB?logo=python&logoColor=white" alt="Python Flask" />
  <img src="https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb&logoColor=white" alt="MongoDB" />
  <img src="https://img.shields.io/badge/Project-NoSQL%20Activity--2-blue" alt="NoSQL Activity 2" />
</p>

**CampusTrack** is a Student Attendance and Performance Management System developed to simplify student record management, attendance tracking, and academic performance monitoring. It uses Flutter for the frontend, Python Flask for the backend, and MongoDB as its NoSQL database.

---

## 📌 Project Overview

CampusTrack provides an integrated platform for managing student information, monitoring attendance, recording academic marks, and generating performance reports.

### ✨ Key Features

- **Student Management:** Add, view, update, and manage student records.
- **Attendance Tracking:** Record and monitor daily student attendance.
- **Performance Management:** Store and manage internal assessment marks.
- **Dashboard Analytics:** Display student statistics and academic insights.
- **Reports:** Analyze attendance percentages and academic performance.
- **MongoDB Integration:** Manage data using a document-oriented NoSQL database.
- **REST API:** Connect the Flutter frontend with the Flask backend.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Frontend development |
| Python Flask | Backend REST API |
| MongoDB | NoSQL database |
| PyMongo | MongoDB connectivity |
| Provider | Flutter state management |
| fl_chart | Data visualization |
| Git & GitHub | Version control |

## 📂 Project Structure

```text
CampusTrack/
├── backend/
│   ├── app.py
│   ├── config.py
│   ├── requirements.txt
│   ├── db/
│   │   ├── connection.py
│   │   ├── schema_validator.py
│   │   ├── indexes.py
│   │   └── seed_data.py
│   ├── routes/
│   ├── services/
│   └── test_*.py
├── frontend/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   ├── models/
│   │   ├── services/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   └── test/
├── screenshots/
├── .gitignore
├── README.md
└── project documentation files
```

## 📸 Application & Implementation Screenshots

The screenshots are stored in the repository's **`screenshots/`** directory (lowercase). The image links below use that exact directory name. GitHub paths are case-sensitive, so keep the directory and image filenames exactly as shown.

### Database Configuration & Schema

<table>
  <tr>
    <td align="center" width="50%"><strong>MongoDB Collections</strong><br/><img src="screenshots/Fig_02_Database_Collections.png" alt="MongoDB Collections" width="100%"/></td>
    <td align="center" width="50%"><strong>Student Schema Validation</strong><br/><img src="screenshots/Fig_03_Students_Validation.png" alt="Student Schema Validation" width="100%"/></td>
  </tr>
  <tr>
    <td align="center"><strong>Unique Compound Indexes</strong><br/><img src="screenshots/Fig_04_Unique_Compound_Indexes.png" alt="Unique Compound Indexes" width="100%"/></td>
    <td align="center"><strong>Insert Documents</strong><br/><img src="screenshots/Fig_05_Insert_Documents.png" alt="Insert Documents" width="100%"/></td>
  </tr>
</table>

### MongoDB CRUD Operations & Queries

<table>
  <tr>
    <td align="center" width="50%"><strong>Find & Filter Queries</strong><br/><img src="screenshots/Fig_06_Find_Filter_Queries.png" alt="Find and Filter Queries" width="100%"/></td>
    <td align="center" width="50%"><strong>Unified Student Profile</strong><br/><img src="screenshots/Fig_16_Unified_Student_Profile.png" alt="Unified Student Profile" width="100%"/></td>
  </tr>
</table>

> **Screenshot filename note:** The repository screenshot folder is confirmed as `screenshots/`. The six image filenames above are the filenames previously referenced in this README draft; they must match the actual files in that folder exactly. If your pushed image filenames differ, update the corresponding `src` values. Add further rows for the remaining screenshots using the same two-column table layout.

## ⚙️ Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Vishwajeetsingh22/CampusTrack.git
cd CampusTrack
```

### 2. Start MongoDB

Make sure MongoDB Community Server is installed and running. On Windows PowerShell:

```powershell
Get-Service MongoDB
Start-Service MongoDB
```

### 3. Set Up the Flask Backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Configure the MongoDB connection using the environment variables expected by the backend. Do not commit `.env` files or database credentials.

If the project uses the supplied seed script, initialize sample data with:

```powershell
python db\seed_data.py
```

Start the backend:

```powershell
python app.py
```

Local backend address (if using the default configuration): `http://127.0.0.1:5000`

### 4. Set Up the Flutter Frontend

Open another terminal:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

You can also run the app on a configured Android emulator or supported device. Ensure the frontend API base URL points to the running backend.

## 🗄️ MongoDB Concepts Demonstrated

- Document-oriented NoSQL database design
- Collections and documents
- CRUD operations
- JSON Schema validation
- Unique and compound indexes
- Query filtering and sorting
- Aggregation framework, including stages such as `$match`, `$group`, `$lookup`, and `$project`
- Attendance and academic performance analytics

## 🧪 Testing

Run the tests from the relevant project directories. Backend examples:

```powershell
cd backend
python test_backend_suite.py
python test_analytics_calculations.py
python test_e2e_integration.py
```

Flutter checks (from the `frontend/` directory):

```powershell
flutter analyze
flutter test
```

Run only test files that are present in your checked-out project.

## 🎯 Academic Information

- **Course:** NoSQL Databases (25MCAG301)
- **Activity:** Activity-2 – Mini Project
- **Programme:** Master of Computer Applications (MCA)
- **University:** Jain (Deemed-to-be University)

## 👨‍💻 Author

**Vishwajeet Singh**

- **USN:** 25MCAR0219
- **Programme:** Master of Computer Applications (MCA)
- **University:** Jain (Deemed-to-be University)
- **GitHub:** [Vishwajeetsingh22](https://github.com/Vishwajeetsingh22)

---

<p align="center">
  <strong>CampusTrack – Smart Attendance. Better Academic Insights.</strong><br/>
  Developed as part of the MCA NoSQL Databases Activity-2 Mini Project.
</p>
