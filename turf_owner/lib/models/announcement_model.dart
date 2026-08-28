class Announcement {
  final String id;
  final String turfId;
  final String? turfName;
  final String title;
  final String message;
  final String type;
  final bool isPublic;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.turfId,
    this.turfName,
    required this.title,
    required this.message,
    required this.type,
    required this.isPublic,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      turfId: (json['turfId'] is Map) ? json['turfId']['_id'] : (json['turfId'] ?? '').toString(),
      turfName: (json['turfId'] is Map) ? json['turfId']['name'] : null,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'General',
      isPublic: json['isPublic'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
