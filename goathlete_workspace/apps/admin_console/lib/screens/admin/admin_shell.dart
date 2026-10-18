import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:core_ui/core_ui.dart';
import 'package:dio/dio.dart';
import '../../network/api_client.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/top_navigation_bar.dart';
import '../executive_screen.dart';
import '../config_screen.dart';
import '../offers_screen.dart';

class GoAthleteAdminShell extends ConsumerStatefulWidget {
  const GoAthleteAdminShell({super.key});

  @override
  ConsumerState<GoAthleteAdminShell> createState() => _GoAthleteAdminShellState();
}

class _GoAthleteAdminShellState extends ConsumerState<GoAthleteAdminShell> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(adminTokenProvider);

    return Scaffold(
      appBar: const AdminTopBar(
        title: 'GoAthlete Super Admin',
        currentMode: PortalMode.goathleteAdmin,
      ),
      body: token == null
          ? const AdminLoginScreen()
          : Row(
              children: [
                // Left Navigation Rail
                NavigationRail(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: GoAthleteColors.athleticOrange),
                  selectedLabelTextStyle: const TextStyle(
                    color: GoAthleteColors.athleticOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.verified_user_outlined),
                      selectedIcon: Icon(Icons.verified_user),
                      label: Text('KYC Approvals'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      selectedIcon: Icon(Icons.people_alt),
                      label: Text('Executives'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.emoji_events_outlined),
                      selectedIcon: Icon(Icons.emoji_events),
                      label: Text('Tournaments'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Config'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_offer_outlined),
                      selectedIcon: Icon(Icons.local_offer),
                      label: Text('Offers'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),

                // Active Tab Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: const [
                      AdminOverviewTab(),
                      AdminKycApprovalsTab(),
                      ExecutiveManagementScreen(),
                      AdminTournamentsTab(),
                      GlobalConfigurationScreen(),
                      PromotionalOffersScreen(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// ADMIN LOGIN SCREEN
// -------------------------------------------------------------

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _usernameController = TextEditingController(text: 'superadmin');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _loading = false;
  String? _error;

  Future<void> _login([bool demo = false]) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (demo) {
      ref.read(adminTokenProvider.notifier).state = 'demo_admin_jwt_token_sample';
      setState(() => _loading = false);
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('users/login/', data: {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      });
      final token = response.data['access'];
      dio.options.headers['Authorization'] = 'Bearer $token';
      ref.read(adminTokenProvider.notifier).state = token;
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(pendingVenuesProvider);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Login failed: ${e.response?.data ?? e.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Login error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GoAthleteColors.athleticOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 48,
                      color: GoAthleteColors.athleticOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'GoAthlete Super Admin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage venue approvals, field executives, and platform analytics.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoAthleteColors.athleticOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login to Admin Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _login(true),
                  icon: const Icon(Icons.flash_on, color: GoAthleteColors.athleticOrange),
                  label: const Text('Quick Demo Admin Login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GoAthleteColors.athleticOrange,
                    side: const BorderSide(color: GoAthleteColors.athleticOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// ADMIN OVERVIEW TAB
// -------------------------------------------------------------

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return analyticsAsync.when(
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform Executive Overview', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Real-time key performance indicators and revenue metrics.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(adminAnalyticsProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoAthleteColors.athleticOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // KPI Metrics Grid
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildStatCard(context, 'Total Revenue', '₹${data['total_revenue'] ?? '0'}', Icons.currency_rupee, Colors.green),
                  _buildStatCard(context, 'Total Venues', '${data['total_venues'] ?? '0'}', Icons.sports_tennis, Colors.blue),
                  _buildStatCard(context, 'Field Executives', '${data['total_executives'] ?? '0'}', Icons.people_alt, Colors.purple),
                  _buildStatCard(context, 'Pending KYC Approvals', '${data['pending_kyc'] ?? '0'}', Icons.pending_actions, Colors.orange),
                  _buildStatCard(context, 'Total Bookings', '${data['total_bookings'] ?? '0'}', Icons.calendar_today, Colors.teal),
                  _buildStatCard(context, 'Active Tournaments', '${data['active_tournaments'] ?? '0'}', Icons.emoji_events, Colors.amber.shade800),
                ],
              ),
              const SizedBox(height: 36),

              // Revenue Graph Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Gross Platform Volume (₹)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 260,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    const months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
                                    final index = val.toInt();
                                    return (index >= 0 && index < months.length) ? Text(months[index], style: const TextStyle(fontSize: 12)) : const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 0),
                                  FlSpot(1, 0),
                                  FlSpot(2, 0),
                                  FlSpot(3, 0),
                                  FlSpot(4, 0),
                                  FlSpot(5, 0),
                                ],
                                isCurved: true,
                                color: GoAthleteColors.athleticOrange,
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: GoAthleteColors.athleticOrange.withValues(alpha: 0.15),
                                ),
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// ADMIN KYC APPROVALS TAB
// -------------------------------------------------------------

class AdminKycApprovalsTab extends ConsumerWidget {
  const AdminKycApprovalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingVenuesProvider);

    return pendingAsync.when(
      data: (venues) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pre-Registered Venues & KYC Verification', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Review onboarding submissions from field executives and approve venues for public listing.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(pendingVenuesProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (venues.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('🎉 No pending KYC verifications. All venues reviewed!'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: venues.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final v = venues[index];
                      final id = v['id'] as int? ?? index + 1;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront, color: Colors.orange, size: 32),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['business_name'] ?? v['name'] ?? 'Venue #$id',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Owner: ${v['owner_name'] ?? 'N/A'} | Phone: ${v['phone_number'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                                    Text('Address: ${v['address'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await ref.read(rejectVenueProvider(id).future);
                                      ref.invalidate(pendingVenuesProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue application rejected.')));
                                      }
                                    },
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref.read(approveVenueProvider(id).future);
                                      ref.invalidate(pendingVenuesProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue approved and activated!')));
                                      }
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('Approve & Publish'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// -------------------------------------------------------------
// ADMIN TOURNAMENTS TAB
// -------------------------------------------------------------

class AdminTournamentsTab extends ConsumerWidget {
  const AdminTournamentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(adminTournamentsProvider);

    return tournamentsAsync.when(
      data: (tournaments) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Tournaments Oversight', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('Monitor live tournaments, registered squads, and fixture scheduling.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 24),
              Expanded(
                child: tournaments.isEmpty
                    ? const Center(child: Text('No active tournaments found.'))
                    : ListView.builder(
                        itemCount: tournaments.length,
                        itemBuilder: (context, index) {
                          final t = tournaments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: GoAthleteColors.athleticOrange,
                                child: Icon(Icons.emoji_events, color: Colors.white),
                              ),
                              title: Text(t['name'] ?? 'Tournament', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Sport: ${t['sport_name'] ?? 'N/A'} | Location: ${t['location'] ?? 'TBD'} | Fee: ₹${t['player_fee'] ?? 0} / player'),
                              trailing: Chip(
                                label: Text(t['tournament_type'] ?? 'Knockout'),
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
