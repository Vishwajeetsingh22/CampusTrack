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
- **Reports Generation:** Analyze attendance percentages and academic performance.
- **MongoDB Integration:** Manage application data using a NoSQL database.
- **REST API:** Connect the Flutter frontend with the Flask backend.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Frontend development |
| Python Flask | Backend development |
| MongoDB | NoSQL database |
| PyMongo | Database connectivity |
| Provider | State management |
| fl_chart | Data visualization |
| REST API | Frontend-backend communication |
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
│   └── test_backend_suite.py
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
├── Report_Screenshots/
├── PROJECT_REPORT.md
├── LIVE_DEMONSTRATION_SCRIPT.md
├── VIVA_QUESTIONS_AND_ANSWERS.md
├── MONGODB_AGGREGATIONS_GUIDE.md
├── MONGODB_COLLEGE_ACTIVITY_PRACTICAL.md
└── README.md
```

## 📸 Application & Implementation Screenshots

The screenshots below are displayed directly from the repository. Keep the image files in a folder named `Report_Screenshots` at the repository root. The image names in the links must match the actual filenames, including uppercase and lowercase letters.

### Database Configuration & Schema

| MongoDB Collections | Student Schema Validation |
|---|---|
| ![MongoDB Collections](Report_screenshots/Fig_02_Database_Collections.png) | ![Student Schema Validation](Report_screenshots/Fig_03_Students_Validation.png) |

| Unique Compound Indexes | Insert Documents |
|---|---|
| ![Unique Compound Indexes](Report_screenshots/Fig_04_Unique_Compound_Indexes.png) | ![Insert Documents](Report_screenshots/Fig_05_Insert_Documents.png) |

### MongoDB CRUD Operations & Queries

| Find and Filter Queries | Unified Student Profile |
|---|---|
| ![Find and Filter Queries](Report_screenshots/Fig_06_Find_Filter_Queries.png) | ![Unified Student Profile](Report_screenshots/Fig_16_Unified_Student_Profile.png) |

> **Screenshot note:** The project ZIP provided for review did not contain a `Report_Screenshots` directory. Add your captured screenshots to that folder and use the exact filenames referenced above, or edit the image paths in this section to match your actual filenames. GitHub will show the images once the files are committed and pushed.

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
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Configure the MongoDB connection settings using your local environment configuration. Do not commit passwords, connection strings, or `.env` files containing secrets.

If the project uses the provided database seeder, initialize sample data with:

```powershell
python db\seed_data.py
```

Start the backend:

```powershell
python app.py
```

Backend address (local development): `http://127.0.0.1:5000`

### 4. Set Up the Flutter Frontend

Open another terminal from the repository root:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

You can also run the app on a configured Android emulator or supported physical device using `flutter run`.

## 🗄️ MongoDB Concepts Demonstrated

- Document-oriented NoSQL database design
- MongoDB collections and documents
- Create, Read, Update, and Delete (CRUD) operations
- JSON Schema validation
- Unique and compound indexes
- Query filtering and sorting
- Aggregation framework and pipeline stages such as `$match`, `$group`, `$lookup`, and `$project`
- Attendance and academic performance analytics

## 🧪 Testing

Run the relevant tests from the appropriate project directory. Example backend commands:

```powershell
cd backend
python test_backend_suite.py
python test_analytics_calculations.py
python test_e2e_integration.py
```

Run Flutter checks from the frontend directory:

```powershell
cd frontend
flutter analyze
flutter test
```

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
  <strong>CampusTrack – Smart Attendance. Better Academic Insights.</strong><br />
  Developed as part of the MCA NoSQL Databases Activity-2 Mini Project.
</p>
