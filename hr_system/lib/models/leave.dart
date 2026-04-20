class Leave {
  final int? id;
  final int employeeId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final int? approvedBy;

  Leave({
    this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.status = 'pending',
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
    };
  }

  factory Leave.fromMap(Map<String, dynamic> map) {
    return Leave(
      id: map['id'] == null ? null : (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())),
      employeeId: map['employee_id'] is int ? map['employee_id'] as int : int.tryParse(map['employee_id'].toString()) ?? 0,
      leaveType: map['leave_type'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      reason: map['reason'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at'] as String) : null,
      approvedBy: map['approved_by'] == null ? null : (map['approved_by'] is int ? map['approved_by'] as int : int.tryParse(map['approved_by'].toString())),
    );
  }
}
