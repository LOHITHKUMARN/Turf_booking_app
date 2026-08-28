class Turf {
  final String id;
  final String ownerId;
  final String name;
  final String city;
  final String area;
  final List<String> grounds;
  final List<String> sports;
  final List<String> amenities;
  final String status;
  final List<String> images;
  final String operationalStatus;
  final String turfType;

  Turf({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.city,
    required this.area,
    this.grounds = const [],
    required this.sports,
    required this.amenities,
    required this.status,
    this.operationalStatus = 'normal',
    this.images = const [],
    this.upiId = '',
    this.taxPercentage = 0.0,
    this.avgRating = 0.0,
    this.numReviews = 0,
    this.turfType = 'both',
  });

  final String upiId;
  final double taxPercentage;
  final double avgRating;
  final int numReviews;

  factory Turf.fromJson(Map<String, dynamic> json) {
    String city = 'N/A';
    String area = 'N/A';
    
    if (json['location'] != null) {
      if (json['location'] is Map) {
        city = json['location']['city'] ?? 'N/A';
        area = json['location']['area'] ?? 'N/A';
      } else if (json['location'] is String) {
        // Fallback for legacy data where location was a string
        city = json['location'];
        area = json['location'];
      }
    }

    return Turf(
      id: json['_id'] ?? json['id'] ?? '',
      ownerId: json['ownerId'] is Map ? (json['ownerId']['_id'] ?? '') : (json['ownerId'] ?? ''),
      name: json['name'] ?? 'Unnamed Turf',
      city: city,
      area: area,
      grounds: List<String>.from(json['grounds'] ?? []),
      sports: List<String>.from(json['sports'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      status: json['status'] ?? 'pending',
      images: List<String>.from(json['images'] ?? []).where((img) => img.isNotEmpty).toList(),
      operationalStatus: json['operationalStatus'] ?? 'normal',
      upiId: json['settings']?['upiId'] ?? '',
      taxPercentage: (json['settings']?['taxPercentage'] ?? 0).toDouble(),
      avgRating: (json['settings']?['avgRating'] ?? 0).toDouble(),
      numReviews: json['settings']?['numReviews'] ?? 0,
      turfType: json['turfType'] ?? 'both',
    );
  }

  String? get firstImageUrl {
    if (images.isEmpty) return null;
    return images[0];
  }
}
