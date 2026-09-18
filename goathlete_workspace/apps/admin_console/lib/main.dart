import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network/api_client.dart';
import 'providers/admin_provider.dart';
import 'screens/executive_screen.dart';
import 'screens/config_screen.dart';
import 'screens/offers_screen.dart';

void main() {
  runApp(const ProviderScope(child: AdminConsoleApp()));
}

final authStateProvider = StateProvider<String?>((ref) => null);

class AdminConsoleApp extends ConsumerStatefulWidget {
  const AdminConsoleApp({super.key});

  @override
  ConsumerState<AdminConsoleApp> createState() => _AdminConsoleAppState();
}

class _AdminConsoleAppState extends ConsumerState<AdminConsoleApp> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkSavedToken();
  }

  Future<void> _checkSavedToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      ref.read(authStateProvider.notifier).state = token;
    }
    if (mounted) {
      setState(() => _checkingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'GoAthlete Super Admin',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _checkingAuth
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (token == null ? const AdminLoginScreen() : const AdminDashboardScreen()),
    );
  }
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter both username and password.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('users/login/', data: {
        'username': username,
        'password': password,
      });
      final token = response.data['access'];
      const storage = FlutterSecureStorage();
      await storage.write(key: 'access_token', value: token);
      ref.read(authStateProvider.notifier).state = token;
      ref.refresh(adminAnalyticsProvider);
      ref.refresh(pendingVenuesProvider);
    } catch (e) {
      if (e is DioException) {
        setState(() => _error = e.response?.data?['detail'] ?? 'Login failed. Invalid credentials.');
      } else {
        setState(() => _error = 'Login error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Super Admin Login'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 64, color: GoAthleteColors.athleticOrange),
                  const SizedBox(height: 16),
                  Text(
                    'Super Admin Console',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
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
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoAthleteColors.athleticOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login to Console', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'access_token');
              ref.read(authStateProvider.notifier).state = null;
            },
          ),
        ],
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
