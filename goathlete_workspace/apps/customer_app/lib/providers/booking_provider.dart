import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/booking_model.dart';

class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final Dio _dio;

  BookingNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchMyBookings();
  }

  Future<void> fetchMyBookings() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('bookings/');
      final List<dynamic> data = response.data;
      final bookings = data.map((json) => Booking.fromJson(json)).toList();
      state = AsyncValue.data(bookings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createBooking(int venueId, String date, String startTime, String endTime) async {
    try {
      await _dio.post('bookings/', data: {
        'venue': venueId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
      });
      
      // Refresh the list after successful booking
      await fetchMyBookings();
      return true;
    } catch (e) {
      // In a real app we might want to return the specific error message from the backend
      return false;
    }
  }
  Future<Map<String, dynamic>?> createPaymentIntent(int venueId, String date, String startTime, String endTime) async {
    try {
      final response = await _dio.post('bookings/payments/create-intent/', data: {
        'venue_id': venueId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final err = e.response?.data is Map ? e.response?.data['error'] : null;
      if (err != null) {
        return {'error': err.toString()};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> confirmPayment(
    int paymentId, {
    String? transactionId,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    try {
      final payload = <String, dynamic>{
        'payment_id': paymentId,
      };
      if (transactionId != null && transactionId.isNotEmpty) {
        payload['transaction_id'] = transactionId;
      }
      if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) {
        payload['razorpay_order_id'] = razorpayOrderId;
      }
      if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty) {
        payload['razorpay_payment_id'] = razorpayPaymentId;
      }
      if (razorpaySignature != null && razorpaySignature.isNotEmpty) {
        payload['razorpay_signature'] = razorpaySignature;
      }

      await _dio.post('bookings/payments/confirm/', data: payload);
      await fetchMyBookings();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class BookingFlowState {
  final Map<String, dynamic>? venue;
  final String? date;
  final String? startTime;
  final String? endTime;
  
  BookingFlowState({this.venue, this.date, this.startTime, this.endTime});
  
  BookingFlowState copyWith({Map<String, dynamic>? venue, String? date, String? startTime, String? endTime}) {
    return BookingFlowState(
      venue: venue ?? this.venue,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

final bookingFlowProvider = StateProvider<BookingFlowState>((ref) => BookingFlowState());


final bookingProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  return BookingNotifier(ref.watch(dioProvider));
});
