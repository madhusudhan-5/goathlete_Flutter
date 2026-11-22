import 'dart:async';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Auto-scrolling image gallery for venue cards and venue details hero headers.
class VenueImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius? borderRadius;
  final Duration autoScrollInterval;
  final bool darkenOverlay;
  final Widget? overlayChild;

  const VenueImageCarousel({
    super.key,
    required this.imageUrls,
    required this.height,
    this.borderRadius,
    this.autoScrollInterval = const Duration(milliseconds: 3500),
    this.darkenOverlay = false,
    this.overlayChild,
  });

  @override
  State<VenueImageCarousel> createState() => _VenueImageCarouselState();
}

class _VenueImageCarouselState extends State<VenueImageCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  List<String> get _resolvedUrls {
    final urls = <String>[];
    for (final raw in widget.imageUrls) {
      final resolved = AppConfig.resolveMediaUrl(raw);
      if (resolved != null && resolved.isNotEmpty && !urls.contains(resolved)) {
        urls.add(resolved);
      }
    }
    return urls;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant VenueImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _currentPage = 0;
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final urls = _resolvedUrls;
    if (urls.length <= 1) return;

    _autoScrollTimer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final total = _resolvedUrls.length;
      if (total <= 1) return;
      final nextPage = (_currentPage + 1) % total;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [GoAthleteColors.deepNavy, GoAthleteColors.athleticOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 52, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _resolvedUrls;

    Widget content = SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urls.isEmpty)
            _buildPlaceholder()
          else
            PageView.builder(
              controller: _pageController,
              itemCount: urls.length,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => _currentPage = index);
                }
                // Restart timer so manual swipe gets a full interval before auto-advancing
                _startAutoScroll();
              },
              itemBuilder: (context, index) {
                return Image.network(
                  urls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                  color: widget.darkenOverlay
                      ? Colors.black.withValues(alpha: 0.28)
                      : null,
                  colorBlendMode: widget.darkenOverlay ? BlendMode.darken : null,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: GoAthleteColors.deepNavy.withValues(alpha: 0.2),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GoAthleteColors.athleticOrange,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                );
              },
            ),
          if (urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? GoAthleteColors.athleticOrange
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          if (urls.length > 1)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentPage + 1}/${urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (widget.overlayChild != null) widget.overlayChild!,
        ],
      ),
    );

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
