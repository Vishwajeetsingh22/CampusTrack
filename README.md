# CampusTrack — Student Attendance and Performance Management System
> **Full-Stack NoSQL Academic Project built with Flutter, Python Flask, and MongoDB**

[![Flutter](https://img.shields.io/badge/Flutter-3.33+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Python Flask](https://img.shields.io/badge/Flask-3.x-000000?logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-8.0-47A248?logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![License](https://img.shields.io/badge/License-Academic-blue.svg)]()

---

## 📌 Project Overview

**CampusTrack** is an end-to-end college academic administration system designed to track daily session attendance, record continuous internal assessment marks, and generate institutional analytics in real-time.

### Key Technology Stack
- **Frontend**: Flutter & Dart (Cross-platform Material 3 responsive UI, Provider state management, `fl_chart` data visualizations).
- **Backend**: Python Flask REST API (Modular Blueprints, PyMongo connection pooling, centralized JSON serialization, CORS enabled).
- **Database**: MongoDB Community Server 8.0 (Document store, `$jsonSchema` validators, compound unique indexes, multi-stage aggregation pipelines).
- **Tools**: Windows 11 PowerShell, MongoDB Compass, Android Studio, VS Code / Google Antigravity.

---

## 📁 Repository Structure

```text
NoSQLs Activity-2/
├── CampusTrack_Project_Report.docx       # Editable Word Document Project Report (Academic Format)
├── PROJECT_REPORT.md                     # Markdown Project Report (14 Complete Chapters)
├── LIVE_DEMONSTRATION_SCRIPT.md          # Step-by-Step Live Demo Walkthrough for Viva
├── VIVA_QUESTIONS_AND_ANSWERS.md         # 25 High-Probability Viva Questions & Detailed Answers
├── MONGODB_AGGREGATIONS_GUIDE.md         # Master Aggregation Pipeline Reference & Explanations
├── MONGODB_COLLEGE_ACTIVITY_PRACTICAL.md # 9 MongoDB Shell / Compass Viva Practical Exercises
│
├── backend/                              # Python Flask REST API
│   ├── app.py                            # Flask application factory, routes, and CORS setup
│   ├── config.py                         # Environment configuration (never hardcoded)
│   ├── requirements.txt                  # Python dependencies
│   ├── .env                              # MongoDB connection parameters
│   ├── db/
│   │   ├── connection.py                 # PyMongo singleton client and health checks
│   │   ├── schema_validator.py           # MongoDB $jsonSchema validation rules
│   │   ├── indexes.py                    # Single & compound unique indexes setup
│   │   └── seed_data.py                  # Idempotent database seeder (12 students, 110 logs, 96 marks)
│   ├── routes/                           # Modular API Blueprints (students, attendance, marks, reports, demo)
│   ├── services/                         # Business logic & MongoDB aggregation pipelines
│   ├── test_backend_suite.py             # Isolated automated test suite (18/18 tests passed)
│   ├── test_analytics_calculations.py    # Math formula verification suite (7/7 passed)
│   ├── test_e2e_integration.py           # Live database CRUD integration tests (8/8 passed)
│   └── test_mongodb_viva_examples.py     # Automated viva demonstration tests (9/9 passed)
│
└── frontend/                             # Flutter Mobile/Web Application
    ├── pubspec.yaml                      # Flutter dependencies (provider, fl_chart, http)
    ├── lib/
    │   ├── main.dart                     # App entry point & theme provider
    │   ├── config/                       # AppTheme palette & ApiConfig base URL
    │   ├── models/                       # Strongly typed Dart data models
    │   ├── services/                     # Centralized HTTP REST API clients
    │   ├── providers/                    # Reactive ChangeNotifier state providers
    │   ├── screens/                      # UI screens (Dashboard, Students, Attendance, Marks, Reports)
    │   └── widgets/                      # Reusable UI components (StatKpiCard, EmptyState, ErrorState, Loading)
    └── test/
        ├── widget_test.dart              # Flutter smoke test
        └── models_and_widgets_test.dart  # Model parsing and widget state tests (10/10 passed)
```

---

## ⚡ Quick Start & Running Commands

Open separate Windows PowerShell windows for the database, backend, and frontend:

### 1. MongoDB Database
Ensure the MongoDB Windows service is active:
```powershell
# Verify service status
Get-Service MongoDB

# If stopped, start service:
Start-Service MongoDB
```

### 2. Python Flask Backend
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\backend"

# (Optional: If first time) create venv & install dependencies
python -m venv .venv
.\.venv\Scripts\pip.exe install -r requirements.txt

# Seed sample data into MongoDB (idempotent, safe)
.\.venv\Scripts\python.exe db\seed_data.py

# Start Flask REST API server
.\.venv\Scripts\python.exe app.py
```
*Backend will start on `http://0.0.0.0:5000`.* Verify via `GET http://127.0.0.1:5000/health`.

### 3. Flutter Frontend
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"

# Fetch Flutter packages
flutter pub get

# Run on Chrome Browser
flutter run -d chrome

# Or run on Windows Desktop
flutter run -d windows

# Or run on an Android Emulator / Physical Device
flutter run
```

---

## 🧪 Automated Quality & Test Verification

All test suites have been verified with a **100% pass rate**:

```powershell
# 1. Run Isolated Backend Test Suite (18 tests on isolated db)
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\backend"
.\.venv\Scripts\python.exe test_backend_suite.py

# 2. Run Mathematical Aggregation Calculations Test (7 tests)
.\.venv\Scripts\python.exe test_analytics_calculations.py

# 3. Run Live End-to-End Database Integration Test (8 tests)
.\.venv\Scripts\python.exe test_e2e_integration.py

# 4. Run 9 MongoDB Practical Viva Examples (9 tests)
.\.venv\Scripts\python.exe test_mongodb_viva_examples.py

# 5. Run Flutter Static Analysis (0 errors, 0 warnings)
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"
flutter analyze

# 6. Run Flutter Unit and Widget Tests (10 tests)
flutter test
```

---

## 📊 Core MongoDB Features Demonstrated

1. **Schema Validation (`$jsonSchema`)**:
   - Enforced directly by the database engine on `students`, `attendance`, and `marks`.
   - Validates regex patterns, required properties, and integer ranges ($1 \le \text{semester} \le 8$).
2. **Compound Unique Indexes**:
   - `students`: `{ student_id: 1 }` (Unique).
   - `attendance`: `{ student_id: 1, date: 1, subject: 1 }` (Unique).
   - `marks`: `{ student_id: 1, subject: 1, exam: 1 }` (Unique).
3. **Advanced Aggregation Pipelines**:
   - **Attendance Percentage**: Formula with $\text{Late} = 0.5$ and zero-division guard (`$cond`).
   - **Low Attendance Defaulters**: Identifies students $< 75.0\%$ with shortfall calculation.
   - **Class Rankings**: Cumulative performance ordering with 1:1 joined student profiles.
   - **Unified 360 Profile**: Uses correlated subqueries within `$lookup` containing inner `$group` stages to eliminate Cartesian product row multiplication ($N \times M$).

---

## 🔒 Local Development vs. Production Deployment

| Architectural Dimension | Local Development (Current Setup) | Production Public Deployment (Target Architecture) |
| :--- | :--- | :--- |
| **Flask Server** | Local dev server (`python app.py`) on `http://127.0.0.1:5000` | Production WSGI runner (Gunicorn / Uvicorn) behind Nginx reverse proxy |
| **Network Protocol** | Unencrypted HTTP for local development | Strict TLS 1.3 encryption over HTTPS with automated Let's Encrypt certificates |
| **Database Host** | Local standalone MongoDB Community Server on `localhost:27017` | Managed MongoDB cluster (e.g. MongoDB Atlas / AWS DocumentDB) with automated backups |
| **Database Access** | Local loopback interface without external internet exposure | **Strictly restricted database access**: VPC peering or IP whitelist allowing ONLY the Flask backend |
| **Database Port (27017)**| Accessible only locally on host machine | **NEVER exposed publicly to the open Internet** (blocked by firewall / security groups) |
| **CORS Policy** | Permissive `origins: "*"` to allow Flutter web and Android emulator | Strict whitelist: `origins: ["https://campustrack.college.edu"]` |
| **Secrets Management** | `.env` file (git-ignored, never committed) | Cloud Secrets Manager (AWS Secrets Manager, GCP Secret Manager, or Docker secrets) |
| **Flutter Client** | Debug build with cleartext enabled for emulator (`10.0.2.2`) | Release build (`flutter build web --release`) with HTTPS-only `ApiConfig.baseUrl` |

---

## 🚀 Pre-Deployment Checklist for Future Public Demos

Follow this checklist when preparing CampusTrack for a public cloud demonstration or university hosting.

> [!WARNING]
> **Safety Rule**: No cloud deployment, domain purchasing, or external publishing will be executed without explicit user confirmation.

### Phase 1: Database Provisioning & Hardening
- [ ] **Provision Managed MongoDB**: Create a secured cluster on MongoDB Atlas (Free Tier M0 or dedicated M10+).
- [ ] **Configure Network Access / IP Whitelisting**:
  - Add **ONLY** the static IP address(es) of your deployed Flask backend service.
  - **Never** allow `0.0.0.0/0` (allow access from anywhere) in production.
- [ ] **Create Dedicated Database User**:
  - Assign least-privilege role: `readWrite` on `campustrack` database only.
  - Generate a high-entropy password (minimum 24 characters).
- [ ] **Verify Encryption in Transit**:
  - Ensure the connection string uses `mongodb+srv://` with mandatory TLS/SSL.
- [ ] **Execute Seed & Schema Initialization**:
  - Run `seed_data.py` once to build collections, indexes, and `$jsonSchema` validators.

### Phase 2: Backend API Service Deployment
- [ ] **Containerize or Host as API Service**:
  - Deploy Flask to a managed container or PaaS service (e.g. Render, Railway, AWS ECS, Google Cloud Run).
- [ ] **Configure Production WSGI Server**:
  - Run using Gunicorn: `gunicorn -w 4 -b 0.0.0.0:$PORT "app:create_app()"`
- [ ] **Inject Environment Variables via Cloud Secret Store**:
  - Set `FLASK_ENV=production`
  - Set `FLASK_DEBUG=0`
  - Set `SECRET_KEY` to a cryptographically secure random 64-char hex string
  - Set `MONGO_URI` to the secured MongoDB Atlas URI
  - Set `MONGO_DB_NAME=campustrack`
- [ ] **Restrict CORS Origins**:
  - In `app.py`, update CORS origins from `*` to the exact public frontend domain:
    `CORS(app, resources={r"/api/*": {"origins": ["https://campustrack.yourdomain.com"]}})`
- [ ] **Verify TLS / HTTPS Termination**:
  - Confirm the API responds strictly over `https://api.yourdomain.com/health` with HTTP 200.

### Phase 3: Frontend Client Configuration & Release Build
- [ ] **Update API Base URL**:
  - In `frontend/lib/config/api_config.dart`, update `_productionBaseUrl`:
    ```dart
    static const String _productionBaseUrl = 'https://api.yourdomain.com/api/';
    ```
- [ ] **Zero Database Credentials Verification**:
  - Verify Flutter source contains zero database connection strings, passwords, or port numbers.
- [ ] **Compile Production Release Artifacts**:
  - For Web: `flutter build web --release` (deploy static output to Firebase Hosting, Cloudflare Pages, or Netlify).
  - For Android APK: `flutter build apk --release --split-per-abi`
- [ ] **Audit Android Permissions**:
  - Ensure `usesCleartextTraffic="true"` remains isolated to `debug/AndroidManifest.xml` and is absent from release APKs.

---

## 📄 College Submission Materials Included

- 📘 [CampusTrack_Project_Report.docx](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/CampusTrack_Project_Report.docx) — Fully styled editable Word document report.
- 📑 [PROJECT_REPORT.md](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/PROJECT_REPORT.md) — Complete 14-chapter academic project report.
- 🎯 [LIVE_DEMONSTRATION_SCRIPT.md](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/LIVE_DEMONSTRATION_SCRIPT.md) — Step-by-step viva presentation guide with verbal prompts.
- 💡 [VIVA_QUESTIONS_AND_ANSWERS.md](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/VIVA_QUESTIONS_AND_ANSWERS.md) — 25 core viva questions covering NoSQL, Flutter, and Flask.
- 🔍 [MONGODB_AGGREGATIONS_GUIDE.md](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/MONGODB_AGGREGATIONS_GUIDE.md) — Detailed aggregation pipeline breakdowns.
- 🛠️ [MONGODB_COLLEGE_ACTIVITY_PRACTICAL.md](file:///c:/Users/admin/OneDrive/Desktop/NoSQLs%20Activity-2/MONGODB_COLLEGE_ACTIVITY_PRACTICAL.md) — 9 live practical lab queries.

