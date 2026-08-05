import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/screens/auth/splash_screen.dart';
import 'package:customer_app/screens/auth/login_screen.dart';
import 'package:customer_app/screens/auth/profile_completion_screen.dart';
import 'package:customer_app/screens/profile/profile_setup_screen.dart';
import 'package:customer_app/screens/main_layout.dart';
import 'package:customer_app/screens/dashboard/home_screen.dart';
import 'package:customer_app/screens/dashboard/bookings_screen.dart';
import 'package:customer_app/screens/dashboard/tournaments_screen.dart';
import 'package:customer_app/screens/dashboard/favorites_screen.dart';
import 'package:customer_app/screens/dashboard/performance_screen.dart';
import 'package:customer_app/screens/booking/venue_details_screen.dart';
import 'package:customer_app/screens/booking/slot_selection_screen.dart';
import 'package:customer_app/screens/booking/booking_checkout_screen.dart';
import 'package:customer_app/screens/dashboard/upcoming_events_screen.dart';
import 'package:customer_app/screens/community/play_tribes_screen.dart';
import 'package:customer_app/screens/profile/notifications_screen.dart';
import 'package:customer_app/screens/profile/profile_details_screen.dart';
import 'package:customer_app/screens/organizer/organizer_hub_screen.dart';
import 'package:customer_app/screens/organizer/create_tournament_wizard.dart';
import 'package:customer_app/screens/organizer/manage_tournaments_screen.dart';
import 'package:customer_app/screens/team/create_team_screen.dart';
import 'package:customer_app/screens/team/qr_scanner_screen.dart';
import 'package:customer_app/screens/scoring/live_scorer_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/profile-completion',
      builder: (context, state) => const ProfileCompletionScreen(),
    ),
    // Booking Flow Routes (Outside Bottom Navigation so they hide the nav bar)
    GoRoute(
      path: '/venue-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VenueDetailsScreen(),
    ),
    GoRoute(
      path: '/slot-selection',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SlotSelectionScreen(),
    ),
    GoRoute(
      path: '/booking-checkout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BookingCheckoutScreen(),
    ),
    // Sub-screens Routes
    GoRoute(
      path: '/upcoming-events',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UpcomingEventsScreen(),
    ),
    GoRoute(
      path: '/play-tribes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PlayTribesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileDetailsScreen(),
    ),
    GoRoute(
      path: '/live-scorer/:matchId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? 'unknown';
        return LiveScorerScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/create-tournament',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateTournamentWizard(),
    ),
    GoRoute(
      path: '/manage-tournaments',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ManageTournamentsScreen(),
    ),
    GoRoute(
      path: '/create-team',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateTeamScreen(),
    ),
    GoRoute(
      path: '/qr-scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const QRScannerScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const BookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tournaments',
              builder: (context, state) => const TournamentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/performance',
              builder: (context, state) => const PerformanceScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
