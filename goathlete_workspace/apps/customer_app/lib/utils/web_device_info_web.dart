import 'dart:js_interop';

@JS('window.navigator.userAgent')
external String get _userAgent;

@JS('window.navigator.maxTouchPoints')
external int? get _maxTouchPoints;

@JS('window.location.href')
external String get _locationHref;

@JS('window.matchMedia')
external _MediaQueryList _matchMedia(String query);

extension type _MediaQueryList(JSObject _) implements JSObject {
  external bool get matches;
}

@JS('window.localStorage')
external _Storage get _localStorage;

extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

final RegExp _mobileTabletUaRegex = RegExp(
  r'android|iphone|ipad|ipod|blackberry|iemobile|opera mini|mobile|tablet|silk|kindle|playbook|webos',
  caseSensitive: false,
);

/// Returns true only on mobile phones and tablets (including iPadOS Safari in
/// desktop-mode and browser mobile/tablet device emulators).
bool isMobileOrTabletBrowser() {
  try {
    final ua = _userAgent;
    if (_mobileTabletUaRegex.hasMatch(ua)) {
      return true;
    }

    // iPadOS 13+ reports "Macintosh" in UA while supporting multi-touch.
    final touchPoints = _maxTouchPoints ?? 0;
    if (ua.toLowerCase().contains('macintosh') && touchPoints > 1) {
      return true;
    }

    // Fallback for touch-first tablets (e.g. Android tablets requesting desktop site).
    final hasCoarsePointer = _matchMedia('(pointer: coarse)').matches;
    final hasNoHover = _matchMedia('(hover: none)').matches;
    if (hasCoarsePointer && hasNoHover && touchPoints > 0) {
      return true;
    }

    return false;
  } catch (_) {
    return false;
  }
}

String currentBrowserUrl() {
  try {
    return _locationHref;
  } catch (_) {
    return '';
  }
}

String? webLocalStorageRead(String key) {
  try {
    return _localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void webLocalStorageWrite(String key, String value) {
  try {
    _localStorage.setItem(key, value);
  } catch (_) {}
}

void webLocalStorageDelete(String key) {
  try {
    _localStorage.removeItem(key);
  } catch (_) {}
}
