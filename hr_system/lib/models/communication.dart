class Communication {
  final int? id;
  final String title;
  final String sender;
  final String receiver;
  final String content;
  final String type; // 'message', 'purchase_request'
  final String status; // 'pending', 'replied', 'approved', 'rejected'
  final DateTime createdAt;

  Communication({
    this.id,
    required this.title,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.type,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'type': type,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Communication.fromMap(Map<String, dynamic> map) {
    return Communication(
      id: map['id'],
      title: map['title'],
      sender: map['sender'],
      receiver: map['receiver'],
      content: map['content'],
      type: map['type'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
