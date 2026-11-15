class UserModel {
  final String id;
  final String email;
  final String role;
  final String fullName;
  final String? studentId;
  final bool isVerified;
  final Map<String, dynamic>? studentProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    this.studentId,
    required this.isVerified,
    this.studentProfile,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStudent => role.toLowerCase() == 'student';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      fullName: json['full_name'] ?? json['name'] ?? '',
      studentId: json['student_id'],
      isVerified: json['is_verified'] ?? false,
      studentProfile: json['student_profile'] is Map<String, dynamic>
          ? json['student_profile'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'student_id': studentId,
      'is_verified': isVerified,
      if (studentProfile != null) 'student_profile': studentProfile,
    };
  }
}
