import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:core_ui/core_ui.dart';

void main() {
  runApp(const ProviderScope(child: AdminWebApp()));
}

final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api/',
    headers: {'Content-Type': 'application/json'},
  ));
  return dio;
});

final authStateProvider = StateProvider<String?>((ref) => null);

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoAthlete Admin',
      theme: GoAthleteTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authStateProvider);
    if (token == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GoAthlete Web Admin'),
        backgroundColor: GoAthleteColors.athleticOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).state = null,
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: GoAthleteColors.athleticOrange),
            selectedLabelTextStyle: const TextStyle(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: Text('Executives List'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_add_outlined),
                selectedIcon: Icon(Icons.person_add),
                label: Text('Add Executive'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _currentIndex == 0 ? const ExecutivesListScreen() : const AddExecutiveScreen(),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('users/login/', data: {
        'username': _usernameController.text,
        'password': _passwordController.text,
      });
      final token = response.data['access'];
      dio.options.headers['Authorization'] = 'Bearer $token';
      ref.read(authStateProvider.notifier).state = token;
    } catch (e) {
      setState(() => _error = 'Login failed. Check credentials.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login'), backgroundColor: GoAthleteColors.athleticOrange),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutivesListScreen extends ConsumerStatefulWidget {
  const ExecutivesListScreen({super.key});

  @override
  ConsumerState<ExecutivesListScreen> createState() => _ExecutivesListScreenState();
}

class _ExecutivesListScreenState extends ConsumerState<ExecutivesListScreen> {
  bool _loading = false;
  List<dynamic> _executives = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExecutives();
  }

  Future<void> _fetchExecutives() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('users/executives/');
      setState(() {
        _executives = response.data as List<dynamic>;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load executives: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteExecutive(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('users/executives/$id/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executive deleted successfully')));
      }
      _fetchExecutives();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchExecutives, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Field Executives (${_executives.length})', style: Theme.of(context).textTheme.headlineMedium),
              ElevatedButton.icon(
                onPressed: _fetchExecutives,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_executives.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No executives registered yet.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Click "Add Executive" in the sidebar to onboard field executives.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView.separated(
                  itemCount: _executives.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final exec = _executives[index];
                    final profile = exec['profile'] ?? {};
                    final firstName = exec['first_name'] ?? '';
                    final lastName = exec['last_name'] ?? '';
                    final fullName = '$firstName $lastName'.trim();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: GoAthleteColors.athleticOrange.withOpacity(0.1),
                        foregroundColor: GoAthleteColors.athleticOrange,
                        child: const Icon(Icons.person),
                      ),
                      title: Text(fullName.isNotEmpty ? fullName : 'Executive #${exec['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Phone: ${profile['phone_number'] ?? exec['username'] ?? 'N/A'} • GOATH-ID: ${profile['goath_id'] ?? 'Pending'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Executive',
                        onPressed: () => _deleteExecutive(exec['id']),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddExecutiveScreen extends ConsumerStatefulWidget {
  const AddExecutiveScreen({super.key});
  @override
  ConsumerState<AddExecutiveScreen> createState() => _AddExecutiveScreenState();
}

class _AddExecutiveScreenState extends ConsumerState<AddExecutiveScreen> {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _loading = false;
  String? _message;

  void _addExecutive() async {
    setState(() { _loading = true; _message = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('users/executives/', data: {
        'username': _phoneController.text.trim(),
        'password': 'temp_password_123',
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'profile': {
          'phone_number': _phoneController.text.trim()
        }
      });
      setState(() { 
        _message = 'Executive created successfully!'; 
        _phoneController.clear(); 
        _firstNameController.clear(); 
        _lastNameController.clear(); 
      });
    } catch (e) {
      if (e is DioException) {
         setState(() => _message = 'Failed: ${e.response?.data}');
      } else {
         setState(() => _message = 'Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Create New Executive Account', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number (10 digits)')),
            const SizedBox(height: 16),
            TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 16),
            TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
            const SizedBox(height: 24),
            if (_message != null) Text(_message!, style: TextStyle(color: _message!.contains('Failed') ? Colors.red : Colors.green)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _addExecutive,
                style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Executive'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
