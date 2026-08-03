import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/venue_provider.dart';
import '../../models/venue_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildTopHeader(context),
      drawer: const Drawer(), // Side menu placeholder
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLocationAndReadyToPlay(context),
                  const SizedBox(height: 16),
                  _buildSearchBar(context),
                  const SizedBox(height: 24),
                  dashboardAsync.when(
                    data: (config) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHighlightsBanner(context, config.banners),
                        const SizedBox(height: 32),
                        _buildPlayBySports(context, config.sports),
                        const SizedBox(height: 24),
                        _buildNearbyVenues(context, ref),
                        const SizedBox(height: 24),
                        _buildHorizontalCardsRow(context, config.quickActions),
                        const SizedBox(height: 24),
                        _buildFooterQuickLinks(context),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Error loading dashboard: $error')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      elevation: 0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.location_on, color: GoAthleteColors.athleticOrange, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'HSR Layout, Bangalore',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 20, color: Theme.of(context).colorScheme.onSurface),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSurface), // Add people icon
          onPressed: () {
            // Create games with strangers and split payment
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Find your play tribe!')));
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_none, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            context.push('/notifications');
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              context.push('/profile-details');
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndReadyToPlay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: 'Ready to Play, ',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: const [
                TextSpan(
                  text: 'Athlete!',
                  style: TextStyle(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search turfs, courts, and matches...',
            prefixIcon: const Icon(Icons.search, color: GoAthleteColors.athleticOrange),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightsBanner(BuildContext context, List<HighlightBanner> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(banner.imageUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(24),
              child: Text(
                banner.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayBySports(BuildContext context, List<SportCategory> sports) {
    if (sports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Play by Sports', style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sports.length,
            itemBuilder: (context, index) {
              final sport = sports[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        _getIconData(sport.iconName),
                        color: GoAthleteColors.athleticOrange,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sport.name,
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyVenues(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nearby Venues', style: Theme.of(context).textTheme.headlineMedium),
              const Icon(Icons.tune, color: GoAthleteColors.athleticOrange),
            ],
          ),
          const SizedBox(height: 16),
          
          ref.watch(venueProvider).when(
            data: (venues) {
               // Showing only 2 items here for brevity since we added more sections above and below
              final items = venues.take(2).toList();
              if (items.isEmpty) {
                return const Center(child: Text("No venues found."));
              }
              return Column(
                children: items.map((venue) => _buildDynamicVenueCard(context, venue)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCardsRow(BuildContext context, List<QuickAction> actions) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () {
              if (action.route.isNotEmpty) {
                context.push(action.route);
              }
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GoAthleteColors.athleticOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIconData(action.iconName), color: GoAthleteColors.athleticOrange, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooterQuickLinks(BuildContext context) {
    final links = [
      {'title': 'Vouchers', 'icon': Icons.card_giftcard},
      {'title': 'Support & Help', 'icon': Icons.help_outline},
      {'title': 'Corporate Connect (Coming Soon)', 'icon': Icons.business},
      {'title': 'Loans on sports training (Coming Soon)', 'icon': Icons.account_balance},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More for you', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ...links.map((link) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Icon(link['icon'] as IconData, color: GoAthleteColors.athleticOrange),
            ),
            title: Text(link['title'] as String, style: Theme.of(context).textTheme.labelMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDynamicVenueCard(BuildContext context, Venue venue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(venue.imageUrl.isNotEmpty ? venue.imageUrl : 'https://images.unsplash.com/photo-1574629810360-7efbb2639446'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text('${venue.rating}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(venue.name, style: Theme.of(context).textTheme.titleMedium),
                Text('₹${venue.pricePerHour}/hr', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: GoAthleteColors.athleticOrange)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(venue.distance, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'sports_tennis': return Icons.sports_tennis;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports_cricket': return Icons.sports_cricket;
      case 'sports_baseball': return Icons.sports_baseball;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'sports_esports': return Icons.sports_esports;
      case 'emoji_events': return Icons.emoji_events;
      case 'model_training': return Icons.model_training;
      case 'stadium': return Icons.stadium;
      case 'groups': return Icons.groups;
      default: return Icons.sports;
    }
  }
}
