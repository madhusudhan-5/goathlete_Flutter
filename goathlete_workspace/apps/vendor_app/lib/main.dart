import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/vendor_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/venue_editor_screen.dart';

void main() {
  runApp(const ProviderScope(child: VendorApp()));
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoAthlete Vendor Partner',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const VendorHomeScreen(),
    );
  }
}

class VendorHomeScreen extends ConsumerWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(vendorDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: dashboardAsync.when(
        data: (data) {
          final revenue = data['total_revenue'] ?? 0;
          final bookingsCount = data['total_bookings'] ?? 0;
          final List upcoming = data['upcoming_bookings'] ?? [];

          return RefreshIndicator(
            onRefresh: () => ref.refresh(vendorDashboardProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: GoAthleteColors.athleticOrange.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text('Total Revenue', style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('\$$revenue', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.blue.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text('Total Bookings', style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('$bookingsCount', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text('Upcoming Bookings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (upcoming.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No upcoming bookings scheduled.')),
                  ),
                ...upcoming.map((b) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.event, color: GoAthleteColors.athleticOrange),
                    title: Text('${b['date']} at ${b['start_time']}'),
                    subtitle: Text('Status: ${b['status']} | Total: \$${b['total_price']}'),
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: BottomAppBar(
        color: GoAthleteColors.athleticOrange,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VenueEditorScreen()),
                );
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit Venue Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CalendarScreen()),
          );
        },
        label: const Text('Block Slot'),
        icon: const Icon(Icons.add_task),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
    );
  }
}
