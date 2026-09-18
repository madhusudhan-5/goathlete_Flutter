import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          elevation: 0,
          bottom: TabBar(
            indicatorColor: GoAthleteColors.athleticOrange,
            labelColor: GoAthleteColors.athleticOrange,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsList(type: 'upcoming'),
            _BookingsList(type: 'past'),
            _BookingsList(type: 'cancelled'),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends ConsumerWidget {
  final String type;

  const _BookingsList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final now = DateTime.now();
        List<Booking> filtered;

        if (type == 'cancelled') {
          filtered = bookings.where((b) => b.status.toUpperCase() == 'CANCELLED').toList();
        } else if (type == 'past') {
          filtered = bookings.where((b) {
            if (b.status.toUpperCase() == 'CANCELLED') return false;
            final bookingDate = DateTime.tryParse(b.date);
            return bookingDate != null && bookingDate.isBefore(DateTime(now.year, now.month, now.day));
          }).toList();
        } else {
          // upcoming
          filtered = bookings.where((b) {
            if (b.status.toUpperCase() == 'CANCELLED') return false;
            final bookingDate = DateTime.tryParse(b.date);
            return bookingDate == null || !bookingDate.isBefore(DateTime(now.year, now.month, now.day));
          }).toList();
        }

        if (filtered.isEmpty) {
          final label = type == 'upcoming'
              ? 'No upcoming bookings.'
              : type == 'past'
                  ? 'No past bookings.'
                  : 'No cancelled bookings.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(bookingProvider.notifier).fetchMyBookings(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final booking = filtered[index];
              final isUpcoming = type == 'upcoming';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Venue #${booking.venue} (Booking #${booking.id})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUpcoming
                                  ? GoAthleteColors.athleticOrange.withOpacity(0.1)
                                  : GoAthleteColors.outlineVariant.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isUpcoming
                                        ? GoAthleteColors.athleticOrange
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            '${booking.date} (${booking.startTime} - ${booking.endTime})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, size: 16, color: GoAthleteColors.athleticOrange),
                          Text(
                            '${booking.totalPrice}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Unable to load bookings: $e', style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}
