import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../../providers/venue_provider.dart';
import '../../providers/auth_provider.dart';
import '../venue_onboarding_screen.dart';

class ExecutiveDashboardScreen extends ConsumerWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Dashboard'),
        backgroundColor: GoAthleteColors.athleticOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          )
        ],
      ),
      body: statsAsyncValue.when(
        data: (stats) {
          final recentBookings = stats['recent_bookings'] as List<dynamic>? ?? [];
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardStatsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMetricsGrid(context, stats),
                const SizedBox(height: 24),
                Text('Recent Bookings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (recentBookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No bookings found for your approved venues yet.'),
                  )
                else
                  ...recentBookings.map((b) => _buildBookingCard(b)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const VenueOnboardingScreen()),
          );
          ref.refresh(dashboardStatsProvider);
        },
        label: const Text('Onboard Venue'),
        icon: const Icon(Icons.add_business),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(context, 'Total Onboarded', '${stats['total_onboarded']}', Icons.business, Colors.blue),
        _buildMetricCard(context, 'Pending KYC', '${stats['pending_approval']}', Icons.pending_actions, Colors.orange),
        _buildMetricCard(context, 'Approved Venues', '${stats['approved_venues']}', Icons.verified, Colors.green),
        _buildMetricCard(context, 'Live Bookings', '${stats['total_bookings']}', Icons.event_available, GoAthleteColors.athleticOrange),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: GoAthleteColors.athleticOrange,
          child: Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text('Booking on ${booking['date']}'),
        subtitle: Text('Time: ${booking['start_time']} - ${booking['end_time']}\nStatus: ${booking['status']}'),
        trailing: Text('₹${booking['total_price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        isThreeLine: true,
      ),
    );
  }
}
