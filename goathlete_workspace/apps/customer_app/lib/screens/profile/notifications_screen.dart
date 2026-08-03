import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {}, // Mark all as read
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: 8,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final isUnread = index < 2;
          
          return Container(
            color: isUnread ? GoAthleteColors.athleticOrange.withOpacity(0.05) : Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnread ? GoAthleteColors.athleticOrange.withOpacity(0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  index % 3 == 0 ? Icons.calendar_today : (index % 3 == 1 ? Icons.emoji_events : Icons.group),
                  color: isUnread ? GoAthleteColors.athleticOrange : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                index % 3 == 0 ? 'Booking Confirmed' : (index % 3 == 1 ? 'Tournament Reminder' : 'New Tribe Message'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Your match at Smash It Turf is confirmed for tomorrow at 6:00 PM.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              trailing: Text(
                '2h ago',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }
}
