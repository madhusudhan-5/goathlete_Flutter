// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueImpl _$$VenueImplFromJson(Map<String, dynamic> json) => _$VenueImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String,
  location: json['location'] as String,
  distance: json['distance'] as String,
  rating: json['rating'] as num,
  reviewsCount: (json['reviews_count'] as num).toInt(),
  imageUrl: json['image_url'] as String,
  pricePerHour: json['price_per_hour'] as num,
  sports: (json['sports'] as List<dynamic>)
      .map((e) => VenueSport.fromJson(e as Map<String, dynamic>))
      .toList(),
  amenities: (json['amenities'] as List<dynamic>)
      .map((e) => Amenity.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$VenueImplToJson(_$VenueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'distance': instance.distance,
      'rating': instance.rating,
      'reviews_count': instance.reviewsCount,
      'image_url': instance.imageUrl,
      'price_per_hour': instance.pricePerHour,
      'sports': instance.sports,
      'amenities': instance.amenities,
    };

_$VenueSportImpl _$$VenueSportImplFromJson(Map<String, dynamic> json) =>
    _$VenueSportImpl(
      sport: Sport.fromJson(json['sport'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VenueSportImplToJson(_$VenueSportImpl instance) =>
    <String, dynamic>{'sport': instance.sport};

_$SportImpl _$$SportImplFromJson(Map<String, dynamic> json) => _$SportImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  iconName: json['icon_name'] as String,
);

Map<String, dynamic> _$$SportImplToJson(_$SportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon_name': instance.iconName,
    };

_$AmenityImpl _$$AmenityImplFromJson(Map<String, dynamic> json) =>
    _$AmenityImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
    );

Map<String, dynamic> _$$AmenityImplToJson(_$AmenityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon_name': instance.iconName,
    };
