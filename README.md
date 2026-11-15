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

All project screenshots are available in the `screenshots/` directory.

### 🗄️ Database Configuration & Schema

<table>
<tr>
<th width="50%">MongoDB Collections</th>
<th width="50%">Student Schema Validation</th>
</tr>
<tr>
<td align="center">
<a href="screenshots/Fig_02_Database_Collections.png">
<img src="screenshots/Fig_02_Database_Collections.png" width="100%" alt="MongoDB Collections"/>
</a>
</td>
<td align="center">
<a href="screenshots/Fig_03_Students_Validation.png">
<img src="screenshots/Fig_03_Students_Validation.png" width="100%" alt="Student Schema Validation"/>
</a>
</td>
</tr>
<tr>
<th>Unique Compound Indexes</th>
<th>Insert Documents</th>
</tr>
<tr>
<td align="center">
<a href="screenshots/Fig_04_Unique_Compound_Indexes.png">
<img src="screenshots/Fig_04_Unique_Compound_Indexes.png" width="100%" alt="Unique Compound Indexes"/>
</a>
</td>
<td align="center">
<a href="screenshots/Fig_05_Insert_Documents.png">
<img src="screenshots/Fig_05_Insert_Documents.png" width="100%" alt="Insert Documents"/>
</a>
</td>
</tr>
</table>

### 🔍 MongoDB CRUD Operations & Queries

<table>
<tr>
<th width="50%">Find & Filter Queries</th>
<th width="50%">Unified Student Profile</th>
</tr>
<tr>
<td align="center">
<a href="screenshots/Fig_06_Find_Filter_Queries.png">
<img src="screenshots/Fig_06_Find_Filter_Queries.png" width="100%" alt="Find and Filter Queries"/>
</a>
</td>
<td align="center">
<a href="screenshots/Fig_16_Unified_Student_Profile.png">
<img src="screenshots/Fig_16_Unified_Student_Profile.png" width="100%" alt="Unified Student Profile"/>
</a>
</td>
</tr>
</table>

### 📌 More Project Screenshots

Explore the complete collection of application and MongoDB implementation screenshots in the [screenshots folder](screenshots/).

> Click any screenshot to view its full-size image.


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
