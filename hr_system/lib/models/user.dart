class User {
  final int? id;
  final String username;
  final String? password;
  final int? employeeId;
  final String role; // 'admin' or 'employee'

  User({
    this.id,
    required this.username,
    this.password,
    this.employeeId,
    this.role = 'employee',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'employee_id': employeeId,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString()),
      username: map['username'] as String,
      password: map['password'] as String?,
      employeeId: map['employee_id'] == null ? null : (map['employee_id'] is int ? map['employee_id'] as int : int.tryParse(map['employee_id'].toString())),
      role: map['role'] as String? ?? 'employee',
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    int? employeeId,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
    );
  }
}
