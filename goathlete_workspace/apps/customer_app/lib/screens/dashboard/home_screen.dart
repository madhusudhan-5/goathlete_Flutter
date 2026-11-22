import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../providers/venue_provider.dart';
import '../../models/venue_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sports_news_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/venue_image_carousel.dart';
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
  String? _selectedLocationFilter;
  String _searchQuery = '';
  final TextEditingController _homeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition({bool filterByDetectedLocality = true}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _currentLocation = 'All Locations');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _currentLocation = 'All Locations');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _currentLocation = 'All Locations');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      String? resolvedLocation = await ref
          .read(venueProvider.notifier)
          .reverseGeocode(position.latitude, position.longitude);

      if (!kIsWeb && (resolvedLocation == null || resolvedLocation.isEmpty)) {
        try {
          List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            final parts = [place.subLocality, place.locality]
                .where((e) => e != null && e.isNotEmpty)
                .toList();
            if (parts.isNotEmpty) {
              resolvedLocation = parts.join(', ');
            } else if (place.name != null && place.name!.isNotEmpty) {
              resolvedLocation = place.name!;
            }
          }
        } catch (_) {}
      }

      resolvedLocation ??= 'Bengaluru, Karnataka';

      if (mounted) {
        setState(() {
          _currentLocation = resolvedLocation!;
          _selectedLocationFilter =
              filterByDetectedLocality ? resolvedLocation : null;
        });
      }

      await ref.read(venueProvider.notifier).fetchVenues(
            locationQuery: filterByDetectedLocality ? resolvedLocation : null,
            customLat: position.latitude,
            customLng: position.longitude,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Bengaluru, Karnataka';
          _selectedLocationFilter = null;
        });
      }
    }
  }

  Future<void> _applyLocationSelection(
    String locationLabel, {
    String? filterQuery,
    double? lat,
    double? lng,
  }) async {
    final cleanLabel = locationLabel.trim();
    if (cleanLabel.isEmpty) return;

    final bool isAll = cleanLabel.toLowerCase() == 'all locations';
    final String? effectiveFilter = isAll ? null : (filterQuery ?? cleanLabel);

    setState(() {
      _currentLocation = cleanLabel;
      _selectedLocationFilter = effectiveFilter;
    });

    await ref.read(venueProvider.notifier).fetchVenues(
          locationQuery: effectiveFilter,
          customLat: isAll ? null : lat,
          customLng: isAll ? null : lng,
        );
  }

  void _showLocationPickerSheet(BuildContext context) {
    final cachedVenues = ref.read(venueProvider.notifier).allVenuesCache;
    final currentVenues = ref.read(venueProvider).valueOrNull ?? [];
    final allKnown = {...cachedVenues, ...currentVenues};

    final List<Map<String, dynamic>> defaultQuickPlaces = [];
    final Set<String> seenNames = {};

    for (final v in allKnown) {
      final loc = v.location.trim();
      if (loc.isNotEmpty &&
          !loc.startsWith('Lat:') &&
          !seenNames.contains(loc.toLowerCase())) {
        seenNames.add(loc.toLowerCase());
        defaultQuickPlaces.add({
          'short_name': loc,
          'display_name': '${v.name} • $loc',
          'lat': v.latitude,
          'lng': v.longitude,
          'is_venue': true,
        });
      }
    }

    final popularAreas = [
      {
        'short_name': 'Hongasandra, Bengaluru',
        'display_name': 'Hongasandra, Bommanahalli, Bengaluru',
        'lat': 12.8986,
        'lng': 77.6287,
      },
      {
        'short_name': 'Electronic City, Bengaluru',
        'display_name': 'Electronic City, Bangalore South, Bengaluru',
        'lat': 12.8452,
        'lng': 77.6602,
      },
      {
        'short_name': 'HSR Layout, Bengaluru',
        'display_name': 'HSR Layout, Bengaluru, Karnataka',
        'lat': 12.9121,
        'lng': 77.6446,
      },
      {
        'short_name': 'Koramangala, Bengaluru',
        'display_name': 'Koramangala, Bengaluru, Karnataka',
        'lat': 12.9352,
        'lng': 77.6245,
      },
      {
        'short_name': 'Indiranagar, Bengaluru',
        'display_name': 'Indiranagar, Bengaluru, Karnataka',
        'lat': 12.9784,
        'lng': 77.6408,
      },
      {
        'short_name': 'Whitefield, Bengaluru',
        'display_name': 'Whitefield, Bengaluru, Karnataka',
        'lat': 12.9698,
        'lng': 77.7500,
      },
    ];

    for (final p in popularAreas) {
      final key = (p['short_name'] as String).toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        defaultQuickPlaces.add(p);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return _LocationSearchSheet(
          currentLocation: _currentLocation,
          initialQuickPlaces: defaultQuickPlaces,
          onSelectLocation: (label, lat, lng) {
            Navigator.pop(sheetCtx);
            _applyLocationSelection(label, lat: lat, lng: lng);
          },
          onUseGps: () {
            Navigator.pop(sheetCtx);
            _determinePosition(filterByDetectedLocality: true);
          },
          onSelectAll: () {
            Navigator.pop(sheetCtx);
            _applyLocationSelection('All Locations');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(profileProvider);

    final profileData = profileAsyncValue.value;
    final firstName = profileData?['first_name'];
    final displayName =
        (firstName != null && firstName.isNotEmpty) ? firstName : 'Athlete';
    final profilePicUrl = AppConfig.resolveMediaUrl(profileData?['profile_picture']);

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
                  _buildSportsNewsAds(
                      context, ref, profileData?['primary_sport'] ?? 'sports'),
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

  PreferredSizeWidget _buildTopHeader(
      BuildContext context, String? profilePicUrl) {
    return AppBar(
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showLocationPickerSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: GoAthleteColors.athleticOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: GoAthleteColors.athleticOrange.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on,
                  color: GoAthleteColors.athleticOrange, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _currentLocation,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit_location_alt_outlined,
                size: 16,
                color: GoAthleteColors.athleticOrange,
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.person_add,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Find your play tribe!')));
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_none,
              color: Theme.of(context).colorScheme.onSurface),
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
              backgroundImage:
                  profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
              child: profilePicUrl == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
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
                  style: const TextStyle(
                      color: GoAthleteColors.athleticOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
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
          controller: _homeSearchController,
          onChanged: (val) {
            setState(() => _searchQuery = val.trim());
          },
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              _applyLocationSelection(val.trim());
            }
          },
          decoration: InputDecoration(
            hintText: 'Search turfs, courts, or locations...',
            prefixIcon:
                const Icon(Icons.search, color: GoAthleteColors.athleticOrange),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _homeSearchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location,
                        color: GoAthleteColors.athleticOrange, size: 20),
                    tooltip: 'Change Location',
                    onPressed: () => _showLocationPickerSheet(context),
                  ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSportsNewsAds(
      BuildContext context, WidgetRef ref, String query) {
    return ref.watch(sportsNewsProvider(query)).when(
          data: (newsList) {
            if (newsList.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Sports Highlights & Offers',
                      style: Theme.of(context).textTheme.headlineMedium),
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
                              image: NetworkImage(news['image_url'] ??
                                  'https://via.placeholder.com/300x150'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.4),
                                  BlendMode.darken),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: GoAthleteColors.athleticOrange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('AD',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news['title'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to read more',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12),
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
          loading: () =>
              const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nearby Venues',
                        style: Theme.of(context).textTheme.headlineMedium),
                    if (_selectedLocationFilter != null &&
                        _selectedLocationFilter!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt,
                                size: 14, color: GoAthleteColors.athleticOrange),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Near: $_selectedLocationFilter',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: GoAthleteColors.athleticOrange,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  _applyLocationSelection('All Locations'),
                              child: const Text(
                                'Show All',
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_location_alt,
                    color: GoAthleteColors.athleticOrange),
                tooltip: 'Change Location',
                onPressed: () => _showLocationPickerSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ref.watch(venueProvider).when(
                data: (venues) {
                  final filtered = _searchQuery.isEmpty
                      ? venues
                      : venues.where((v) {
                          final q = _searchQuery.toLowerCase();
                          return v.name.toLowerCase().contains(q) ||
                              v.location.toLowerCase().contains(q) ||
                              v.description.toLowerCase().contains(q);
                        }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyVenuesState(context);
                  }
                  return Column(
                    children: filtered
                        .map((venue) =>
                            _buildDynamicVenueCard(context, ref, venue))
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                        color: GoAthleteColors.athleticOrange),
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
    final hasFilter = (_selectedLocationFilter != null &&
            _selectedLocationFilter!.isNotEmpty) ||
        _searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stadium_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'No Venues Found Near "${_selectedLocationFilter ?? _searchQuery}"'
                : 'No Venue Found Nearby',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try searching another locality or tap "Show All Venues" below.'
                : 'There are no sports venues or turfs listed in this area yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (hasFilter)
                OutlinedButton.icon(
                  icon: const Icon(Icons.public, size: 18),
                  label: const Text('Show All Venues'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GoAthleteColors.athleticOrange,
                    side: const BorderSide(color: GoAthleteColors.athleticOrange),
                  ),
                  onPressed: () {
                    _homeSearchController.clear();
                    setState(() => _searchQuery = '');
                    _applyLocationSelection('All Locations');
                  },
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.emoji_events, size: 18),
                label: const Text('View Live Tournaments'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoAthleteColors.athleticOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  context.go('/tournaments');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicVenueCard(
      BuildContext context, WidgetRef ref, Venue venue) {
    final List<String> locParts = [];
    if (venue.location.isNotEmpty) locParts.add(venue.location);
    if (venue.distance.isNotEmpty) locParts.add(venue.distance);
    final String locationLine =
        locParts.isNotEmpty ? locParts.join(' • ') : 'Location available on map';

    return GestureDetector(
      onTap: () {
        ref.read(bookingFlowProvider.notifier).state = BookingFlowState(
          venue: {
            'id': venue.id,
            'name': venue.name,
            'description': venue.description,
            'location': venue.location,
            'price_per_hour': venue.pricePerHour,
            'image_url': venue.imageUrl,
            'images': venue.allImageUrls,
            'ground_type': venue.groundType,
            'sports': venue.sports.map((s) => s.sport.name).toList(),
            'distance': venue.distance,
            'rating': venue.rating,
          },
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
              VenueImageCarousel(
                imageUrls: venue.allImageUrls,
                height: 160,
                borderRadius: BorderRadius.circular(16),
                overlayChild: Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text('${venue.rating}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
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
                  Text('₹${venue.pricePerHour}/hr',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: GoAthleteColors.athleticOrange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 15, color: GoAthleteColors.athleticOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationLine,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends ConsumerStatefulWidget {
  final String currentLocation;
  final List<Map<String, dynamic>> initialQuickPlaces;
  final void Function(String label, double? lat, double? lng) onSelectLocation;
  final VoidCallback onUseGps;
  final VoidCallback onSelectAll;

  const _LocationSearchSheet({
    required this.currentLocation,
    required this.initialQuickPlaces,
    required this.onSelectLocation,
    required this.onUseGps,
    required this.onSelectAll,
  });

  @override
  ConsumerState<_LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<_LocationSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  String _query = '';
  List<Map<String, dynamic>> _liveSuggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    _debounce?.cancel();

    if (trimmed.length < 2) {
      setState(() {
        _liveSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results =
          await ref.read(venueProvider.notifier).searchPlaces(trimmed);
      if (mounted) {
        setState(() {
          _liveSuggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayList =
        _query.length >= 2 ? _liveSuggestions : widget.initialQuickPlaces;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_location_alt,
                        color: GoAthleteColors.athleticOrange),
                    SizedBox(width: 8),
                    Text(
                      'Select or Search Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search area, city, or turf (e.g. Hongasandra)...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: GoAthleteColors.athleticOrange,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _controller.clear();
                                _onQueryChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _onQueryChanged,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        widget.onSelectLocation(val.trim(), null, null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoAthleteColors.athleticOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final q = _controller.text.trim();
                    if (q.isNotEmpty) {
                      if (_liveSuggestions.isNotEmpty) {
                        final first = _liveSuggestions.first;
                        widget.onSelectLocation(
                          first['short_name']?.toString() ?? q,
                          (first['lat'] as num?)?.toDouble(),
                          (first['lng'] as num?)?.toDouble(),
                        );
                      } else {
                        widget.onSelectLocation(q, null, null);
                      }
                    }
                  },
                  child: const Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location, size: 17),
                    label: const Text(
                      'Use GPS Location',
                      style:
                          TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GoAthleteColors.athleticOrange,
                      side: const BorderSide(
                          color: GoAthleteColors.athleticOrange),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.onUseGps,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.public, size: 17),
                    label: const Text(
                      'All Locations',
                      style:
                          TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GoAthleteColors.deepNavy,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.onSelectAll,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  _query.length >= 2
                      ? 'Map & Venue Search Results'
                      : 'Available & Popular Locations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.34,
              ),
              child: displayList.isEmpty && !_isSearching
                  ? ListTile(
                      leading: const Icon(Icons.place,
                          color: GoAthleteColors.athleticOrange),
                      title: Text('Search venues near "$_query"'),
                      subtitle:
                          const Text('Tap to find turfs around this location'),
                      onTap: () => widget.onSelectLocation(_query, null, null),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = displayList[idx];
                        final String shortName =
                            item['short_name']?.toString() ?? '';
                        final String displayName =
                            item['display_name']?.toString() ?? shortName;
                        final double? lat = (item['lat'] as num?)?.toDouble();
                        final double? lng = (item['lng'] as num?)?.toDouble();
                        final bool isVenue = item['is_venue'] == true;
                        final bool isCurrent = widget.currentLocation
                                .toLowerCase() ==
                            shortName.toLowerCase();

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          leading: Icon(
                            isVenue ? Icons.stadium : Icons.location_on,
                            color: isCurrent
                                ? Colors.green
                                : GoAthleteColors.athleticOrange,
                            size: 20,
                          ),
                          title: Text(
                            shortName,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: displayName != shortName
                              ? Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                              : null,
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 18)
                              : const Icon(Icons.north_west,
                                  size: 16, color: Colors.grey),
                          onTap: () =>
                              widget.onSelectLocation(shortName, lat, lng),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
