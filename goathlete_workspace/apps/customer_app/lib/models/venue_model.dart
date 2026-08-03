import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue_model.freezed.dart';
part 'venue_model.g.dart';

@freezed
class Venue with _$Venue {
  const factory Venue({
    required int id,
    required String name,
    required String description,
    required String location,
    required String distance,
    required num rating,
    @JsonKey(name: 'reviews_count') required int reviewsCount,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'price_per_hour') required num pricePerHour,
    required List<VenueSport> sports,
    required List<Amenity> amenities,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}

@freezed
class VenueSport with _$VenueSport {
  const factory VenueSport({
    required Sport sport,
  }) = _VenueSport;

  factory VenueSport.fromJson(Map<String, dynamic> json) => _$VenueSportFromJson(json);
}

@freezed
class Sport with _$Sport {
  const factory Sport({
    required int id,
    required String name,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _Sport;

  factory Sport.fromJson(Map<String, dynamic> json) => _$SportFromJson(json);
}

@freezed
class Amenity with _$Amenity {
  const factory Amenity({
    required int id,
    required String name,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _Amenity;

  factory Amenity.fromJson(Map<String, dynamic> json) => _$AmenityFromJson(json);
}
