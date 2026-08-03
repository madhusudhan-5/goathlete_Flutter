import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/venue_onboarding_screen.dart';
import 'providers/venue_provider.dart';

void main() {
  runApp(const ProviderScope(child: ExecutiveApp()));
}

class ExecutiveApp extends StatelessWidget {
  const ExecutiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoAthlete Executive',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ExecutiveHomeScreen(),
    );
  }
}

class ExecutiveHomeScreen extends ConsumerWidget {
  const ExecutiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsyncValue = ref.watch(venuesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Onboarded Venues'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: venuesAsyncValue.when(
        data: (venues) {
          if (venues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_center, size: 100, color: GoAthleteColors.athleticOrange),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, Executive!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text('You have not onboarded any venues yet.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(venuesListProvider.future),
            child: ListView.builder(
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.sports_tennis, color: GoAthleteColors.athleticOrange),
                    title: Text(venue['name'] ?? 'Unknown Venue'),
                    subtitle: Text('Status: ${venue['status']} \nOwner: ${venue['owner_name']}'),
                    isThreeLine: true,
                  ),
                );
              },
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
          ref.refresh(venuesListProvider);
        },
        label: const Text('New Venue'),
        icon: const Icon(Icons.add),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
    );
  }
}
