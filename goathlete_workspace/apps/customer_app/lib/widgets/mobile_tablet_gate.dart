import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_config.dart';
import '../utils/web_device_info.dart';

/// Returns true when the current runtime should show the full customer app.
/// Native mobile apps are always allowed; web is restricted to phones & tablets.
bool isAllowedWebDevice() {
  if (!kIsWeb) return true;
  return isMobileOrTabletBrowser();
}

/// Branded gate screen shown on desktop/laptop browsers when accessing the
/// mobile & tablet-only customer web app.
class DesktopBlockedScreen extends StatefulWidget {
  const DesktopBlockedScreen({super.key});

  @override
  State<DesktopBlockedScreen> createState() => _DesktopBlockedScreenState();
}

class _DesktopBlockedScreenState extends State<DesktopBlockedScreen> {
  bool _copied = false;

  String get _targetUrl {
    final liveUrl = currentBrowserUrl().trim();
    if (liveUrl.isNotEmpty) {
      return liveUrl;
    }
    return AppConfig.webAppUrl;
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _targetUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied! Open it on your phone or tablet.'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetUrl = _targetUrl;

    return Scaffold(
      backgroundColor: GoAthleteColors.deepestMidnight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GoAthleteColors.deepestMidnight,
              GoAthleteColors.deepNavy,
              Color(0xFF0E2944),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/appIcon.png',
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 12),
                        Image.asset(
                          'assets/images/goAthleteLogo.png',
                          height: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GoAthleteColors.athleticOrange.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: GoAthleteColors.athleticOrange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.devices_other_rounded,
                            size: 16,
                            color: GoAthleteColors.athleticOrange,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'PHONES & TABLETS ONLY',
                            style: TextStyle(
                              color: GoAthleteColors.athleticOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Open GoAthlete on your Phone or Tablet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The GoAthlete Customer Web App is designed exclusively for mobile phones and tablets. Scan the QR code below with your camera to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: GoAthleteColors.athleticOrange.withValues(alpha: 0.22),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: targetUrl,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: GoAthleteColors.deepNavy,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: GoAthleteColors.deepestMidnight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _copyLink,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                targetUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              _copied ? Icons.check_circle : Icons.copy_rounded,
                              size: 18,
                              color: _copied
                                  ? Colors.greenAccent
                                  : GoAthleteColors.athleticOrange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.ios_share_rounded,
                            color: GoAthleteColors.athleticOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'iPhone & iPad tip: Open in Safari, tap Share, then choose "Add to Home Screen" for a full-screen app experience.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
