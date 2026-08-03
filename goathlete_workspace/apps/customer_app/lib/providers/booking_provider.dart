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
}

final bookingProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  return BookingNotifier(ref.watch(dioProvider));
});
