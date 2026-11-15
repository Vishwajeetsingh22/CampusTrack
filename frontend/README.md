# CampusTrack — Flutter Frontend Client

The frontend for **CampusTrack (Student Attendance and Performance Management System)** is built using Flutter & Dart with Material 3, clean Navy & Indigo styling, and responsive layout support for mobile phones, tablets, and desktop/web browsers.

---

## 1. Directory Structure

```
frontend/
├── pubspec.yaml               # Flutter dependencies (provider, fl_chart, http, intl)
├── lib/
│   ├── main.dart              # MultiProvider setup, Material 3 theme, adaptive tab controller
│   ├── config/
│   │   ├── api_config.dart    # Dynamic Base URL: 10.0.2.2 for Android Emulator, 127.0.0.1 for Web/Windows
│   │   └── app_theme.dart     # Navy (#0F172A) and Indigo (#4338CA) Material 3 theme configuration
│   ├── models/
│   │   ├── student_model.dart # StudentModel (student_id, name, course, semester, email, active, phone)
│   │   ├── attendance_model.dart # AttendanceModel & AttendanceSummaryModel
│   │   ├── marks_model.dart   # MarksModel & MarksSummaryModel
│   │   └── report_models.dart # DashboardStatsModel, DefaulterStudentModel, StudentRankingModel
│   ├── services/
│   │   ├── api_service.dart   # HTTP client with timeouts, status code handlers, and user-friendly error formatting
│   │   ├── student_service.dart # Student CRUD & search API integration
│   │   ├── attendance_service.dart # Attendance recording, filtering, and summary API integration
│   │   ├── marks_service.dart # Marks recording, score range validation, and summary API integration
│   │   └── report_service.dart # Dashboard metrics, defaulters (<75%), rankings, and analytics API
│   ├── providers/             # Provider State Management
│   │   ├── dashboard_provider.dart # Dashboard metrics and charts state
│   │   ├── student_provider.dart   # Student directory, live search, and filter state
│   │   ├── attendance_provider.dart # Attendance records and status filtering state
│   │   ├── marks_provider.dart     # Examination marks and dynamic percentage preview state
│   │   └── report_provider.dart    # Tabbed reports center state
│   ├── widgets/
│   │   ├── app_drawer.dart         # College navigation drawer with server URL configurator
│   │   ├── responsive_scaffold.dart # Adaptive layout: BottomNav on phones, NavigationRail on tablets
│   │   ├── stat_kpi_card.dart      # Clean KPI metric card with trend badges
│   │   ├── empty_state_view.dart   # Empty state view with icons and action buttons
│   │   ├── error_state_view.dart   # Error card with retry button
│   │   ├── loading_indicator.dart  # Centered progress loader
│   │   └── confirm_dialog.dart     # Confirmation modal for delete actions
│   └── screens/
│       ├── splash/
│       │   └── splash_screen.dart       # Welcome screen with backend health verification
│       ├── dashboard/
│       │   ├── dashboard_screen.dart    # KPI metrics, quick actions, fl_chart charts
│       │   └── widgets/
│       │       ├── attendance_chart_card.dart  # fl_chart BarChart (Present vs Absent vs Late)
│       │       └── course_pie_chart_card.dart  # fl_chart PieChart (Enrollment by course)
│       ├── students/
│       │   ├── student_list_screen.dart    # Student directory, search bar, course chips
│       │   ├── student_form_screen.dart    # Add / Edit student with form validation
│       │   └── student_detail_screen.dart  # 360° profile with Attendance & Marks tabs
│       ├── attendance/
│       │   ├── attendance_list_screen.dart # Date picker, subject filter, status chips
│       │   └── mark_attendance_screen.dart # Present, Absent, Late marking form
│       ├── marks/
│       │   ├── marks_list_screen.dart      # Score cards, subject & exam filters
│       │   └── marks_form_screen.dart      # Add / Edit scores with live percentage preview
│       └── reports/
│           └── reports_screen.dart         # Tabbed analytics: Attendance %, Performance, Rankings, Defaulters (<75%)
└── test/
    └── widget_test.dart       # Widget test verifying CampusTrackApp render
```

---

## 2. How to Run the App

### Option A: On Android Emulator

#### 1. Create an Android Emulator (if none exists)
In Windows PowerShell or Android Studio:
```powershell
flutter emulators --create --name Pixel_CampusTrack
```
*(Alternatively, open **Android Studio > Virtual Device Manager** and click **Create Virtual Device**).*

#### 2. Launch the Emulator
```powershell
flutter emulators --launch Pixel_CampusTrack
```

#### 3. Run CampusTrack on Android Emulator
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"
flutter run
```
*Note: The app automatically detects Android and connects to `http://10.0.2.2:5000` (the host computer's Flask backend).*

---

### Option B: On Chrome / Web Browser (Instant Testing)
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"
flutter run -d chrome
```

---

### Option C: Run Automated Tests
```powershell
cd "c:\Users\admin\OneDrive\Desktop\NoSQLs Activity-2\frontend"
flutter test
```
*(Result: 100% passing tests).*
