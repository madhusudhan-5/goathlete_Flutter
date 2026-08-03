import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

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

class _BookingsList extends StatelessWidget {
  final String type;

  const _BookingsList({required this.type});

  @override
  Widget build(BuildContext context) {
    // Placeholder content for now
    if (type == 'cancelled') {
      return const Center(child: Text('No cancelled bookings.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
      itemCount: type == 'upcoming' ? 2 : 5,
      itemBuilder: (context, index) {
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
                      'Smash It Turf',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: type == 'upcoming'
                            ? GoAthleteColors.athleticOrange.withOpacity(0.1)
                            : GoAthleteColors.outlineVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        type == 'upcoming' ? 'Confirmed' : 'Completed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: type == 'upcoming' ? GoAthleteColors.athleticOrange : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 20, color: GoAthleteColors.athleticOrange),
                    const SizedBox(width: 8),
                    Text('Football - 5v5', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      type == 'upcoming' ? 'Tomorrow, 6:00 PM' : 'Oct 10, 5:00 PM',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (type == 'upcoming')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('View Details'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Book Again'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
