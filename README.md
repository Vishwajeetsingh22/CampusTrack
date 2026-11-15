# 🎓 CampusTrack – Student Attendance & Performance Management System

\<p align="center">
&#x20; \<img src="[https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter\&logoColor=white)" />
&#x20; \<img src="[https://img.shields.io/badge/Python-Flask-3776AB?logo=python&logoColor=white](https://img.shields.io/badge/Python-Flask-3776AB?logo=python\&logoColor=white)" />
&#x20; \<img src="[https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb&logoColor=white](https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb\&logoColor=white)" />
&#x20; \<img src="[https://img.shields.io/badge/Project-NoSQL%20Activity--2-blue](https://img.shields.io/badge/Project-NoSQL%20Activity--2-blue)" />
\</p>

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
- **MongoDB Integration:** Efficient NoSQL database management.
- **REST API:** Backend communication using Flask REST APIs.

## 🛠️ Technology Stack

| Technology     | Purpose                        |
| -------------- | ------------------------------ |
| Flutter & Dart | Frontend Development           |
| Python Flask   | Backend Development            |
| MongoDB        | NoSQL Database                 |
| PyMongo        | Database Connectivity          |
| Provider       | State Management               |
| fl_chart       | Data Visualization             |
| REST API       | Frontend-Backend Communication |
| Git & GitHub   | Version Control                |

## 📂 Project Structure

```text
CampusTrack/
│
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
│
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
│
├── Report_Screenshots/
│
├── PROJECT_REPORT.md
├── LIVE_DEMONSTRATION_SCRIPT.md
├── VIVA_QUESTIONS_AND_ANSWERS.md
├── MONGODB_AGGREGATIONS_GUIDE.md
├── MONGODB_COLLEGE_ACTIVITY_PRACTICAL.md
│
└── README.md
```

## 📸 Application & Implementation Screenshots

The following screenshots demonstrate the MongoDB implementation and database operations performed in CampusTrack.

### Database Configuration & Schema

\<p align="center">
&#x20; \<img src="Report_Screenshots/Fig_02_Database_Collections.png" width="85%" alt="MongoDB Database Collections"/>
&#x20; \<br/>
&#x20; \<b>Fig 1. MongoDB Database Collections\</b>
\</p>

\<p align="center">
&#x20; \<img src="Report_Screenshots/Fig_03_Students_Validation.png" width="85%" alt="Student Schema Validation"/>
&#x20; \<br/>
&#x20; \<b>Fig 2. Student Schema Validation\</b>
\</p>

\<p align="center">
&#x20; \<img src="Report_Screenshots/Fig_04_Unique_Compound_Indexes.png" width="85%" alt="MongoDB Unique Compound Indexes"/>
&#x20; \<br/>
&#x20; \<b>Fig 3. Unique Compound Indexes\</b>
\</p>

### MongoDB CRUD Operations & Queries

\<p align="center">
&#x20; \<img src="Report_Screenshots/Fig_05_Insert_Documents.png" width="85%" alt="MongoDB Insert Documents"/>
&#x20; \<br/>
&#x20; \<b>Fig 4. Inserting Documents\</b>
\</p>

\<p align="center">
&#x20; \<img src="Report_Screenshots/Fig_06_Find_Filter_Queries.png" width="85%" alt="MongoDB Find and Filter Queries"/>
&#x20; \<br/>
&#x20; \<b>Fig 5. Find and Filter Queries\</b>
\</p>

### Aggregation & Advanced Database Operations

\<p align="center">
&#x20; \<img src="Report_Screenshots/Fig_16_Unified_Student_Profile.png" width="85%" alt="Unified Student Profile"/>
&#x20; \<br/>
&#x20; \<b>Fig 6. Unified Student Profile Using Aggregation\</b>
\</p>

> **Note:** Keep all screenshot images inside the `Report_Screenshots` folder using the exact filenames referenced above. Add the remaining application and database screenshots from Figures 1–18 to the gallery as appropriate.

## ⚙️ Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Vishwajeetsingh22/CampusTrack.git
cd CampusTrack
```

### 2. Start MongoDB

Ensure MongoDB Community Server is installed and running.

```powershell
Get-Service MongoDB
Start-Service MongoDB
```

### 3. Setup Flask Backend

```bash
cd backend

python -m venv .venv

.venv\Scripts\activate

pip install -r requirements.txt
```

Configure your MongoDB connection details in the environment configuration.

Initialize sample database records:

```bash
python db/seed_data.py
```

Start the backend:

```bash
python app.py
```

Backend URL:

```text
http://127.0.0.1:5000
```

### 4. Setup Flutter Frontend

Open another terminal:

```bash
cd frontend

flutter pub get

flutter run -d chrome
```

You can also run the application using an Android emulator or a supported physical device.

## 🗄️ MongoDB Concepts Demonstrated

- NoSQL Document-Oriented Database Design
- MongoDB Collections and Documents
- CRUD Operations
- JSON Schema Validation
- Unique and Compound Indexes
- Query Filtering and Sorting
- Aggregation Framework
- `$match`, `$group`, `$lookup`, `$project` and other pipeline stages
- Student Attendance and Performance Analytics

## 🧪 Testing

The project includes backend and frontend testing.

```bash
# Backend tests
python test_backend_suite.py

# Analytics tests
python test_analytics_calculations.py

# Integration tests
python test_e2e_integration.py

# Flutter analysis
flutter analyze

# Flutter tests
flutter test
```

## 🎯 Academic Information

**Course:** NoSQL Databases (25MCAG301)
**Activity:** Activity-2 – Mini Project
**Programme:** Master of Computer Applications (MCA)
**University:** Jain (Deemed-to-be University)

## 👨‍💻 Author

**Vishwajeet Singh**

- **USN:** 25MCAR0219
- **Programme:** Master of Computer Applications (MCA)
- **University:** Jain (Deemed-to-be University)
- **GitHub:** [Vishwajeetsingh22](https://github.com/Vishwajeetsingh22)

---

\<p align="center">
&#x20; \<b>CampusTrack – Smart Attendance. Better Academic Insights.\</b>
&#x20; \<br/>
&#x20; Developed as part of the MCA NoSQL Databases Activity-2 Mini Project.
\</p>
