class SalaryPayment {
  final int? id;
  final int employeeId;
  final double amount;
  final DateTime paymentDate;
  final String paymentType;
  final String? notes;
  final DateTime createdAt;

  SalaryPayment({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.paymentDate,
    this.paymentType = 'salary',
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_type': paymentType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SalaryPayment.fromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['id'] == null ? null : (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())),
      employeeId: map['employee_id'] is int ? map['employee_id'] as int : int.tryParse(map['employee_id'].toString()) ?? 0,
      amount: map['amount'] is num ? (map['amount'] as num).toDouble() : double.tryParse(map['amount'].toString()) ?? 0.0,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentType: map['payment_type'] as String? ?? 'salary',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
