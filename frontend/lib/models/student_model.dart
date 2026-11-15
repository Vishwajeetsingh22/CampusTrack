class StudentModel {
  final String? id;
  final String studentId;
  final String name;
  final String course;
  final String? department;
  final int semester;
  final String email;
  final bool active;
  final String? phone;
  final String? createdAt;
  final String? updatedAt;

  StudentModel({
    this.id,
    required this.studentId,
    required this.name,
    required this.course,
    this.department,
    required this.semester,
    required this.email,
    this.active = true,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      studentId: json['student_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      course: json['course']?.toString() ?? json['department']?.toString() ?? 'Unassigned',
      department: json['department']?.toString(),
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? '1') ?? 1,
      email: json['email']?.toString() ?? '',
      active: json['active'] is bool ? json['active'] : (json['active']?.toString().toLowerCase() == 'true'),
      phone: json['phone']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'course': course,
      'department': course,
      'semester': semester,
      'email': email,
      'active': active,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }

  StudentModel copyWith({
    String? id,
    String? studentId,
    String? name,
    String? course,
    String? department,
    int? semester,
    String? email,
    bool? active,
    String? phone,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      course: course ?? this.course,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      email: email ?? this.email,
      active: active ?? this.active,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
