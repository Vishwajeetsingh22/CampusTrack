import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/student_model.dart';
import 'package:frontend/models/attendance_model.dart';
import 'package:frontend/models/marks_model.dart';
import 'package:frontend/models/report_models.dart';
import 'package:frontend/widgets/empty_state_view.dart';
import 'package:frontend/widgets/error_state_view.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/widgets/stat_kpi_card.dart';

void main() {
  group('CampusTrack Dart Models & JSON Serialization Tests', () {
    test('StudentModel fromJson and toJson serialization', () {
      final json = {
        '_id': '65a123456789abcdef012345',
        'student_id': 'STU1001',
        'name': 'Aarav Sharma',
        'course': 'Computer Science',
        'semester': 6,
        'email': 'aarav.sharma@campus.edu',
        'active': true,
        'phone': '+91-9876543210',
        'created_at': '2026-10-25T00:00:00Z',
      };

      final student = StudentModel.fromJson(json);
      expect(student.studentId, 'STU1001');
      expect(student.name, 'Aarav Sharma');
      expect(student.course, 'Computer Science');
      expect(student.semester, 6);
      expect(student.email, 'aarav.sharma@campus.edu');
      expect(student.active, isTrue);
      expect(student.id, '65a123456789abcdef012345');

      final serialized = student.toJson();
      expect(serialized['student_id'], 'STU1001');
      expect(serialized['name'], 'Aarav Sharma');
      expect(serialized['semester'], 6);
      expect(serialized['phone'], '+91-9876543210');
    });

    test('AttendanceModel fromJson and toJson serialization', () {
      final json = {
        '_id': 'att_01',
        'student_id': 'STU1001',
        'student_name': 'Aarav Sharma',
        'date': '2026-11-01',
        'subject': 'NoSQL Systems',
        'status': 'Present',
        'remarks': 'On time',
      };

      final att = AttendanceModel.fromJson(json);
      expect(att.studentId, 'STU1001');
      expect(att.studentName, 'Aarav Sharma');
      expect(att.date, '2026-11-01');
      expect(att.status, 'Present');

      final serialized = att.toJson();
      expect(serialized['student_id'], 'STU1001');
      expect(serialized['status'], 'Present');
      expect(serialized['subject'], 'NoSQL Systems');
    });

    test('MarksModel fromJson and toJson serialization', () {
      final json = {
        '_id': 'marks_01',
        'student_id': 'STU1001',
        'subject': 'NoSQL Systems',
        'exam': 'Final Exam',
        'marks_obtained': 92.0,
        'max_marks': 100.0,
        'percentage': 92.0,
      };

      final mark = MarksModel.fromJson(json);
      expect(mark.studentId, 'STU1001');
      expect(mark.marksObtained, 92.0);
      expect(mark.maxMarks, 100.0);
      expect(mark.percentage, 92.0);

      final serialized = mark.toJson();
      expect(serialized['marks_obtained'], 92.0);
      expect(serialized['max_marks'], 100.0);
    });

    test('DashboardStatsModel fromJson parsing', () {
      final json = {
        'total_students': 12,
        'active_students': 12,
        'total_attendance_records': 110,
        'total_marks_records': 96,
        'overall_attendance_pct': 86.5,
        'avg_marks_pct': 78.4,
        'low_attendance_count': 2,
        'course_distribution': [
          {'course': 'Computer Science', 'count': 6},
          {'course': 'Information Technology', 'count': 6},
        ],
        'status_breakdown': [
          {'status': 'Present', 'count': 90},
          {'status': 'Late', 'count': 10},
          {'status': 'Absent', 'count': 10},
        ],
      };

      final dash = DashboardStatsModel.fromJson(json);
      expect(dash.totalStudents, 12);
      expect(dash.overallAttendancePct, 86.5);
      expect(dash.avgMarksPct, 78.4);
      expect(dash.lowAttendanceCount, 2);
      expect(dash.courseDistribution.length, 2);
    });

    test('StudentRankingModel and SubjectAttendanceItem parsing', () {
      final rankJson = {
        'rank': 1,
        'student_id': 'STU1001',
        'name': 'Aarav Sharma',
        'course': 'Computer Science',
        'semester': 6,
        'avg_percentage': 94.5,
      };
      final rank = StudentRankingModel.fromJson(rankJson);
      expect(rank.studentId, 'STU1001');
      expect(rank.avgPercentage, 94.5);
      expect(rank.rank, 1);

      final subJson = {
        'subject': 'NoSQL Systems',
        'total_records': 25,
        'student_count': 12,
        'present_count': 22,
        'absent_count': 2,
        'late_count': 1,
        'attendance_percentage': 90.0,
      };
      final sub = SubjectAttendanceItem.fromJson(subJson);
      expect(sub.subject, 'NoSQL Systems');
      expect(sub.attendancePercentage, 90.0);
      expect(sub.presentCount, 22);
      expect(sub.studentCount, 12);
    });
  });

  group('CampusTrack Reusable Widget State Tests', () {
    testWidgets('EmptyStateView renders title, message, and responds to action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.school_outlined,
              title: 'No Students Found',
              message: 'Database currently has zero student profiles.',
              actionLabel: 'Add Student',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Students Found'), findsOneWidget);
      expect(find.text('Database currently has zero student profiles.'), findsOneWidget);
      expect(find.text('Add Student'), findsOneWidget);

      await tester.tap(find.text('Add Student'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('ErrorStateView renders error message and triggers onRetry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView(
              message: 'Failed to connect to Flask backend at 10.0.2.2:5000',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect to Flask backend at 10.0.2.2:5000'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('LoadingIndicator renders message and CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Fetching aggregated attendance records...'),
          ),
        ),
      );

      expect(find.text('Fetching aggregated attendance records...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('StatKpiCard displays title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatKpiCard(
              title: 'TOTAL STUDENTS',
              value: '12',
              subtitle: '100% active enrollment',
              icon: Icons.people_alt_rounded,
              iconColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('TOTAL STUDENTS'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('100% active enrollment'), findsOneWidget);
    });
  });
}
