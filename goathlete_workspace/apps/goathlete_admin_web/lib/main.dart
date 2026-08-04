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

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authStateProvider);
    if (token == null) {
      return const LoginScreen();
    }
    return const AddExecutiveScreen();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');
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
        'username': _phoneController.text,
        'password': 'temp_password_123', // required for django user
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'profile': {
          'phone_number': _phoneController.text
        }
      });
      setState(() { _message = 'Executive created successfully!'; _phoneController.clear(); _firstNameController.clear(); _lastNameController.clear(); });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Executive'),
        backgroundColor: GoAthleteColors.athleticOrange,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(authStateProvider.notifier).state = null)
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
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
      ),
    );
  }
}
