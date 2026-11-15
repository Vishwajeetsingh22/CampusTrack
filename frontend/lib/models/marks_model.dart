class MarksModel {
  final String? id;
  final String studentId;
  final String? studentName;
  final String? course;
  final String subject;
  final String exam;
  final double marksObtained;
  final double maxMarks;
  final double percentage;
  final String? createdAt;

  MarksModel({
    this.id,
    required this.studentId,
    this.studentName,
    this.course,
    required this.subject,
    required this.exam,
    required this.marksObtained,
    required this.maxMarks,
    required this.percentage,
    this.createdAt,
  });

  factory MarksModel.fromJson(Map<String, dynamic> json) {
    return MarksModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString(),
      course: json['course']?.toString() ?? json['department']?.toString(),
      subject: json['subject']?.toString() ?? '',
      exam: json['exam']?.toString() ?? '',
      marksObtained: (json['marks_obtained'] is num) ? (json['marks_obtained'] as num).toDouble() : 0.0,
      maxMarks: (json['max_marks'] is num) ? (json['max_marks'] as num).toDouble() : 100.0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'subject': subject,
      'exam': exam,
      'marks_obtained': marksObtained,
      'max_marks': maxMarks,
    };
  }
}

class SubjectMarksStat {
  final String subject;
  final int assessmentsCount;
  final double avgPercentage;
  final double maxPercentage;
  final double minPercentage;

  SubjectMarksStat({
    required this.subject,
    required this.assessmentsCount,
    required this.avgPercentage,
    required this.maxPercentage,
    required this.minPercentage,
  });

  factory SubjectMarksStat.fromJson(Map<String, dynamic> json) {
    return SubjectMarksStat(
      subject: json['subject']?.toString() ?? '',
      assessmentsCount: json['assessments_count'] is int ? json['assessments_count'] : int.tryParse(json['assessments_count']?.toString() ?? '0') ?? 0,
      avgPercentage: (json['avg_percentage'] is num) ? (json['avg_percentage'] as num).toDouble() : 0.0,
      maxPercentage: (json['max_percentage'] is num) ? (json['max_percentage'] as num).toDouble() : 0.0,
      minPercentage: (json['min_percentage'] is num) ? (json['min_percentage'] as num).toDouble() : 0.0,
    );
  }
}

class MarksSummaryModel {
  final String? studentId;
  final Map<String, dynamic>? studentDetails;
  final int totalRecords;
  final double totalObtained;
  final double totalMax;
  final double avgPercentage;
  final double maxPercentage;
  final double minPercentage;
  final List<SubjectMarksStat> subjectBreakdown;

  MarksSummaryModel({
    this.studentId,
    this.studentDetails,
    required this.totalRecords,
    required this.totalObtained,
    required this.totalMax,
    required this.avgPercentage,
    required this.maxPercentage,
    required this.minPercentage,
    required this.subjectBreakdown,
  });

  factory MarksSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['subject_breakdown'] as List? ?? [];
    return MarksSummaryModel(
      studentId: json['student_id']?.toString(),
      studentDetails: json['student_details'] is Map ? json['student_details'] as Map<String, dynamic> : null,
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
      totalObtained: (json['total_obtained'] is num) ? (json['total_obtained'] as num).toDouble() : 0.0,
      totalMax: (json['total_max'] is num) ? (json['total_max'] as num).toDouble() : 0.0,
      avgPercentage: (json['avg_percentage'] is num) ? (json['avg_percentage'] as num).toDouble() : 0.0,
      maxPercentage: (json['max_percentage'] is num) ? (json['max_percentage'] as num).toDouble() : 0.0,
      minPercentage: (json['min_percentage'] is num) ? (json['min_percentage'] as num).toDouble() : 0.0,
      subjectBreakdown: rawList.map((e) => SubjectMarksStat.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
