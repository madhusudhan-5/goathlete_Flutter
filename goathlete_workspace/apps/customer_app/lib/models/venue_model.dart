import '../config/app_config.dart';

class Venue {
  final int id;
  final String name;
  final String description;
  final String location;
  final String distance;
  final double? latitude;
  final double? longitude;
  final num rating;
  final int reviewsCount;
  final String imageUrl;
  final List<String> images;
  final num pricePerHour;
  final String groundType;
  final List<VenueSport> sports;
  final List<Amenity> amenities;

  const Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.distance,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.reviewsCount,
    required this.imageUrl,
    this.images = const [],
    required this.pricePerHour,
    this.groundType = '',
    required this.sports,
    required this.amenities,
  });

  /// Returns all resolved image URLs for this venue (de-duplicated).
  List<String> get allImageUrls {
    final List<String> result = [];
    for (final raw in images) {
      final resolved = AppConfig.resolveMediaUrl(raw);
      if (resolved != null && resolved.isNotEmpty && !result.contains(resolved)) {
        result.add(resolved);
      }
    }
    if (result.isEmpty && imageUrl.isNotEmpty) {
      final resolved = AppConfig.resolveMediaUrl(imageUrl);
      if (resolved != null && resolved.isNotEmpty) {
        result.add(resolved);
      }
    }
    return result;
  }

  factory Venue.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? const [];
    final parsedImages = rawImages
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return Venue(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      distance: (json['distance'] ?? '') as String,
      latitude: json['latitude'] == null
          ? null
          : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] == null
          ? null
          : double.tryParse(json['longitude'].toString()),
      rating: num.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      imageUrl: (json['image_url'] ?? '') as String,
      images: parsedImages,
      pricePerHour: num.tryParse(json['price_per_hour']?.toString() ?? '0') ?? 0,
      groundType: (json['ground_type'] ?? '') as String,
      sports: (json['sports'] as List<dynamic>? ?? [])
          .map((e) => VenueSport.fromJson(e as Map<String, dynamic>))
          .toList(),
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((e) => Amenity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VenueSport {
  final Sport sport;

  const VenueSport({required this.sport});

  factory VenueSport.fromJson(Map<String, dynamic> json) => VenueSport(
        sport: Sport.fromJson(json['sport'] as Map<String, dynamic>),
      );
}

class Sport {
  final int id;
  final String name;
  final String iconName;

  const Sport({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory Sport.fromJson(Map<String, dynamic> json) => Sport(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        iconName: (json['icon_name'] ?? 'sports') as String,
      );
}

class Amenity {
  final int id;
  final String name;
  final String iconName;

  const Amenity({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        iconName: (json['icon_name'] ?? 'check_circle') as String,
      );
}
