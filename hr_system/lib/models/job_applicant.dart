class JobApplicant {
  final int? id;
  final String name;
  final String position;
  final String email;
  final String phone;
  final String status; // 'new', 'reviewing', 'rejected', 'accepted'
  final String? resumeUrl;
  final DateTime appliedAt;

  JobApplicant({
    this.id,
    required this.name,
    required this.position,
    required this.email,
    required this.phone,
    this.status = 'new',
    this.resumeUrl,
    required this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'email': email,
      'phone': phone,
      'status': status,
      'resume_url': resumeUrl,
      'applied_at': appliedAt.toIso8601String(),
    };
  }

  factory JobApplicant.fromMap(Map<String, dynamic> map) {
    return JobApplicant(
      id: map['id'],
      name: map['name'],
      position: map['position'],
      email: map['email'],
      phone: map['phone'],
      status: map['status'] ?? 'new',
      resumeUrl: map['resume_url'],
      appliedAt: DateTime.parse(map['applied_at']),
    );
  }
}
