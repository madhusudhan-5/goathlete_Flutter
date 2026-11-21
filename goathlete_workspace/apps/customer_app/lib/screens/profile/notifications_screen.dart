import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../../providers/tournament_provider.dart';

class AppNotificationItem {
  final String title;
  final String body;
  final String timestamp;
  final String? tournamentName;
  final String? teamName;
  final String? matchDateTime;
  final String? location;
  final String? paymentStatus;

  const AppNotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.tournamentName,
    this.teamName,
    this.matchDateTime,
    this.location,
    this.paymentStatus,
  });
}

class NotificationsNotifier extends StateNotifier<List<AppNotificationItem>> {
  NotificationsNotifier() : super(const []);

  void addNotification(AppNotificationItem item) {
    state = [item, ...state];
  }
}

final appNotificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotificationItem>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localNotifications = ref.watch(appNotificationsProvider);
    final tournamentsAsync = ref.watch(activeTournamentsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeTournamentsProvider),
          ),
        ],
      ),
      body: tournamentsAsync.when(
        data: (tournaments) {
          final List<AppNotificationItem> allItems = [...localNotifications];

          // Also include joined tournament teams from backend so notifications persist across sessions
          for (final t in tournaments) {
            final joined = t['my_joined_team'];
            if (joined is Map) {
              final tName = t['name']?.toString() ?? 'Tournament';
              final teamName = joined['team_name']?.toString() ?? 'Team';
              final alreadyInLocal = allItems.any(
                (n) => n.tournamentName == tName && n.teamName == teamName,
              );
              if (!alreadyInLocal) {
                final startDate = t['start_date']?.toString() ?? 'TBD';
                final location = t['location']?.toString() ?? 'TBD';
                final feePaid = (joined['fee_paid'] as num?)?.toDouble() ?? 0.0;
                final payStatus = feePaid > 0
                    ? '₹${feePaid.toInt()} Paid'
                    : 'Free Entry';
                allItems.add(
                  AppNotificationItem(
                    title: '🎉 Successfully Joined Team "$teamName"',
                    body:
                        'You are registered in team "$teamName" for $tName (${t['sport_name'] ?? 'Sport'}).',
                    timestamp: startDate,
                    tournamentName: tName,
                    teamName: teamName,
                    matchDateTime: '$startDate (09:00 AM)',
                    location: location,
                    paymentStatus: payStatus,
                  ),
                );
              }
            }
          }

          if (allItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Notifications',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Updates about joined tournament teams, match timings, and bookings will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: allItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = allItems[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: GoAthleteColors.athleticOrange.withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.body,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (item.matchDateTime != null || item.location != null) ...[
                        const Divider(height: 20),
                        if (item.teamName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.shield, size: 15, color: GoAthleteColors.athleticOrange),
                                const SizedBox(width: 6),
                                Text(
                                  'Team: ${item.teamName}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        if (item.matchDateTime != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_filled, size: 15, color: GoAthleteColors.athleticOrange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tournament Date & Time: ${item.matchDateTime}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.location != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 15, color: GoAthleteColors.athleticOrange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Venue: ${item.location}',
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.paymentStatus != null)
                          Row(
                            children: [
                              const Icon(Icons.verified, size: 15, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                'Entry Status: ${item.paymentStatus}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load notifications')),
      ),
    );
  }
}
