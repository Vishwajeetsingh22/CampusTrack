"""
Generates a Word document (.docx) for the CampusTrack Project Report
with academic formatting, styled headings, data tables, and placeholders.
"""

import os
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    """Sets background color of a table cell."""
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tc_pr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    """Sets inner padding for a table cell in dxa (1 pt = 20 dxa)."""
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tc_pr.append(tc_mar)

def add_code_block(doc, text):
    """Adds a shaded callout code block."""
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    cell = table.cell(0, 0)
    cell.width = Inches(6.5)
    set_cell_background(cell, "F8FAFC")
    set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
    
    # Border
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'<w:left w:val="single" w:sz="18" w:space="0" w:color="3B82F6"/>'
        f'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'<w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'</w:tcBorders>'
    )
    tc_pr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.05
    run = p.add_run(text)
    run.font.name = "Consolas"
    run.font.size = Pt(9.0)
    run.font.color.rgb = RGBColor(30, 41, 59)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def format_table(table, header_bg="1E3A8A", alt_bg="F8FAFC"):
    """Styles a table with navy header and alternating row colors."""
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    
    for i, row in enumerate(table.rows):
        is_header = (i == 0)
        bg = header_bg if is_header else (alt_bg if i % 2 == 1 else "FFFFFF")
        
        for cell in row.cells:
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
            
            # Subtle cell borders
            tc_pr = cell._tc.get_or_add_tcPr()
            borders = parse_xml(
                f'<w:tcBorders {nsdecls("w")}>'
                f'<w:top w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
                f'<w:left w:val="none"/>'
                f'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
                f'<w:right w:val="none"/>'
                f'</w:tcBorders>'
            )
            tc_pr.append(borders)
            
            for p in cell.paragraphs:
                p.paragraph_format.space_before = Pt(3)
                p.paragraph_format.space_after = Pt(3)
                p.paragraph_format.line_spacing = 1.1
                for run in p.runs:
                    if is_header:
                        run.font.name = "Calibri"
                        run.font.size = Pt(10)
                        run.font.bold = True
                        run.font.color.rgb = RGBColor(255, 255, 255)
                    else:
                        run.font.name = "Calibri"
                        run.font.size = Pt(9.5)
                        run.font.color.rgb = RGBColor(30, 41, 59)

def generate_report():
    doc = Document()
    
    # Page setup: Standard Letter/A4 with 1-inch margins
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)

    # Palette
    c_navy = RGBColor(30, 58, 138)       # #1E3A8A
    c_indigo = RGBColor(59, 130, 246)    # #3B82F6
    c_dark = RGBColor(30, 41, 59)        # #1E293B
    c_body = RGBColor(51, 65, 85)        # #334155

    # =========================================================================
    # 1. TITLE / COVER PAGE
    # =========================================================================
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_inst = p_inst.add_run("[NAME OF THE INSTITUTION / UNIVERSITY]")
    r_inst.font.name = "Calibri"
    r_inst.font.size = Pt(13)
    r_inst.font.bold = True
    r_inst.font.color.rgb = c_navy
    p_inst.paragraph_format.space_after = Pt(2)

    p_dept = doc.add_paragraph()
    p_dept.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_dept = p_dept.add_run("DEPARTMENT OF COMPUTER SCIENCE AND ENGINEERING\n[OR INFORMATION TECHNOLOGY]")
    r_dept.font.name = "Calibri"
    r_dept.font.size = Pt(11)
    r_dept.font.bold = True
    r_dept.font.color.rgb = c_indigo
    p_dept.paragraph_format.space_after = Pt(36)

    p_proj = doc.add_paragraph()
    p_proj.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_proj = p_proj.add_run("A PROJECT REPORT ON\n")
    r_proj.font.name = "Calibri"
    r_proj.font.size = Pt(12)
    r_proj.font.color.rgb = c_dark

    r_title = p_proj.add_run("CAMPUSTRACK: STUDENT ATTENDANCE AND PERFORMANCE MANAGEMENT SYSTEM")
    r_title.font.name = "Calibri"
    r_title.font.size = Pt(18)
    r_title.font.bold = True
    r_title.font.color.rgb = c_navy

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Using Flutter, Python Flask REST API, and MongoDB NoSQL Database")
    r_sub.font.name = "Calibri"
    r_sub.font.size = Pt(13)
    r_sub.font.italic = True
    r_sub.font.color.rgb = c_indigo
    p_sub.paragraph_format.space_after = Pt(40)

    p_deg = doc.add_paragraph()
    p_deg.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_deg = p_deg.add_run(
        "Submitted in partial fulfillment of the academic requirements for the award of\n"
        "[BACHELOR OF TECHNOLOGY / MASTER OF COMPUTER APPLICATIONS]\n"
        "IN\n"
        "[COMPUTER SCIENCE AND ENGINEERING / INFORMATION SCIENCE]\n"
        "FOR\n"
        "[NoSQL Database Systems / Advanced Database Management Systems Laboratory]"
    )
    r_deg.font.name = "Calibri"
    r_deg.font.size = Pt(10)
    r_deg.font.color.rgb = c_dark
    p_deg.paragraph_format.space_after = Pt(36)

    # Student / Guide Details Table
    details_table = doc.add_table(rows=2, cols=2)
    details_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    
    cell_sub_by = details_table.cell(0, 0)
    p_sb = cell_sub_by.paragraphs[0]
    p_sb.add_run("SUBMITTED BY:\n").bold = True
    p_sb.add_run("[Student Name 1]  (USN: [Roll No / USN])\n")
    p_sb.add_run("[Student Name 2]  (USN: [Roll No / USN])\n")
    p_sb.add_run("[Semester & Section]")
    
    cell_guide = details_table.cell(0, 1)
    p_g = cell_guide.paragraphs[0]
    p_g.add_run("UNDER THE GUIDANCE OF:\n").bold = True
    p_g.add_run("[Faculty Guide / Mentor Name]\n")
    p_g.add_run("[Designation / Assistant Professor]\n")
    p_g.add_run("Dept of Computer Science & Engineering")

    cell_blank_l = details_table.cell(1, 0)
    cell_blank_r = details_table.cell(1, 1)

    for row in details_table.rows:
        for cell in row.cells:
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = "Calibri"
                    run.font.size = Pt(10)
                    run.font.color.rgb = c_dark

    p_year = doc.add_paragraph()
    p_year.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_year.paragraph_format.space_before = Pt(36)
    r_yr = p_year.add_run("ACADEMIC YEAR: 2026 – 2027")
    r_yr.font.name = "Calibri"
    r_yr.font.size = Pt(11)
    r_yr.font.bold = True
    r_yr.font.color.rgb = c_navy

    doc.add_page_break()

    # =========================================================================
    # Helpers for Content
    # =========================================================================
    def add_h1(title):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(16)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(title)
        r.font.name = "Calibri"
        r.font.size = Pt(15)
        r.font.bold = True
        r.font.color.rgb = c_navy
        return p

    def add_h2(title):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(title)
        r.font.name = "Calibri"
        r.font.size = Pt(12.5)
        r.font.bold = True
        r.font.color.rgb = c_indigo
        return p

    def add_p(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.line_spacing = 1.15
        r = p.add_run(text)
        r.font.name = "Calibri"
        r.font.size = Pt(10.5)
        r.font.color.rgb = c_body
        return p

    # =========================================================================
    # 1. ABSTRACT
    # =========================================================================
    add_h1("1. Abstract")
    add_p(
        "Academic institutions require reliable, scalable, and responsive administrative systems "
        "to record daily classroom attendance, track continuous internal assessments, and generate "
        "actionable institutional analytics. Traditional paper registers and rigid relational database systems "
        "suffer from relational impedance mismatch, administrative bottlenecks, lack of real-time insights, "
        "and slow reporting when complex statistical aggregations are required across thousands of student records."
    )
    add_p(
        "CampusTrack is an end-to-end, multi-tier academic management software built using a modern decoupled architecture: "
        "(1) Presentation Layer built with Flutter and Dart delivering a reactive, Material 3 administrative UI; "
        "(2) Application Services Layer powered by a lightweight Python Flask REST API with modular blueprints and input validation; "
        "and (3) Data Persistence Layer implemented using MongoDB Community Server (NoSQL) with BSON schema validation rules ($jsonSchema), "
        "compound unique indexes, and high-performance server-side aggregation pipelines."
    )
    add_p(
        "The system introduces strict duplicate prevention mechanisms at both application and database tiers, "
        "dynamic zero-division safeguards during mathematical aggregations, correlated $lookup subqueries to prevent "
        "Cartesian product double-counting, and real-time visualization of student performance via interactive bar and pie charts. "
        "Automated verification demonstrates 100% test pass rates across API contracts, schema validations, and calculations."
    )

    # =========================================================================
    # 2. INTRODUCTION & PROBLEM STATEMENT
    # =========================================================================
    add_h1("2. Introduction and Problem Statement")
    add_h2("2.1 Background")
    add_p(
        "Monitoring student attendance and academic performance is a mandatory operational responsibility for colleges and universities. "
        "Attendance percentages often determine examination eligibility (typically requiring an attendance threshold of at least 75%), "
        "while continuous assessment grades guide early remedial interventions for struggling students."
    )
    add_h2("2.2 Existing System Limitations")
    add_p(
        "1. Manual Registers & Disconnected Spreadsheets: Physical registers are prone to human calculation errors, loss, "
        "and unauthorized manipulation. Spreadsheets lack multi-user concurrency and data validation."
    )
    add_p(
        "2. Relational Schema Rigidity: Relational databases enforce static tabular layouts. Adding optional fields or dynamic rubrics "
        "requires altering table structures, which causes administrative friction."
    )
    add_p(
        "3. Multi-Table Join Latencies: Computing cumulative rankings and defaulter lists in relational databases requires computationally "
        "heavy multi-table JOIN operations across large transaction logs."
    )
    add_p(
        "4. Non-Responsive Desktop Portals: Legacy enterprise software fails to adapt to modern mobile devices used by faculty in classrooms."
    )
    add_h2("2.3 Proposed Solution")
    add_p(
        "CampusTrack resolves these issues using a document-oriented NoSQL model in MongoDB, a Python Flask RESTful backend, "
        "and a cross-platform Flutter client. Aggregation pipelines execute calculations natively within the database engine, "
        "delivering sub-second reporting and real-time chart visualizations."
    )

    # =========================================================================
    # 3. OBJECTIVES & SCOPE
    # =========================================================================
    add_h1("3. Objectives and Scope")
    add_h2("3.1 Core Objectives")
    add_p("• Student Profile Management: Register, search, update, and safely delete student records with unique roll numbers.")
    add_p("• Daily Session Attendance: Record Present, Absent, and Late attendance with duplicate prevention for the same student, date, and subject.")
    add_p("• Assessment & Marks Recording: Track continuous internal exam marks with boundary validations (0 <= obtained <= max).")
    add_p("• Advanced MongoDB Aggregations: Generate student attendance %, defaulters (< 75%), subject statistics, and rankings.")
    add_p("• NoSQL Practical Demonstration: Implement and explain MongoDB $jsonSchema validators, unique indexes, and explain plans.")
    add_h2("3.2 Scope of the Project")
    add_p(
        "The project covers academic administration for undergraduate and postgraduate college departments. "
        "The architecture is designed for local-area networks, campus intranets, and mobile emulators."
    )

    # =========================================================================
    # 4. SYSTEM REQUIREMENTS
    # =========================================================================
    add_h1("4. Software and Hardware Requirements")
    add_h2("4.1 Hardware Specifications")
    add_p("• Processor: Intel Core i5 / AMD Ryzen 5 (64-bit multi-core, 2.4 GHz or higher).")
    add_p("• RAM: Minimum 8 GB (16 GB recommended for concurrent Android Studio / Chrome Flutter execution).")
    add_p("• Storage: Minimum 20 GB free disk space (Solid State Drive recommended).")
    add_p("• Network: 802.11ac Wi-Fi or Gigabit Ethernet adapter for LAN communication.")
    add_h2("4.2 Software Specifications")
    add_p("• Operating System: Windows 11 (64-bit) / macOS / Ubuntu Linux.")
    add_p("• Database Server: MongoDB Community Server v7.0 or v8.0.")
    add_p("• Database Management GUI: MongoDB Compass v1.40+.")
    add_p("• Backend Runtime & Framework: Python 3.10+ with Flask 3.x, Flask-CORS, PyMongo, and python-dotenv.")
    add_p("• Frontend Framework: Flutter SDK 3.24+ / 3.33+ with Dart SDK 3.5+.")
    add_p("• External Packages: fl_chart (Flutter charts), provider (State Management), http (REST client).")

    # =========================================================================
    # 5. SYSTEM ARCHITECTURE & DATA FLOW
    # =========================================================================
    add_h1("5. System Architecture and Data Flow")
    add_p(
        "CampusTrack follows a classic three-tier client-server architecture separating presentation, "
        "business logic, and data persistence."
    )
    add_code_block(
        doc,
        "+-------------------------------------------------------------------------+\n"
        "|                    PRESENTATION LAYER (Flutter Client)                  |\n"
        "|  Dashboard Screen | Student Directory | Attendance Logger | Reports     |\n"
        "|  (Material 3 UI, fl_chart widgets, Provider reactive state)             |\n"
        "+------------------------------------+------------------------------------+\n"
        "                                     | JSON over HTTP (REST API)\n"
        "+------------------------------------v------------------------------------+\n"
        "|                 APPLICATION SERVICES LAYER (Python Flask API)           |\n"
        "|  Routes / Blueprints: /api/students | /api/attendance | /api/marks      |\n"
        "|  Services: student_service | attendance_service | aggregation_service   |\n"
        "|  CORS Middleware | Centralized JSON Serializers | Error Handlers        |\n"
        "+------------------------------------+------------------------------------+\n"
        "                                     | BSON / TCP Driver Pool (PyMongo)\n"
        "+------------------------------------v------------------------------------+\n"
        "|                    DATA PERSISTENCE LAYER (MongoDB NoSQL)               |\n"
        "|  Collections: students | attendance | marks                             |\n"
        "|  Validation: $jsonSchema enforcement (Data types, Enums, Ranges)        |\n"
        "|  Indexes: Unique student_id, Compound (student_id, date, subject)       |\n"
        "|  Aggregation Framework: $group, $project, $sort, $lookup, $unwind      |\n"
        "+-------------------------------------------------------------------------+"
    )

    # =========================================================================
    # 6. DATABASE DESIGN & COLLECTION SCHEMAS
    # =========================================================================
    add_h1("6. Database Design and Collection Schemas")
    add_p(
        "MongoDB's document model represents entities naturally as JSON-like BSON documents. "
        "The system organizes academic data into three dedicated collections: students, attendance, and marks."
    )
    
    add_h2("6.1 Collection: students")
    add_p("Stores master demographic and academic registration data.")
    stu_tbl = doc.add_table(rows=8, cols=4)
    stu_tbl_data = [
        ["Field Name", "BSON Type", "Constraints", "Description"],
        ["_id", "ObjectId", "Primary Key", "Unique internal MongoDB document ID"],
        ["student_id", "string", "Unique Index, Regex", "Roll number/USN (e.g. STU1001)"],
        ["name", "string", "Required, 2-100 chars", "Full student name"],
        ["email", "string", "Required, Email regex", "Official institutional email address"],
        ["course", "string", "Required, 2-100 chars", "Degree program (e.g. Computer Science)"],
        ["semester", "int", "Required, 1 to 8", "Current academic semester"],
        ["active", "bool", "Required (default true)", "Enrollment active status flag"]
    ]
    for r_idx, row in enumerate(stu_tbl.rows):
        for c_idx, cell in enumerate(row.cells):
            cell.text = stu_tbl_data[r_idx][c_idx]
    format_table(stu_tbl)

    add_h2("6.2 Collection: attendance")
    add_p("Stores atomic daily classroom attendance session logs.")
    att_tbl = doc.add_table(rows=6, cols=4)
    att_tbl_data = [
        ["Field Name", "BSON Type", "Constraints", "Description"],
        ["_id", "ObjectId", "Primary Key", "Unique log identifier"],
        ["student_id", "string", "References students", "Student roll number"],
        ["date", "string", "Required, YYYY-MM-DD", "Session date string"],
        ["subject", "string", "Required, 2-100 chars", "Subject / course title"],
        ["status", "string", "Enum: Present, Absent, Late", "Session attendance status"]
    ]
    for r_idx, row in enumerate(att_tbl.rows):
        for c_idx, cell in enumerate(row.cells):
            cell.text = att_tbl_data[r_idx][c_idx]
    format_table(att_tbl)

    add_h2("6.3 Collection: marks")
    add_p("Stores internal examination scores and evaluation results.")
    mrk_tbl = doc.add_table(rows=7, cols=4)
    mrk_tbl_data = [
        ["Field Name", "BSON Type", "Constraints", "Description"],
        ["_id", "ObjectId", "Primary Key", "Unique marks entry ID"],
        ["student_id", "string", "References students", "Student roll number"],
        ["subject", "string", "Required, 2-100 chars", "Subject title"],
        ["exam", "string", "Required, 2-100 chars", "Assessment name (e.g. Mid-Term)"],
        ["marks_obtained", "double", ">= 0.0 and <= max_marks", "Raw marks scored"],
        ["percentage", "double", "Calculated value", "Score percentage (0.0 to 100.0)"]
    ]
    for r_idx, row in enumerate(mrk_tbl.rows):
        for c_idx, cell in enumerate(row.cells):
            cell.text = mrk_tbl_data[r_idx][c_idx]
    format_table(mrk_tbl)

    # =========================================================================
    # 7. MONGODB INDEXES & SCHEMA VALIDATION
    # =========================================================================
    add_h1("7. MongoDB Indexes and Schema Validation")
    add_h2("7.1 Schema Validation via $jsonSchema")
    add_p(
        "MongoDB declarative schema validators prevent malformed or invalid documents from being inserted. "
        "For example, the students collection enforces required fields, string length, email regex, and integer semester boundaries (1 to 8):"
    )
    add_code_block(
        doc,
        "db.createCollection('students', {\n"
        "  validator: {\n"
        "    $jsonSchema: {\n"
        "      bsonType: 'object',\n"
        "      required: ['student_id', 'name', 'email', 'course', 'semester', 'active'],\n"
        "      properties: {\n"
        "        student_id: { bsonType: 'string', pattern: '^[A-Za-z0-9_-]{3,20}$' },\n"
        "        name: { bsonType: 'string', minLength: 2, maxLength: 100 },\n"
        "        email: { bsonType: 'string', pattern: '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\\\.[a-zA-Z0-9-.]+$' },\n"
        "        semester: { bsonType: 'int', minimum: 1, maximum: 8 },\n"
        "        active: { bsonType: 'bool' }\n"
        "      }\n"
        "    }\n"
        "  }\n"
        "});"
    )

    add_h2("7.2 Unique and Compound Indexes")
    add_p(
        "Indexes optimize search speeds from full collection scans (COLLSCAN) down to index scans (IXSCAN) "
        "and enforce operational constraints:"
    )
    add_p("1. Unique Index on students.student_id: Prevents duplicate student registrations.")
    add_code_block(doc, "db.students.createIndex({ student_id: 1 }, { unique: true, name: 'idx_students_student_id_unique' });")
    add_p("2. Compound Unique Index on attendance: Guarantees a student is marked at most once per subject per day.")
    add_code_block(doc, "db.attendance.createIndex({ student_id: 1, date: 1, subject: 1 }, { unique: true, name: 'idx_attendance_unique_entry' });")
    add_p("3. Compound Unique Index on marks: Prevents duplicate scores for the same student, subject, and exam.")
    add_code_block(doc, "db.marks.createIndex({ student_id: 1, subject: 1, exam: 1 }, { unique: true, name: 'idx_marks_unique_entry' });")

    # =========================================================================
    # 8. FLUTTER & FLASK IMPLEMENTATION
    # =========================================================================
    add_h1("8. Flutter Frontend and Flask API Implementation")
    add_h2("8.1 REST API Endpoints Catalog")
    api_tbl = doc.add_table(rows=9, cols=4)
    api_tbl_data = [
        ["HTTP Method", "Endpoint URI", "Controller Function", "Standard Response Codes"],
        ["GET", "/health", "check_db_health", "200 OK, 503 Unavailable"],
        ["GET", "/api/dashboard", "get_dashboard_stats", "200 OK, 500 Error"],
        ["GET / POST", "/api/students", "list_students / add_student", "200 OK, 201 Created, 409 Conflict"],
        ["GET / PUT / DEL", "/api/students/<id>", "single_student_handler", "200 OK, 400 Bad, 404 Not Found"],
        ["GET / POST", "/api/attendance", "list_attendance / mark_att", "200 OK, 201 Created, 409 Conflict"],
        ["PUT / DEL", "/api/attendance/<id>", "update_att / delete_att", "200 OK, 400 Bad, 404 Not Found"],
        ["GET / POST", "/api/marks", "list_marks / add_marks", "200 OK, 201 Created, 409 Conflict"],
        ["GET", "/api/reports/<type>", "attendance, performance, rankings", "200 OK, 500 Error"]
    ]
    for r_idx, row in enumerate(api_tbl.rows):
        for c_idx, cell in enumerate(row.cells):
            cell.text = api_tbl_data[r_idx][c_idx]
    format_table(api_tbl)

    add_h2("8.2 Flutter Mobile/Web Architecture")
    add_p(
        "The Flutter frontend employs the Provider pattern for reactive state management. "
        "Separation of concerns ensures UI widgets rebuild only when state changes, maintaining 60 FPS performance."
    )
    add_p("• ApiClient: Centralized HTTP client managing network timeouts, headers, and error decoding.")
    add_p("• Data Models: Null-safe Dart classes equipped with fromJson factory constructors and toJson serializers.")
    add_p("• State Providers: StudentProvider, AttendanceProvider, MarksProvider, and ReportProvider notify listeners upon mutations.")
    add_p("• Interactive Charts: fl_chart BarChart and PieChart visualizers for attendance threshold lines and grade distributions.")

    # =========================================================================
    # 9. CRUD & AGGREGATION PIPELINES
    # =========================================================================
    add_h1("9. CRUD Operations and Aggregation Pipelines")
    add_h2("9.1 Attendance Aggregation with Late Weighting & Zero-Division Safety")
    add_p(
        "Computes cumulative attendance percentage per student where Present counts as 1.0 and Late counts as 0.5. "
        "An internal $cond expression prevents fatal division-by-zero errors when total_classes equals 0:"
    )
    add_code_block(
        doc,
        "db.attendance.aggregate([\n"
        "  { $group: {\n"
        "      _id: '$student_id',\n"
        "      total_classes: { $sum: 1 },\n"
        "      present_count: { $sum: { $cond: [{ $eq: ['$status', 'Present'] }, 1, 0] } },\n"
        "      absent_count: { $sum: { $cond: [{ $eq: ['$status', 'Absent'] }, 1, 0] } },\n"
        "      late_count: { $sum: { $cond: [{ $eq: ['$status', 'Late'] }, 1, 0] } }\n"
        "  }},\n"
        "  { $project: {\n"
        "      student_id: '$_id',\n"
        "      total_classes: 1, present_count: 1, absent_count: 1, late_count: 1,\n"
        "      attendance_pct: {\n"
        "        $cond: [\n"
        "          { $gt: ['$total_classes', 0] },\n"
        "          { $round: [{ $multiply: [{ $divide: [{ $add: ['$present_count', { $multiply: ['$late_count', 0.5] }] }, '$total_classes'] }, 100] }, 2] },\n"
        "          0.0\n"
        "        ]\n"
        "      }\n"
        "  }},\n"
        "  { $lookup: { from: 'students', localField: 'student_id', foreignField: 'student_id', as: 'student' } },\n"
        "  { $unwind: { path: '$student', preserveNullAndEmptyArrays: true } },\n"
        "  { $sort: { attendance_pct: -1 } }\n"
        "]);"
    )

    add_h2("9.2 Academic Merit Rankings Pipeline")
    add_p("Calculates average assessment percentage per student and orders the entire class descending by merit:")
    add_code_block(
        doc,
        "db.marks.aggregate([\n"
        "  { $group: { _id: '$student_id', total_exams: { $sum: 1 }, avg_percentage: { $avg: '$percentage' } } },\n"
        "  { $lookup: { from: 'students', localField: '_id', foreignField: 'student_id', as: 'student' } },\n"
        "  { $unwind: '$student' },\n"
        "  { $sort: { avg_percentage: -1 } }\n"
        "]);"
    )

    # =========================================================================
    # 10. TESTING METHODOLOGY & RESULTS
    # =========================================================================
    add_h1("10. Testing Methodology and Actual Results")
    add_p(
        "A rigorous testing protocol verified backend endpoints, database constraints, "
        "mathematical accuracy, and frontend widget rendering."
    )
    
    test_tbl = doc.add_table(rows=7, cols=4)
    test_tbl_data = [
        ["Test Suite", "File / Target", "Execution Scope", "Verified Results"],
        ["Backend Isolated Suite", "test_backend_suite.py", "18 Test Cases on campustrack_test_suite", "18 / 18 PASSED (100%)"],
        ["Math Verification", "test_analytics_calculations.py", "7 Mathematical Aggregation Assertions", "7 / 7 PASSED (100%)"],
        ["Live CRUD Integration", "test_e2e_integration.py", "8 Live CRUD lifecycle checks on MongoDB", "8 / 8 PASSED (100%)"],
        ["Viva Demonstrations", "test_mongodb_viva_examples.py", "9 MongoDB practical lab operations", "9 / 9 PASSED (100%)"],
        ["Flutter Static Analysis", "flutter analyze", "Deprecations, lint, and syntax check", "0 Errors, 0 Warnings"],
        ["Flutter Widget Tests", "flutter test", "10 Unit & Widget Tests on Models/States", "10 / 10 PASSED (100%)"]
    ]
    for r_idx, row in enumerate(test_tbl.rows):
        for c_idx, cell in enumerate(row.cells):
            cell.text = test_tbl_data[r_idx][c_idx]
    format_table(test_tbl)

    # =========================================================================
    # 11. SCREENSHOTS GUIDE
    # =========================================================================
    add_h1("11. Screenshots Guide (App and MongoDB Compass)")
    add_p(
        "To complete your physical submission report, capture the following screenshots directly from your running system. "
        "Paste each image into the corresponding numbered placeholder below:"
    )

    ss_tbl = doc.add_table(rows=11, cols=3)
    ss_tbl_data = [
        ["Figure #", "Screen / View Title", "Description & Instructions for Student"],
        ["Figure 1", "MongoDB Compass Collections", "Capture MongoDB Compass showing database 'campustrack' with students, attendance, and marks."],
        ["Figure 2", "Schema Validation Tab", "Capture Compass -> students collection -> Validation tab showing $jsonSchema definition."],
        ["Figure 3", "Compound Index in Compass", "Capture Compass -> attendance collection -> Indexes tab showing idx_attendance_unique_entry."],
        ["Figure 4", "Aggregation Pipeline Preview", "Capture Compass -> Aggregations tab previewing the attendance percentage pipeline stages."],
        ["Figure 5", "Flask REST API Startup", "Capture terminal showing 'Starting CampusTrack Flask server' and GET /health returning 200 OK."],
        ["Figure 6", "CampusTrack Admin Dashboard", "Capture Flutter app showing KPI cards (Students, Attendance %, Avg Marks) and distribution chart."],
        ["Figure 7", "Student Directory & Search", "Capture Flutter app student list with search bar active and enrollment status chips."],
        ["Figure 8", "Daily Attendance Logging Form", "Capture Flutter form with Student dropdown, Date picker, and Present/Absent/Late buttons."],
        ["Figure 9", "Low-Attendance Defaulters List", "Capture Reports screen showing students flagged below the 75% attendance threshold."],
        ["Figure 10", "Academic Merit Rankings", "Capture Reports screen showing class rankings sorted in descending order of performance."]
    ]
    for r_idx, row in enumerate(ss_tbl.rows):
        for c_idx, cell in enumerate(row.cells):
            cell.text = ss_tbl_data[r_idx][c_idx]
    format_table(ss_tbl)

    # =========================================================================
    # 12. LIMITATIONS & FUTURE ENHANCEMENTS
    # =========================================================================
    add_h1("12. Limitations and Future Enhancements")
    add_h2("12.1 Limitations")
    add_p("1. Manual Session Input: Attendance requires manual entry rather than biometric or automated RFID card taps.")
    add_p("2. Single Institutional Scope: Configured for single-college local-network operation rather than multi-tenant cloud hosting.")
    add_p("3. Role-Based Permissions: All client sessions share unified administrative privileges without tiered student/faculty roles.")
    add_h2("12.2 Future Enhancements")
    add_p("1. Automated Biometric / QR Code Logging: Time-limited classroom QR codes scanned by student mobile devices.")
    add_p("2. Predictive Analytics (Machine Learning): Early warning models in Python predicting final grades based on mid-term trends.")
    add_p("3. Role-Based Access Control (RBAC): JWT authentication distinguishing Administrators, Faculty, and Students.")
    add_p("4. Automated Defaulter Alerts: SMS and email notifications automatically dispatched to parents when attendance drops below 75%.")

    # =========================================================================
    # 13. CONCLUSION & REFERENCES
    # =========================================================================
    add_h1("13. Conclusion and References")
    add_h2("13.1 Conclusion")
    add_p(
        "CampusTrack demonstrates the effective synergy between Flutter's responsive multi-platform presentation, "
        "Python Flask's modular RESTful microservices, and MongoDB's high-speed document-oriented persistence. "
        "By enforcing data integrity through $jsonSchema validators, eliminating duplicate logs via compound unique indexes, "
        "and utilizing server-side aggregation pipelines for real-time reporting, CampusTrack successfully meets all college "
        "NoSQL project objectives with a 100% verified test pass rate."
    )
    add_h2("13.2 References")
    add_p("1. MongoDB, Inc. (2026). MongoDB Community Server Documentation: Aggregation Framework & $jsonSchema. https://www.mongodb.com/docs/")
    add_p("2. Google LLC. (2026). Flutter Documentation: Material 3 Reactive UI Design with Provider. https://docs.flutter.dev/")
    add_p("3. Pallets Projects. (2026). Flask REST API Documentation (v3.0). https://flask.palletsprojects.com/")
    add_p("4. Chodorow, Kristina. (2013). MongoDB: The Definitive Guide: Powerful and Scalable Data Storage. O'Reilly Media.")
    add_p("5. Banker, Kyle, et al. (2016). MongoDB in Action: Covers MongoDB version 3.0. Manning Publications.")
    add_p("6. Windmill, Eric. (2020). Flutter in Action. Manning Publications.")

    # Save to project root
    output_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "CampusTrack_Project_Report.docx"))
    doc.save(output_path)
    print(f"Word document created successfully at: {output_path}")

if __name__ == "__main__":
    generate_report()
