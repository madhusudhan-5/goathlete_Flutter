import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/partner/partner_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/admin',
  routes: [
    // Root Redirect
    GoRoute(
      path: '/',
      redirect: (context, state) => '/admin',
    ),

    // GoAthlete Super Admin
    GoRoute(
      path: '/admin',
      builder: (context, state) => const GoAthleteAdminShell(),
    ),
    GoRoute(
      path: '/goathlete-admin',
      redirect: (context, state) => '/admin',
    ),

    // Partner Admin Portal
    GoRoute(
      path: '/partner-admin',
      builder: (context, state) => const PartnerAdminShell(),
    ),
    GoRoute(
      path: '/partner',
      redirect: (context, state) => '/partner-admin',
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text('Page Not Found: ${state.uri}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/admin'),
            child: const Text('Return to GoAthlete Admin'),
          ),
        ],
      ),
    ),
  ),
);
