import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/admin_provider.dart';

class AdminTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final PortalMode currentMode;

  const AdminTopBar({
    super.key,
    required this.title,
    required this.currentMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = currentMode == PortalMode.goathleteAdmin;
    final adminToken = ref.watch(adminTokenProvider);
    final partnerToken = ref.watch(partnerTokenProvider);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo & Brand
          InkWell(
            onTap: () => context.go(isAdmin ? '/admin' : '/partner-admin'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAdmin ? GoAthleteColors.athleticOrange : Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GoAthlete Web',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                    ),
                    Text(
                      isAdmin ? 'Super Admin Portal' : 'Partner & Turf Portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isAdmin ? GoAthleteColors.athleticOrange : Colors.teal.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // Portal Switcher Tabs (Direct URL Routing)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPortalTab(
                  context: context,
                  label: 'GoAthlete Admin',
                  icon: Icons.admin_panel_settings_rounded,
                  isSelected: isAdmin,
                  activeColor: GoAthleteColors.athleticOrange,
                  route: '/admin',
                ),
                const SizedBox(width: 4),
                _buildPortalTab(
                  context: context,
                  label: 'Partner Admin',
                  icon: Icons.stadium_rounded,
                  isSelected: !isAdmin,
                  activeColor: Colors.teal.shade700,
                  route: '/partner-admin',
                ),
              ],
            ),
          ),

          const Spacer(),

          // Active URL helper badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isAdmin ? GoAthleteColors.athleticOrange : Colors.teal).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  size: 14,
                  color: isAdmin ? GoAthleteColors.athleticOrange : Colors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  isAdmin ? '/admin' : '/partner-admin',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAdmin ? GoAthleteColors.athleticOrange : Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // User Session / Logout
          if ((isAdmin && adminToken != null) || (!isAdmin && partnerToken != null)) ...[
            Chip(
              avatar: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 14, color: Colors.black87),
              ),
              label: Text(
                isAdmin ? 'Super Admin' : 'Turf Partner',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              tooltip: 'Logout',
              onPressed: () {
                if (isAdmin) {
                  ref.read(adminTokenProvider.notifier).state = null;
                } else {
                  ref.read(partnerTokenProvider.notifier).state = null;
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortalTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
