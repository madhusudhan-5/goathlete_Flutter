import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/web_device_info.dart';

/// Cross-platform key-value storage that uses [FlutterSecureStorage] on mobile
/// and HTTPS web origins, with a safe `localStorage` fallback on non-HTTPS web
/// testing origins where Web Crypto (`crypto.subtle`) is unavailable.
class AppStorage {
  const AppStorage();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _webKeyPrefix = 'goathlete_';

  Future<String?> read({required String key}) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null || !kIsWeb) return value;
    } catch (_) {
      // Fallback below on web when Web Crypto is unavailable.
    }
    if (kIsWeb) {
      return webLocalStorageRead('$_webKeyPrefix$key');
    }
    return null;
  }

  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await delete(key: key);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
      return;
    } catch (_) {
      if (!kIsWeb) rethrow;
    }
    if (kIsWeb) {
      webLocalStorageWrite('$_webKeyPrefix$key', value);
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      if (!kIsWeb) rethrow;
    }
    if (kIsWeb) {
      webLocalStorageDelete('$_webKeyPrefix$key');
    }
  }
}
