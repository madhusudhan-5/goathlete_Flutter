// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      id: (json['id'] as num).toInt(),
      venue: (json['venue'] as num).toInt(),
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      totalPrice: json['total_price'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'venue': instance.venue,
      'date': instance.date,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'total_price': instance.totalPrice,
      'status': instance.status,
    };
