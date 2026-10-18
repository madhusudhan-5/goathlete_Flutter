import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/venue_provider.dart';
import '../../models/venue_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sports_news_provider.dart';
import '../../widgets/app_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _currentLocation = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _currentLocation = 'Location disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _currentLocation = 'Permission denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _currentLocation = 'Permission denied forever');
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            final parts = [place.subLocality, place.locality].where((e) => e != null && e.isNotEmpty).toList();
            _currentLocation = parts.isNotEmpty 
                ? parts.join(', ') 
                : (place.name ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
          } else {
            _currentLocation = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocation = 'HSR Layout, Bangalore');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(profileProvider);

    final profileData = profileAsyncValue.value;
    final firstName = profileData?['first_name'];
    final displayName = (firstName != null && firstName.isNotEmpty) ? firstName : 'Athlete';
    final profilePicUrl = (profileData?['profile_picture'] != null && profileData!['profile_picture'].toString().isNotEmpty)
        ? (profileData['profile_picture'].toString().startsWith('http') 
            ? profileData['profile_picture'] 
            : 'http://72.60.193.38${profileData['profile_picture']}') 
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  _buildSportsNewsAds(context, ref, profileData?['primary_sport'] ?? 'sports'),
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

  PreferredSizeWidget _buildTopHeader(BuildContext context, String? profilePicUrl) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
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
              _currentLocation,
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
              backgroundColor: GoAthleteColors.athleticOrange,
              backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
              child: profilePicUrl == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$userName!',
                  style: const TextStyle(color: GoAthleteColors.athleticOrange, fontWeight: FontWeight.bold, fontSize: 20),
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
              color: Colors.black.withValues(alpha: 0.04),
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

  Widget _buildSportsNewsAds(BuildContext context, WidgetRef ref, String query) {
    return ref.watch(sportsNewsProvider(query)).when(
      data: (newsList) {
        if (newsList.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Sports Highlights & Offers', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final news = newsList[index];
                  return GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(news['link']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(news['image_url'] ?? 'https://via.placeholder.com/300x150'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: GoAthleteColors.athleticOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              news['title'] ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to read more',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
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
                return _buildEmptyVenuesState(context);
              }
              return Column(
                children: venues.map((venue) => _buildDynamicVenueCard(context, ref, venue)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: GoAthleteColors.athleticOrange),
              ),
            ),
            error: (error, stack) => _buildEmptyVenuesState(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVenuesState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stadium_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Venue Found Nearby',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no sports venues or turfs listed in this area yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.emoji_events, size: 18),
            label: const Text('View Live Tournaments'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GoAthleteColors.athleticOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              context.go('/tournaments');
            },
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
                        color: Colors.black.withValues(alpha: 0.6),
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
                Expanded(
                  child: Text(
                    venue.name, 
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
}


