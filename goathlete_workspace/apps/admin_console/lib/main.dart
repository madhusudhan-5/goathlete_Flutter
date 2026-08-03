import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'providers/admin_provider.dart';
import 'screens/executive_screen.dart';
import 'screens/config_screen.dart';
import 'screens/offers_screen.dart';

void main() {
  runApp(const ProviderScope(child: AdminConsoleApp()));
}

class AdminConsoleApp extends StatelessWidget {
  const AdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoAthlete Super Admin',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Console'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: analyticsAsync.when(
        data: (data) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar
              Container(
                width: 250,
                color: Colors.grey.shade100,
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      selected: true,
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: const Text('KYC Approvals'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const KycApprovalScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_alt),
                      title: const Text('Executives'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExecutiveManagementScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Global Config'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GlobalConfigurationScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_offer),
                      title: const Text('Offers'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PromotionalOffersScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform Overview', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(context, 'Total Revenue', '\$${data['total_revenue']}', Icons.attach_money),
                          _buildStatCard(context, 'Total Venues', '${data['total_venues']}', Icons.sports_tennis),
                          _buildStatCard(context, 'Total Executives', '${data['total_executives']}', Icons.people),
                          _buildStatCard(context, 'Pending KYC', '${data['pending_kyc']}', Icons.pending_actions),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Text('Revenue Chart (Demo)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 1),
                                  FlSpot(1, 1.5),
                                  FlSpot(2, 1.4),
                                  FlSpot(3, 3.4),
                                  FlSpot(4, 2),
                                  FlSpot(5, 2.2),
                                  FlSpot(6, 1.8),
                                ],
                                isCurved: true,
                                color: GoAthleteColors.athleticOrange,
                                barWidth: 4,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: GoAthleteColors.athleticOrange),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class KycApprovalScreen extends ConsumerWidget {
  const KycApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Approvals'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: pendingAsync.when(
        data: (venues) {
          if (venues.isEmpty) {
            return const Center(child: Text('No pending KYC approvals.'));
          }
          return ListView.builder(
            itemCount: venues.length,
            itemBuilder: (context, index) {
              final venue = venues[index];
              return Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: Text(venue['name'] ?? 'Unknown'),
                  subtitle: Text('Owner: ${venue['owner_name']} | Address: ${venue['address']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () async {
                          await ref.read(approveVenueProvider(venue['id']).future);
                          ref.refresh(pendingVenuesProvider);
                          ref.refresh(adminAnalyticsProvider);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await ref.read(rejectVenueProvider(venue['id']).future);
                          ref.refresh(pendingVenuesProvider);
                          ref.refresh(adminAnalyticsProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
