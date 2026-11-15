class AttendanceModel {
  final String? id;
  final String studentId;
  final String? studentName;
  final String? course;
  final String date;
  final String subject;
  final String status; // Present, Absent, Late
  final String? remarks;
  final String? createdAt;

  AttendanceModel({
    this.id,
    required this.studentId,
    this.studentName,
    this.course,
    required this.date,
    required this.subject,
    required this.status,
    this.remarks,
    this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString(),
      course: json['course']?.toString() ?? json['department']?.toString(),
      date: json['date']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Present',
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'date': date,
      'subject': subject,
      'status': status,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }
}

class SubjectAttendanceStat {
  final String subject;
  final int total;
  final int present;
  final int absent;
  final int late;
  final double percentage;

  SubjectAttendanceStat({
    required this.subject,
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
  });

  factory SubjectAttendanceStat.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceStat(
      subject: json['subject']?.toString() ?? 'General',
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      present: json['present'] is int ? json['present'] : int.tryParse(json['present']?.toString() ?? '0') ?? 0,
      absent: json['absent'] is int ? json['absent'] : int.tryParse(json['absent']?.toString() ?? '0') ?? 0,
      late: json['late'] is int ? json['late'] : int.tryParse(json['late']?.toString() ?? '0') ?? 0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
    );
  }
}

class AttendanceSummaryModel {
  final String? studentId;
  final Map<String, dynamic>? studentDetails;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double attendancePercentage;
  final List<SubjectAttendanceStat> subjectBreakdown;

  AttendanceSummaryModel({
    this.studentId,
    this.studentDetails,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.attendancePercentage,
    required this.subjectBreakdown,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['subject_breakdown'] as List? ?? [];
    return AttendanceSummaryModel(
      studentId: json['student_id']?.toString(),
      studentDetails: json['student_details'] is Map ? json['student_details'] as Map<String, dynamic> : null,
      totalClasses: json['total_classes'] is int ? json['total_classes'] : int.tryParse(json['total_classes']?.toString() ?? '0') ?? 0,
      presentCount: json['present_count'] is int ? json['present_count'] : int.tryParse(json['present_count']?.toString() ?? '0') ?? 0,
      absentCount: json['absent_count'] is int ? json['absent_count'] : int.tryParse(json['absent_count']?.toString() ?? '0') ?? 0,
      lateCount: json['late_count'] is int ? json['late_count'] : int.tryParse(json['late_count']?.toString() ?? '0') ?? 0,
      attendancePercentage: (json['attendance_percentage'] is num) ? (json['attendance_percentage'] as num).toDouble() : 0.0,
      subjectBreakdown: rawList.map((e) => SubjectAttendanceStat.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
