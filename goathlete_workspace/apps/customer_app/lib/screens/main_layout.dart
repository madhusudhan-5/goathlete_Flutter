import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  DateTime? _lastBackPressTime;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If on another tab (e.g. Tournaments, Bookings, Favorites, Performance), navigate back to Explore (tab 0)
        if (widget.navigationShell.currentIndex != 0) {
          _goBranch(0);
          return;
        }

        // On Explore tab: require double press within 2 seconds to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit GoAthlete'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Allow app exit
        Navigator.of(context).pop();
      },
      child: Scaffold(
        extendBody: false,
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: BottomNavigationBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _goBranch,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: GoAthleteColors.athleticOrange,
                unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                showSelectedLabels: true,
                showUnselectedLabels: true,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month),
                    label: 'Bookings',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_outlined),
                    activeIcon: Icon(Icons.emoji_events),
                    label: 'Tournaments',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_outlined),
                    activeIcon: Icon(Icons.bar_chart),
                    label: 'Performance',
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

