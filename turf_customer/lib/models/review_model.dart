class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String turfId;
  final String bookingId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.turfId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      userId: (json['userId'] is Map) ? (json['userId']['_id'] ?? '') : (json['userId'] ?? ''),
      userName: (json['userId'] is Map) ? (json['userId']['name'] ?? 'User') : 'User',
      userProfileImage: (json['userId'] is Map) ? json['userId']['profileImage'] : null,
      turfId: json['turfId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
