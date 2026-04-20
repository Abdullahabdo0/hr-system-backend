class Employee {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String department;
  final DateTime hireDate;
  final double salary;
  final String status; // 'active' or 'inactive'

  Employee({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.department,
    required this.hireDate,
    required this.salary,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'hire_date': hireDate.toIso8601String(),
      'salary': salary,
      'status': status,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] == null ? null : (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())),
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      position: map['position'] as String,
      department: map['department'] as String,
      hireDate: DateTime.parse(map['hire_date'] as String),
      salary: map['salary'] is num ? (map['salary'] as num).toDouble() : double.tryParse(map['salary'].toString()) ?? 0.0,
      status: map['status'] as String? ?? 'active',
    );
  }

  Employee copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? department,
    DateTime? hireDate,
    double? salary,
    String? status,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      status: status ?? this.status,
    );
  }
}
