class Attendance {
  final int? id;
  final int employeeId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double totalHours;
  final String status; // 'present', 'absent', 'late'
  final String? notes;

  Attendance({
    this.id,
    required this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.totalHours = 0,
    this.status = 'present',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'total_hours': totalHours,
      'status': status,
      'notes': notes,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      employeeId: map['employee_id'] is int 
          ? map['employee_id'] as int 
          : int.tryParse(map['employee_id'].toString()) ?? 0,
      date: DateTime.parse(map['date'] as String),
      checkInTime: map['check_in_time'] != null
          ? DateTime.parse(map['check_in_time'] as String)
          : null,
      checkOutTime: map['check_out_time'] != null
          ? DateTime.parse(map['check_out_time'] as String)
          : null,
      totalHours: map['total_hours'] is num ? (map['total_hours'] as num).toDouble() : double.tryParse(map['total_hours'].toString()) ?? 0.0,
      status: map['status'] as String? ?? 'present',
      notes: map['notes'] as String?,
    );
  }

  Attendance copyWith({
    int? id,
    int? employeeId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? totalHours,
    String? status,
    String? notes,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      totalHours: totalHours ?? this.totalHours,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
