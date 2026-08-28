class SlotSettings {
  final int? minBookingDuration;
  final int? advanceBookingLimit;
  final int? bookingCutoffTime;
  final int? gracePeriod;

  final int? maxMembers;
  final String? upiId;
  final double? taxPercentage;

  SlotSettings({
    this.minBookingDuration,
    this.advanceBookingLimit,
    this.bookingCutoffTime,
    this.gracePeriod,
    this.maxMembers,
    this.upiId,
    this.taxPercentage,
  });

  factory SlotSettings.fromJson(Map<String, dynamic> json) {
    return SlotSettings(
      minBookingDuration: json['minBookingDuration'],
      advanceBookingLimit: json['advanceBookingLimit'],
      bookingCutoffTime: json['bookingCutoffTime'],
      gracePeriod: json['gracePeriod'],
      maxMembers: json['maxMembers'],
      upiId: json['upiId'],
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minBookingDuration': minBookingDuration,
      'advanceBookingLimit': advanceBookingLimit,
      'bookingCutoffTime': bookingCutoffTime,
      'gracePeriod': gracePeriod,
      'maxMembers': maxMembers,
      'upiId': upiId,
      'taxPercentage': taxPercentage,
    };
  }
}

class Turf {
  final String id;
  final String ownerId;
  final String name;
  final String city;
  final String area;
  final List<String> sports;
  final List<String> amenities;
  final List<String> images;
  final String status;
  final SlotSettings settings;
  final List<String> grounds;
  final String turfType;

  Turf({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.city,
    required this.area,
    required this.sports,
    required this.amenities,
    required this.images,
    required this.status,
    required this.settings,
    this.grounds = const [],
    this.turfType = 'both',
  });

  String get upiId => settings.upiId ?? '';
  double get taxPercentage => settings.taxPercentage ?? 0.0;

  factory Turf.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    return Turf(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: (location['city'] ?? '').toString(),
      area: (location['area'] ?? '').toString(),
      sports: (json['sports'] as List?)?.map((e) => e.toString()).toList() ?? [],
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: (json['status'] ?? 'pending').toString(),
      settings: SlotSettings.fromJson(json['settings'] ?? {}),
      grounds: (json['grounds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      turfType: (json['turfType'] ?? 'both').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'location': {
        'city': city,
        'area': area,
      },
      'sports': sports,
      'amenities': amenities,
      'images': images,
      'status': status,
      'settings': settings.toJson(),
      'grounds': grounds,
      'turfType': turfType,
    };
  }
}
