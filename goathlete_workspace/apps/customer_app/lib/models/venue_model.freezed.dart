// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Venue _$VenueFromJson(Map<String, dynamic> json) {
  return _Venue.fromJson(json);
}

/// @nodoc
mixin _$Venue {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get distance => throw _privateConstructorUsedError;
  num get rating => throw _privateConstructorUsedError;
  @JsonKey(name: 'reviews_count')
  int get reviewsCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_hour')
  num get pricePerHour => throw _privateConstructorUsedError;
  List<VenueSport> get sports => throw _privateConstructorUsedError;
  List<Amenity> get amenities => throw _privateConstructorUsedError;

  /// Serializes this Venue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueCopyWith<Venue> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueCopyWith<$Res> {
  factory $VenueCopyWith(Venue value, $Res Function(Venue) then) =
      _$VenueCopyWithImpl<$Res, Venue>;
  @useResult
  $Res call({
    int id,
    String name,
    String description,
    String location,
    String distance,
    num rating,
    @JsonKey(name: 'reviews_count') int reviewsCount,
    @JsonKey(name: 'image_url') String imageUrl,
    @JsonKey(name: 'price_per_hour') num pricePerHour,
    List<VenueSport> sports,
    List<Amenity> amenities,
  });
}

/// @nodoc
class _$VenueCopyWithImpl<$Res, $Val extends Venue>
    implements $VenueCopyWith<$Res> {
  _$VenueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? location = null,
    Object? distance = null,
    Object? rating = null,
    Object? reviewsCount = null,
    Object? imageUrl = null,
    Object? pricePerHour = null,
    Object? sports = null,
    Object? amenities = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            distance: null == distance
                ? _value.distance
                : distance // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as num,
            reviewsCount: null == reviewsCount
                ? _value.reviewsCount
                : reviewsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            pricePerHour: null == pricePerHour
                ? _value.pricePerHour
                : pricePerHour // ignore: cast_nullable_to_non_nullable
                      as num,
            sports: null == sports
                ? _value.sports
                : sports // ignore: cast_nullable_to_non_nullable
                      as List<VenueSport>,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as List<Amenity>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VenueImplCopyWith<$Res> implements $VenueCopyWith<$Res> {
  factory _$$VenueImplCopyWith(
    _$VenueImpl value,
    $Res Function(_$VenueImpl) then,
  ) = __$$VenueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String description,
    String location,
    String distance,
    num rating,
    @JsonKey(name: 'reviews_count') int reviewsCount,
    @JsonKey(name: 'image_url') String imageUrl,
    @JsonKey(name: 'price_per_hour') num pricePerHour,
    List<VenueSport> sports,
    List<Amenity> amenities,
  });
}

/// @nodoc
class __$$VenueImplCopyWithImpl<$Res>
    extends _$VenueCopyWithImpl<$Res, _$VenueImpl>
    implements _$$VenueImplCopyWith<$Res> {
  __$$VenueImplCopyWithImpl(
    _$VenueImpl _value,
    $Res Function(_$VenueImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? location = null,
    Object? distance = null,
    Object? rating = null,
    Object? reviewsCount = null,
    Object? imageUrl = null,
    Object? pricePerHour = null,
    Object? sports = null,
    Object? amenities = null,
  }) {
    return _then(
      _$VenueImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        distance: null == distance
            ? _value.distance
            : distance // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as num,
        reviewsCount: null == reviewsCount
            ? _value.reviewsCount
            : reviewsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        pricePerHour: null == pricePerHour
            ? _value.pricePerHour
            : pricePerHour // ignore: cast_nullable_to_non_nullable
                  as num,
        sports: null == sports
            ? _value._sports
            : sports // ignore: cast_nullable_to_non_nullable
                  as List<VenueSport>,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as List<Amenity>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueImpl implements _Venue {
  const _$VenueImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.distance,
    required this.rating,
    @JsonKey(name: 'reviews_count') required this.reviewsCount,
    @JsonKey(name: 'image_url') required this.imageUrl,
    @JsonKey(name: 'price_per_hour') required this.pricePerHour,
    required final List<VenueSport> sports,
    required final List<Amenity> amenities,
  }) : _sports = sports,
       _amenities = amenities;

  factory _$VenueImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String location;
  @override
  final String distance;
  @override
  final num rating;
  @override
  @JsonKey(name: 'reviews_count')
  final int reviewsCount;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  @JsonKey(name: 'price_per_hour')
  final num pricePerHour;
  final List<VenueSport> _sports;
  @override
  List<VenueSport> get sports {
    if (_sports is EqualUnmodifiableListView) return _sports;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sports);
  }

  final List<Amenity> _amenities;
  @override
  List<Amenity> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  @override
  String toString() {
    return 'Venue(id: $id, name: $name, description: $description, location: $location, distance: $distance, rating: $rating, reviewsCount: $reviewsCount, imageUrl: $imageUrl, pricePerHour: $pricePerHour, sports: $sports, amenities: $amenities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.distance, distance) ||
                other.distance == distance) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewsCount, reviewsCount) ||
                other.reviewsCount == reviewsCount) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.pricePerHour, pricePerHour) ||
                other.pricePerHour == pricePerHour) &&
            const DeepCollectionEquality().equals(other._sports, _sports) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    location,
    distance,
    rating,
    reviewsCount,
    imageUrl,
    pricePerHour,
    const DeepCollectionEquality().hash(_sports),
    const DeepCollectionEquality().hash(_amenities),
  );

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueImplCopyWith<_$VenueImpl> get copyWith =>
      __$$VenueImplCopyWithImpl<_$VenueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueImplToJson(this);
  }
}

abstract class _Venue implements Venue {
  const factory _Venue({
    required final int id,
    required final String name,
    required final String description,
    required final String location,
    required final String distance,
    required final num rating,
    @JsonKey(name: 'reviews_count') required final int reviewsCount,
    @JsonKey(name: 'image_url') required final String imageUrl,
    @JsonKey(name: 'price_per_hour') required final num pricePerHour,
    required final List<VenueSport> sports,
    required final List<Amenity> amenities,
  }) = _$VenueImpl;

  factory _Venue.fromJson(Map<String, dynamic> json) = _$VenueImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get location;
  @override
  String get distance;
  @override
  num get rating;
  @override
  @JsonKey(name: 'reviews_count')
  int get reviewsCount;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  @JsonKey(name: 'price_per_hour')
  num get pricePerHour;
  @override
  List<VenueSport> get sports;
  @override
  List<Amenity> get amenities;

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueImplCopyWith<_$VenueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VenueSport _$VenueSportFromJson(Map<String, dynamic> json) {
  return _VenueSport.fromJson(json);
}

/// @nodoc
mixin _$VenueSport {
  Sport get sport => throw _privateConstructorUsedError;

  /// Serializes this VenueSport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VenueSport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueSportCopyWith<VenueSport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueSportCopyWith<$Res> {
  factory $VenueSportCopyWith(
    VenueSport value,
    $Res Function(VenueSport) then,
  ) = _$VenueSportCopyWithImpl<$Res, VenueSport>;
  @useResult
  $Res call({Sport sport});

  $SportCopyWith<$Res> get sport;
}

/// @nodoc
class _$VenueSportCopyWithImpl<$Res, $Val extends VenueSport>
    implements $VenueSportCopyWith<$Res> {
  _$VenueSportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VenueSport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sport = null}) {
    return _then(
      _value.copyWith(
            sport: null == sport
                ? _value.sport
                : sport // ignore: cast_nullable_to_non_nullable
                      as Sport,
          )
          as $Val,
    );
  }

  /// Create a copy of VenueSport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SportCopyWith<$Res> get sport {
    return $SportCopyWith<$Res>(_value.sport, (value) {
      return _then(_value.copyWith(sport: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VenueSportImplCopyWith<$Res>
    implements $VenueSportCopyWith<$Res> {
  factory _$$VenueSportImplCopyWith(
    _$VenueSportImpl value,
    $Res Function(_$VenueSportImpl) then,
  ) = __$$VenueSportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Sport sport});

  @override
  $SportCopyWith<$Res> get sport;
}

/// @nodoc
class __$$VenueSportImplCopyWithImpl<$Res>
    extends _$VenueSportCopyWithImpl<$Res, _$VenueSportImpl>
    implements _$$VenueSportImplCopyWith<$Res> {
  __$$VenueSportImplCopyWithImpl(
    _$VenueSportImpl _value,
    $Res Function(_$VenueSportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VenueSport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sport = null}) {
    return _then(
      _$VenueSportImpl(
        sport: null == sport
            ? _value.sport
            : sport // ignore: cast_nullable_to_non_nullable
                  as Sport,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueSportImpl implements _VenueSport {
  const _$VenueSportImpl({required this.sport});

  factory _$VenueSportImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueSportImplFromJson(json);

  @override
  final Sport sport;

  @override
  String toString() {
    return 'VenueSport(sport: $sport)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueSportImpl &&
            (identical(other.sport, sport) || other.sport == sport));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sport);

  /// Create a copy of VenueSport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueSportImplCopyWith<_$VenueSportImpl> get copyWith =>
      __$$VenueSportImplCopyWithImpl<_$VenueSportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueSportImplToJson(this);
  }
}

abstract class _VenueSport implements VenueSport {
  const factory _VenueSport({required final Sport sport}) = _$VenueSportImpl;

  factory _VenueSport.fromJson(Map<String, dynamic> json) =
      _$VenueSportImpl.fromJson;

  @override
  Sport get sport;

  /// Create a copy of VenueSport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueSportImplCopyWith<_$VenueSportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Sport _$SportFromJson(Map<String, dynamic> json) {
  return _Sport.fromJson(json);
}

/// @nodoc
mixin _$Sport {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_name')
  String get iconName => throw _privateConstructorUsedError;

  /// Serializes this Sport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Sport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SportCopyWith<Sport> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SportCopyWith<$Res> {
  factory $SportCopyWith(Sport value, $Res Function(Sport) then) =
      _$SportCopyWithImpl<$Res, Sport>;
  @useResult
  $Res call({int id, String name, @JsonKey(name: 'icon_name') String iconName});
}

/// @nodoc
class _$SportCopyWithImpl<$Res, $Val extends Sport>
    implements $SportCopyWith<$Res> {
  _$SportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Sport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? iconName = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            iconName: null == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SportImplCopyWith<$Res> implements $SportCopyWith<$Res> {
  factory _$$SportImplCopyWith(
    _$SportImpl value,
    $Res Function(_$SportImpl) then,
  ) = __$$SportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, @JsonKey(name: 'icon_name') String iconName});
}

/// @nodoc
class __$$SportImplCopyWithImpl<$Res>
    extends _$SportCopyWithImpl<$Res, _$SportImpl>
    implements _$$SportImplCopyWith<$Res> {
  __$$SportImplCopyWithImpl(
    _$SportImpl _value,
    $Res Function(_$SportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Sport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? iconName = null}) {
    return _then(
      _$SportImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        iconName: null == iconName
            ? _value.iconName
            : iconName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SportImpl implements _Sport {
  const _$SportImpl({
    required this.id,
    required this.name,
    @JsonKey(name: 'icon_name') required this.iconName,
  });

  factory _$SportImpl.fromJson(Map<String, dynamic> json) =>
      _$$SportImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey(name: 'icon_name')
  final String iconName;

  @override
  String toString() {
    return 'Sport(id: $id, name: $name, iconName: $iconName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, iconName);

  /// Create a copy of Sport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SportImplCopyWith<_$SportImpl> get copyWith =>
      __$$SportImplCopyWithImpl<_$SportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SportImplToJson(this);
  }
}

abstract class _Sport implements Sport {
  const factory _Sport({
    required final int id,
    required final String name,
    @JsonKey(name: 'icon_name') required final String iconName,
  }) = _$SportImpl;

  factory _Sport.fromJson(Map<String, dynamic> json) = _$SportImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'icon_name')
  String get iconName;

  /// Create a copy of Sport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SportImplCopyWith<_$SportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Amenity _$AmenityFromJson(Map<String, dynamic> json) {
  return _Amenity.fromJson(json);
}

/// @nodoc
mixin _$Amenity {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_name')
  String get iconName => throw _privateConstructorUsedError;

  /// Serializes this Amenity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Amenity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AmenityCopyWith<Amenity> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AmenityCopyWith<$Res> {
  factory $AmenityCopyWith(Amenity value, $Res Function(Amenity) then) =
      _$AmenityCopyWithImpl<$Res, Amenity>;
  @useResult
  $Res call({int id, String name, @JsonKey(name: 'icon_name') String iconName});
}

/// @nodoc
class _$AmenityCopyWithImpl<$Res, $Val extends Amenity>
    implements $AmenityCopyWith<$Res> {
  _$AmenityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Amenity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? iconName = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            iconName: null == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AmenityImplCopyWith<$Res> implements $AmenityCopyWith<$Res> {
  factory _$$AmenityImplCopyWith(
    _$AmenityImpl value,
    $Res Function(_$AmenityImpl) then,
  ) = __$$AmenityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, @JsonKey(name: 'icon_name') String iconName});
}

/// @nodoc
class __$$AmenityImplCopyWithImpl<$Res>
    extends _$AmenityCopyWithImpl<$Res, _$AmenityImpl>
    implements _$$AmenityImplCopyWith<$Res> {
  __$$AmenityImplCopyWithImpl(
    _$AmenityImpl _value,
    $Res Function(_$AmenityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Amenity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? iconName = null}) {
    return _then(
      _$AmenityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        iconName: null == iconName
            ? _value.iconName
            : iconName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AmenityImpl implements _Amenity {
  const _$AmenityImpl({
    required this.id,
    required this.name,
    @JsonKey(name: 'icon_name') required this.iconName,
  });

  factory _$AmenityImpl.fromJson(Map<String, dynamic> json) =>
      _$$AmenityImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey(name: 'icon_name')
  final String iconName;

  @override
  String toString() {
    return 'Amenity(id: $id, name: $name, iconName: $iconName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AmenityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, iconName);

  /// Create a copy of Amenity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AmenityImplCopyWith<_$AmenityImpl> get copyWith =>
      __$$AmenityImplCopyWithImpl<_$AmenityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AmenityImplToJson(this);
  }
}

abstract class _Amenity implements Amenity {
  const factory _Amenity({
    required final int id,
    required final String name,
    @JsonKey(name: 'icon_name') required final String iconName,
  }) = _$AmenityImpl;

  factory _Amenity.fromJson(Map<String, dynamic> json) = _$AmenityImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'icon_name')
  String get iconName;

  /// Create a copy of Amenity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AmenityImplCopyWith<_$AmenityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
