class AuditLog {
  final int? id;
  final int? userId;
  final String action;
  final String entityType;
  final int? entityId;
  final String? oldValues;
  final String? newValues;
  final DateTime createdAt;

  AuditLog({
    this.id,
    this.userId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_values': oldValues,
      'new_values': newValues,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] == null ? null : (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())),
      userId: map['user_id'] == null ? null : (map['user_id'] is int ? map['user_id'] as int : int.tryParse(map['user_id'].toString())),
      action: map['action'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] == null ? null : (map['entity_id'] is int ? map['entity_id'] as int : int.tryParse(map['entity_id'].toString())),
      oldValues: map['old_values'] as String?,
      newValues: map['new_values'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
