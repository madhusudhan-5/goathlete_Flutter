import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/venue_provider.dart';
import '../../models/venue_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(profileProvider);

    final profileData = profileAsyncValue.value;
    final firstName = profileData?['first_name'];
    final displayName = (firstName != null && firstName.isNotEmpty) ? firstName : 'Athlete';
    final profilePicUrl = profileData?['profile_picture'] != null 
        ? (profileData!['profile_picture'].toString().startsWith('http') 
            ? profileData!['profile_picture'] 
            : 'http://192.168.1.218:8000${profileData!['profile_picture']}') 
        : 'https://i.pravatar.cc/100';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildTopHeader(context, profilePicUrl),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLocationAndReadyToPlay(context, displayName),
                  const SizedBox(height: 16),
                  _buildSearchBar(context),
                  const SizedBox(height: 24),
                  _buildNearbyVenues(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopHeader(BuildContext context, String profilePicUrl) {
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
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profilePicUrl),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndReadyToPlay(BuildContext context, String userName) {
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
              children: [
                TextSpan(
                  text: '$userName!',
                  style: const TextStyle(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold),
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
              if (venues.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "No venues currently",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: venues.map((venue) => _buildDynamicVenueCard(context, ref, venue)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicVenueCard(BuildContext context, WidgetRef ref, Venue venue) {
    return GestureDetector(
      onTap: () {
        // Save the selected venue to the global booking flow state
        ref.read(bookingFlowProvider.notifier).state = BookingFlowState(
          venue: {
            'id': venue.id,
            'name': venue.name,
            'price_per_hour': venue.pricePerHour,
            'image_url': venue.imageUrl,
            'distance': venue.distance,
            'rating': venue.rating,
          }
        );
        context.push('/venue-details');
      },
      child: Padding(
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
                  image: NetworkImage(venue.imageUrl.isNotEmpty ? venue.imageUrl : 'https://placehold.co/400x200/png'),
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
