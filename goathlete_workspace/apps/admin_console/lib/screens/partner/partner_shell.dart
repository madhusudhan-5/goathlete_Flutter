import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../../network/api_client.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/top_navigation_bar.dart';

class PartnerAdminShell extends ConsumerStatefulWidget {
  const PartnerAdminShell({super.key});

  @override
  ConsumerState<PartnerAdminShell> createState() => _PartnerAdminShellState();
}

class _PartnerAdminShellState extends ConsumerState<PartnerAdminShell> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(partnerTokenProvider);

    return Scaffold(
      appBar: const AdminTopBar(
        title: 'GoAthlete Partner Portal',
        currentMode: PortalMode.partnerAdmin,
      ),
      body: token == null
          ? const PartnerLoginScreen()
          : Row(
              children: [
                // Left Navigation Rail for Partner
                NavigationRail(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: Colors.teal.shade700),
                  selectedLabelTextStyle: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.stadium_outlined),
                      selectedIcon: Icon(Icons.stadium),
                      label: Text('My Grounds'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.access_time_outlined),
                      selectedIcon: Icon(Icons.access_time_filled),
                      label: Text('Slot Pricing'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Bookings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Settlements'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),

                // Active Tab Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: const [
                      PartnerOverviewTab(),
                      PartnerVenuesTab(),
                      PartnerSlotPricingTab(),
                      PartnerBookingsTab(),
                      PartnerSettlementsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// PARTNER LOGIN SCREEN
// -------------------------------------------------------------

class PartnerLoginScreen extends ConsumerStatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  ConsumerState<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends ConsumerState<PartnerLoginScreen> {
  final _phoneController = TextEditingController(text: '+91 98800 12345');
  final _passwordController = TextEditingController(text: 'partner123');
  bool _loading = false;

  Future<void> _login([bool demo = false]) async {
    setState(() => _loading = true);

    if (demo) {
      ref.read(partnerTokenProvider.notifier).state = 'partner_authenticated_jwt_sample';
      setState(() => _loading = false);
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('users/login/', data: {
        'username': _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
      });
      final token = response.data['access'];
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Fetch profile to check requires_password_change
      final profileRes = await dio.get('users/profile/');
      final requiresChange = profileRes.data['requires_password_change'] == true;
      final role = profileRes.data['role'];

      if (role != 'VENDOR' && role != 'SUPER_ADMIN') {
        throw Exception('Access Denied. Vendor privileges required.');
      }

      if (requiresChange) {
        if (mounted) {
          _showChangePasswordDialog(dio, token);
        }
        return; // Don't set token state yet
      }

      ref.read(partnerTokenProvider.notifier).state = token;
      ref.invalidate(partnerAnalyticsProvider);
      ref.invalidate(partnerVenuesProvider);
      ref.invalidate(partnerBookingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showChangePasswordDialog(Dio dio, String token) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please change your default password to continue.'),
              const SizedBox(height: 16),
              TextField(
                controller: oldPasswordController,
                decoration: const InputDecoration(labelText: 'Old Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () {
                Navigator.pop(context);
                setState(() => _loading = false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: dialogLoading ? null : () async {
                setDialogState(() => dialogLoading = true);
                try {
                  await dio.post('users/change-password/', data: {
                    'old_password': oldPasswordController.text,
                    'new_password': newPasswordController.text,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.read(partnerTokenProvider.notifier).state = token;
                    ref.invalidate(partnerAnalyticsProvider);
                    ref.invalidate(partnerVenuesProvider);
                    ref.invalidate(partnerBookingsProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password')));
                  }
                } finally {
                  if (context.mounted) setDialogState(() => dialogLoading = false);
                }
              },
              child: dialogLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Change & Login'),
            ),
          ],
        ),
      ),
    );
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
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stadium_rounded,
                      size: 48,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Partner & Turf Portal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your sports arenas, turf slots, hourly pricing, and customer check-ins.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Partner Mobile / Email',
                    prefixIcon: Icon(Icons.phone_android),
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
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login as Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _login(true),
                  icon: Icon(Icons.flash_on, color: Colors.teal.shade700),
                  label: const Text('Quick Demo Partner Access'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade700,
                    side: BorderSide(color: Colors.teal.shade700),
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
// PARTNER OVERVIEW TAB
// -------------------------------------------------------------

class PartnerOverviewTab extends ConsumerWidget {
  const PartnerOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(partnerAnalyticsProvider);

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
                      Text('Turf Arena Dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Daily booking schedule, occupancy rates, and revenue settlements.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(partnerAnalyticsProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // KPI Metrics
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildPartnerCard(context, 'This Month Revenue', '₹${data['total_revenue'] ?? '0'}', Icons.currency_rupee, Colors.green),
                  _buildPartnerCard(context, "Today's Bookings", '${data['today_bookings'] ?? '0'} Slots', Icons.alarm_on, Colors.blue),
                  _buildPartnerCard(context, 'Total Slot Bookings', '${data['total_bookings'] ?? '0'}', Icons.confirmation_number_outlined, Colors.purple),
                  _buildPartnerCard(context, 'Turf Occupancy', '${data['occupancy_rate'] ?? '0'}%', Icons.pie_chart_outline, Colors.teal),
                  _buildPartnerCard(context, 'Pending Payout', '₹${data['pending_payout'] ?? '0'}', Icons.account_balance, Colors.amber.shade800),
                ],
              ),
              const SizedBox(height: 36),

              // Booking Trends Chart
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Turf Slot Bookings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 240,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    final index = val.toInt();
                                    return (index >= 0 && index < days.length) ? Text(days[index], style: const TextStyle(fontSize: 12)) : const Text('');
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
                                  FlSpot(6, 0),
                                ],
                                isCurved: true,
                                color: Colors.teal.shade700,
                                barWidth: 4,
                                belowBarData: BarAreaData(show: true, color: Colors.teal.shade700.withValues(alpha: 0.15)),
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

  Widget _buildPartnerCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    return Container(
      width: 210,
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
// PARTNER MY VENUES TAB
// -------------------------------------------------------------



class PartnerVenuesTab extends ConsumerWidget {
  const PartnerVenuesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.teal.shade700,
            indicatorColor: Colors.teal.shade700,
            tabs: const [
              Tab(text: 'Venues'),
              Tab(text: 'Courts'),
              Tab(text: 'Rental Items'),
              Tab(text: 'Turf Partners'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVenuesList(context, ref),
                const PartnerCourtsView(),
                const PartnerRentalItemsView(),
                const PartnerVendorPartnersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuesList(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(partnerVenuesProvider);

    return venuesAsync.when(

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
                      Text('My Sports Venues & Pitches', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Manage court dimensions, pitch surface specifications, and player amenities.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue creation wizard opened.')));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Venue / Court'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: venues.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final v = venues[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.sports_soccer, size: 40, color: Colors.teal.shade700),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(v['name'] ?? 'Sports Arena', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Chip(
                                        label: Text('★ ${v['rating'] ?? '4.8'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        backgroundColor: Colors.amber.shade100,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(v['address'] ?? 'Bengaluru, India', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(label: Text(v['sport'] ?? 'Football / Cricket'), visualDensity: VisualDensity.compact),
                                      Chip(label: Text('${v['total_courts'] ?? 2} Courts Available'), visualDensity: VisualDensity.compact),
                                      Chip(label: Text('Base: ₹${v['price_per_hour'] ?? 1000}/hr'), visualDensity: VisualDensity.compact),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showEditVenueDialog(context, ref, v);
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit Details'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                ),
                              ],
                            ),
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

  void _showEditVenueDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> venue) {

    final descController = TextEditingController(text: venue['description'] ?? '');
    final priceController = TextEditingController(text: venue['price_per_hour']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Venue Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price Per Hour'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (venue['id'] == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cannot update: Venue ID is missing')));
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              try {
                final dio = ref.read(dioProvider);
                await dio.patch('venues/vendor-venues/${venue['id']}/', data: {
                  'description': descController.text,
                  'price_per_hour': double.tryParse(priceController.text),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerVenuesProvider);
                  messenger.showSnackBar(const SnackBar(content: Text('Venue updated successfully')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed to update venue: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}



// -------------------------------------------------------------
// PARTNER RENTAL ITEMS
// -------------------------------------------------------------

final partnerRentalItemsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/rental-items/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class PartnerRentalItemsView extends ConsumerWidget {
  const PartnerRentalItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(partnerRentalItemsProvider);

    return asyncData.when(
      data: (items) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rental Items', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddDialog(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rental Item'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['name'] ?? 'Item'),
                        subtitle: Text('Price: ₹${item['price']} | Qty: ${item['total_quantity']}'),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    final venues = ref.read(partnerVenuesProvider).value ?? [];
    int? selectedVenueId = venues.isNotEmpty ? venues.first['id'] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Rental Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedVenueId,
                  items: venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                  onChanged: (val) => setState(() => selectedVenueId = val),
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Total Quantity'), keyboardType: TextInputType.number),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedVenueId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cannot add: Venue is required')));
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('venues/rental-items/', data: {
                      'venue': selectedVenueId,
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'total_quantity': int.tryParse(qtyController.text) ?? 1,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ref.invalidate(partnerRentalItemsProvider);
                      messenger.showSnackBar(const SnackBar(content: Text('Item added')));
                    }
                  } catch (e) {
                    if (ctx.mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}

// -------------------------------------------------------------
// PARTNER VENDOR PARTNERS
// -------------------------------------------------------------

final partnerVendorPartnersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('venues/vendor-partners/');
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

class PartnerVendorPartnersView extends ConsumerWidget {
  const PartnerVendorPartnersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(partnerVendorPartnersProvider);

    return asyncData.when(
      data: (partners) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Turf Partners', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddDialog(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Partner'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final p = partners[index];
                    return Card(
                      child: ListTile(
                        title: Text(p['user_email'] ?? 'Unknown'),
                        subtitle: Text('Role: ${p['role']} | Venue: ${p['venue_name'] ?? p['venue']}'),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    String role = 'MANAGER';
    
    final venues = ref.read(partnerVenuesProvider).value ?? [];
    int? selectedVenueId = venues.isNotEmpty ? venues.first['id'] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Turf Partner'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedVenueId,
                  items: venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                  onChanged: (val) => setState(() => selectedVenueId = val),
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'User Email')),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: ['CO_OWNER', 'MANAGER', 'STAFF'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => role = val!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedVenueId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cannot add: Venue is required')));
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('venues/vendor-partners/', data: {
                      'venue': selectedVenueId,
                      'user_email': emailController.text,
                      'role': role,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ref.invalidate(partnerVendorPartnersProvider);
                      messenger.showSnackBar(const SnackBar(content: Text('Partner added')));
                    }
                  } catch (e) {
                    if (ctx.mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}


class PartnerCourtsView extends ConsumerWidget {
  const PartnerCourtsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(partnerVenuesProvider).value ?? [];
    if (venues.isEmpty) return const Center(child: Text('No venues available.'));
    return PartnerCourtsList(venues: venues);
  }
}

class PartnerCourtsList extends ConsumerStatefulWidget {
  final List<dynamic> venues;
  const PartnerCourtsList({super.key, required this.venues});
  @override
  ConsumerState<PartnerCourtsList> createState() => _PartnerCourtsListState();
}

class _PartnerCourtsListState extends ConsumerState<PartnerCourtsList> {
  int? selectedVenueId;

  @override
  void initState() {
    super.initState();
    if (widget.venues.isNotEmpty) {
      selectedVenueId = widget.venues.first['id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.venues.isEmpty) return const Center(child: Text('No venues available.'));
    
    int? validVenueId = selectedVenueId;
    if (validVenueId != null && !widget.venues.any((v) => v['id'] == validVenueId)) {
      validVenueId = null;
    }
    
    if (validVenueId == null) {
      validVenueId = widget.venues.first['id'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedVenueId = validVenueId;
          });
        }
      });
    }

    final courtsAsync = ref.watch(partnerCourtsProvider(validVenueId!));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: validVenueId,
                items: widget.venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                onChanged: (val) => setState(() => selectedVenueId = val),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddCourtDialog(context, ref, validVenueId!);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Court'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: courtsAsync.when(
              data: (courts) {
                return ListView.builder(
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return Card(
                      child: ListTile(
                        title: Text(court['name'] ?? 'Court'),
                        subtitle: Text('Sport: ${court['sport']}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCourtDialog(BuildContext context, WidgetRef ref, int venueId) {
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Court'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (e.g. Pitch 1)')),
            TextField(controller: sportController, decoration: const InputDecoration(labelText: 'Sport')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.post('venues/courts/', data: {
                  'venue': venueId,
                  'name': nameController.text,
                  'sport': sportController.text,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerCourtsProvider(venueId));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Court added')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// PARTNER SLOT PRICING TAB
// -------------------------------------------------------------




class PartnerSlotPricingTab extends ConsumerStatefulWidget {
  const PartnerSlotPricingTab({super.key});

  @override
  ConsumerState<PartnerSlotPricingTab> createState() => _PartnerSlotPricingTabState();
}

class _PartnerSlotPricingTabState extends ConsumerState<PartnerSlotPricingTab> {
  int? selectedVenueId;
  int? selectedCourtId;

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(partnerVenuesProvider).value ?? [];
    if (venues.isEmpty) return const Center(child: Text('No venues available.'));

    int? validVenueId = selectedVenueId;
    if (validVenueId != null && !venues.any((v) => v['id'] == validVenueId)) {
      validVenueId = null;
    }
    
    if (validVenueId == null) {
      validVenueId = venues.first['id'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedVenueId = validVenueId;
          });
        }
      });
    }

    final courtsAsync = ref.watch(partnerCourtsProvider(validVenueId!));

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Slot Pricing by Court', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              DropdownButton<int>(
                value: validVenueId,
                items: venues.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedVenueId = val;
                    selectedCourtId = null;
                  });
                },
              ),
              const SizedBox(width: 24),
              courtsAsync.when(
                data: (courts) {
                  if (courts.isEmpty) return const Text('No courts available for this venue.');
                  int? validCourtId = selectedCourtId;
                  if (validCourtId != null && !courts.any((c) => c['id'] == validCourtId)) {
                    validCourtId = null;
                  }

                  if (validCourtId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          selectedCourtId = courts.first['id'];
                        });
                      }
                    });
                  }
                  
                  return DropdownButton<int>(
                    value: validCourtId,
                    items: courts.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCourtId = val;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (selectedCourtId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time Periods Pricing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddPricingDialog(context, ref, selectedCourtId!),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Period'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final pricings = ref.watch(partnerSlotPricingsProvider(selectedCourtId!));
                  return pricings.when(
                    data: (data) {
                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final p = data[index];
                          return Card(
                            child: ListTile(
                              title: Text(p['time_period']),
                              subtitle: Text('${p['start_time']} - ${p['end_time']}'),
                              trailing: Text('₹${p['price']}'),
                              onTap: () => _showEditPricingDialog(context, ref, p),
                            ),
                          );
                        }
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  );
                }
              )
            ),
          ]
        ],
      )
    );
  }

  void _showAddPricingDialog(BuildContext context, WidgetRef ref, int courtId) {
    String timePeriod = 'Morning';
    final startTimeController = TextEditingController(text: '06:00:00');
    final endTimeController = TextEditingController(text: '12:00:00');
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Time Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: timePeriod,
                items: ['Morning', 'Daytime', 'Evening', 'Night'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => timePeriod = val!),
              ),
              TextField(controller: startTimeController, decoration: const InputDecoration(labelText: 'Start Time (HH:MM:SS)')),
              TextField(controller: endTimeController, decoration: const InputDecoration(labelText: 'End Time (HH:MM:SS)')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            ]
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('venues/court-slot-pricings/', data: {
                    'court': courtId,
                    'time_period': timePeriod,
                    'start_time': startTimeController.text,
                    'end_time': endTimeController.text,
                    'price': double.tryParse(priceController.text) ?? 0,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(partnerSlotPricingsProvider(courtId));
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            )
          ]
        )
      )
    );
  }

  void _showEditPricingDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> pricing) {
    final priceController = TextEditingController(text: pricing['price'].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Price for ${pricing['time_period']}'),
        content: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.patch('venues/court-slot-pricings/${pricing['id']}/', data: {
                  'price': double.tryParse(priceController.text) ?? 0,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(partnerSlotPricingsProvider(pricing['court']));
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          )
        ]
      )
    );
  }
}

// -------------------------------------------------------------
// PARTNER BOOKINGS TAB
// -------------------------------------------------------------

class PartnerBookingsTab extends ConsumerWidget {
  const PartnerBookingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(partnerBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
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
                      Text('Turf Slot Bookings & Check-ins', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Verify player arrival, manage slot confirmations, and check-in reservations.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(partnerBookingsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    final isCheckedIn = b['status'] == 'CHECKED_IN';
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isCheckedIn ? Colors.green.shade100 : Colors.teal.shade100,
                              child: Icon(
                                isCheckedIn ? Icons.check_circle : Icons.sports_tennis,
                                color: isCheckedIn ? Colors.green.shade800 : Colors.teal.shade800,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${b['customer_name']} - ${b['venue_name']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '📅 ${b['date']} | ⏰ ${b['start_time']} - ${b['end_time']} | 📍 ${b['court_name']}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                  ),
                                  Text('Phone: ${b['phone']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${b['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                const SizedBox(height: 6),
                                if (isCheckedIn)
                                  const Chip(label: Text('Checked In', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFE8F5E9))
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${b['customer_name']} verified and checked in!')));
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                    child: const Text('Verify Check-In'),
                                  ),
                              ],
                            ),
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
// PARTNER SETTLEMENTS TAB
// -------------------------------------------------------------

class PartnerSettlementsTab extends StatelessWidget {
  const PartnerSettlementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partner Settlements & Payouts', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Track automatic weekly direct bank transfers, platform fees, and tax invoices.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 28),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next Payout Date: 25 Sep 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Direct Transfer to HDFC Bank **** 9821', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Text('₹21,400 PENDING', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const ListTile(
                    leading: Icon(Icons.receipt_long, color: Colors.teal),
                    title: Text('Settlement Batch #GOATH-SETTL-8891'),
                    subtitle: Text('14 Sep - 20 Sep 2026 • 24 bookings settled'),
                    trailing: Text('₹57,000 PAID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ),
                  const ListTile(
                    leading: Icon(Icons.receipt_long, color: Colors.teal),
                    title: Text('Settlement Batch #GOATH-SETTL-8890'),
                    subtitle: Text('07 Sep - 13 Sep 2026 • 19 bookings settled'),
                    trailing: Text('₹48,200 PAID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
