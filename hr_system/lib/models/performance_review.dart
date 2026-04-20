class PerformanceReview {
  final int? id;
  final int employeeId;
  final int? reviewerId;
  final DateTime reviewDate;
  final int rating;
  final String? comments;
  final DateTime createdAt;

  PerformanceReview({
    this.id,
    required this.employeeId,
    this.reviewerId,
    required this.reviewDate,
    required this.rating,
    this.comments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'reviewer_id': reviewerId,
      'review_date': reviewDate.toIso8601String(),
      'rating': rating,
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PerformanceReview.fromMap(Map<String, dynamic> map) {
    return PerformanceReview(
      id: map['id'] == null ? null : (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())),
      employeeId: map['employee_id'] is int ? map['employee_id'] as int : int.tryParse(map['employee_id'].toString()) ?? 0,
      reviewerId: map['reviewer_id'] == null ? null : (map['reviewer_id'] is int ? map['reviewer_id'] as int : int.tryParse(map['reviewer_id'].toString())),
      reviewDate: DateTime.parse(map['review_date'] as String),
      rating: map['rating'] is int ? map['rating'] as int : int.tryParse(map['rating'].toString()) ?? 0,
      comments: map['comments'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
