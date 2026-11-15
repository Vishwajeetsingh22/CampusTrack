class CourseCount {
  final String course;
  final int count;

  CourseCount({required this.course, required this.count});

  factory CourseCount.fromJson(Map<String, dynamic> json) {
    return CourseCount(
      course: json['course']?.toString() ?? json['department']?.toString() ?? 'General',
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class StatusCount {
  final String status;
  final int count;

  StatusCount({required this.status, required this.count});

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      status: json['status']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class DashboardStatsModel {
  final int totalStudents;
  final int activeStudents;
  final double overallAttendancePct;
  final double avgMarksPct;
  final int lowAttendanceCount;
  final int totalAttendanceRecords;
  final int totalMarksRecords;
  final List<CourseCount> courseDistribution;
  final List<StatusCount> statusBreakdown;

  DashboardStatsModel({
    required this.totalStudents,
    required this.activeStudents,
    required this.overallAttendancePct,
    required this.avgMarksPct,
    required this.lowAttendanceCount,
    required this.totalAttendanceRecords,
    required this.totalMarksRecords,
    required this.courseDistribution,
    required this.statusBreakdown,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    var rawCourses = (json['course_distribution'] ?? json['department_distribution']) as List? ?? [];
    var rawStatuses = json['status_breakdown'] as List? ?? [];

    return DashboardStatsModel(
      totalStudents: json['total_students'] is int ? json['total_students'] : int.tryParse(json['total_students']?.toString() ?? '0') ?? 0,
      activeStudents: json['active_students'] is int ? json['active_students'] : int.tryParse(json['active_students']?.toString() ?? '0') ?? 0,
      overallAttendancePct: (json['overall_attendance_pct'] is num) ? (json['overall_attendance_pct'] as num).toDouble() : 0.0,
      avgMarksPct: (json['avg_marks_pct'] is num) ? (json['avg_marks_pct'] as num).toDouble() : 0.0,
      lowAttendanceCount: json['low_attendance_count'] is int ? json['low_attendance_count'] : int.tryParse(json['low_attendance_count']?.toString() ?? '0') ?? 0,
      totalAttendanceRecords: json['total_attendance_records'] is int ? json['total_attendance_records'] : 0,
      totalMarksRecords: json['total_marks_records'] is int ? json['total_marks_records'] : 0,
      courseDistribution: rawCourses.map((e) => CourseCount.fromJson(e as Map<String, dynamic>)).toList(),
      statusBreakdown: rawStatuses.map((e) => StatusCount.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class AttendanceReportItem {
  final String studentId;
  final String name;
  final String course;
  final int semester;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double attendancePct;
  final String status;

  AttendanceReportItem({
    required this.studentId,
    required this.name,
    required this.course,
    required this.semester,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.attendancePct,
    required this.status,
  });

  factory AttendanceReportItem.fromJson(Map<String, dynamic> json) {
    return AttendanceReportItem(
      studentId: json['student_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      course: json['course']?.toString() ?? json['department']?.toString() ?? 'N/A',
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      totalClasses: json['total_classes'] is int ? json['total_classes'] : int.tryParse(json['total_classes']?.toString() ?? '0') ?? 0,
      presentCount: json['present_count'] is int ? json['present_count'] : int.tryParse(json['present_count']?.toString() ?? '0') ?? 0,
      absentCount: json['absent_count'] is int ? json['absent_count'] : int.tryParse(json['absent_count']?.toString() ?? '0') ?? 0,
      lateCount: json['late_count'] is int ? json['late_count'] : int.tryParse(json['late_count']?.toString() ?? '0') ?? 0,
      attendancePct: (json['attendance_pct'] is num) ? (json['attendance_pct'] as num).toDouble() : 0.0,
      status: json['status']?.toString() ?? 'Normal',
    );
  }
}

class SubjectPerformanceItem {
  final String subject;
  final int studentCount;
  final int passCount;
  final double passPercentage;
  final double avgPercentage;
  final double maxPercentage;
  final double minPercentage;

  SubjectPerformanceItem({
    required this.subject,
    required this.studentCount,
    required this.passCount,
    required this.passPercentage,
    required this.avgPercentage,
    required this.maxPercentage,
    required this.minPercentage,
  });

  factory SubjectPerformanceItem.fromJson(Map<String, dynamic> json) {
    return SubjectPerformanceItem(
      subject: json['subject']?.toString() ?? '',
      studentCount: json['student_count'] is int ? json['student_count'] : int.tryParse(json['student_count']?.toString() ?? '0') ?? 0,
      passCount: json['pass_count'] is int ? json['pass_count'] : int.tryParse(json['pass_count']?.toString() ?? '0') ?? 0,
      passPercentage: (json['pass_percentage'] is num) ? (json['pass_percentage'] as num).toDouble() : 0.0,
      avgPercentage: (json['avg_percentage'] is num) ? (json['avg_percentage'] as num).toDouble() : 0.0,
      maxPercentage: (json['max_percentage'] is num) ? (json['max_percentage'] as num).toDouble() : 0.0,
      minPercentage: (json['min_percentage'] is num) ? (json['min_percentage'] as num).toDouble() : 0.0,
    );
  }
}

class DefaulterStudentModel {
  final String studentId;
  final String name;
  final String course;
  final int semester;
  final int totalClasses;
  final double attendancePct;
  final double shortfall;
  final String email;
  final String phone;

  DefaulterStudentModel({
    required this.studentId,
    required this.name,
    required this.course,
    required this.semester,
    required this.totalClasses,
    required this.attendancePct,
    required this.shortfall,
    required this.email,
    required this.phone,
  });

  factory DefaulterStudentModel.fromJson(Map<String, dynamic> json) {
    return DefaulterStudentModel(
      studentId: json['student_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      course: json['course']?.toString() ?? json['department']?.toString() ?? 'N/A',
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      totalClasses: json['total_classes'] is int ? json['total_classes'] : int.tryParse(json['total_classes']?.toString() ?? '0') ?? 0,
      attendancePct: (json['attendance_pct'] is num) ? (json['attendance_pct'] as num).toDouble() : 0.0,
      shortfall: (json['shortfall'] is num) ? (json['shortfall'] as num).toDouble() : 0.0,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class StudentRankingModel {
  final int rank;
  final String studentId;
  final String name;
  final String course;
  final int semester;
  final double avgPercentage;

  StudentRankingModel({
    required this.rank,
    required this.studentId,
    required this.name,
    required this.course,
    required this.semester,
    required this.avgPercentage,
  });

  factory StudentRankingModel.fromJson(Map<String, dynamic> json) {
    return StudentRankingModel(
      rank: json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      studentId: json['student_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      course: json['course']?.toString() ?? json['department']?.toString() ?? 'N/A',
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      avgPercentage: (json['avg_percentage'] is num) ? (json['avg_percentage'] as num).toDouble() : 0.0,
    );
  }
}

class SubjectAttendanceItem {
  final String subject;
  final int totalRecords;
  final int studentCount;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double attendancePercentage;

  SubjectAttendanceItem({
    required this.subject,
    required this.totalRecords,
    required this.studentCount,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.attendancePercentage,
  });

  factory SubjectAttendanceItem.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceItem(
      subject: json['subject']?.toString() ?? '',
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
      studentCount: json['student_count'] is int ? json['student_count'] : int.tryParse(json['student_count']?.toString() ?? '0') ?? 0,
      presentCount: json['present_count'] is int ? json['present_count'] : int.tryParse(json['present_count']?.toString() ?? '0') ?? 0,
      absentCount: json['absent_count'] is int ? json['absent_count'] : int.tryParse(json['absent_count']?.toString() ?? '0') ?? 0,
      lateCount: json['late_count'] is int ? json['late_count'] : int.tryParse(json['late_count']?.toString() ?? '0') ?? 0,
      attendancePercentage: (json['attendance_percentage'] is num) ? (json['attendance_percentage'] as num).toDouble() : 0.0,
    );
  }
}

