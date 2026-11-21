import '../config/app_config.dart';

bool isMobileOrTabletBrowser() => true;

String currentBrowserUrl() => AppConfig.webAppUrl;

String? webLocalStorageRead(String key) => null;

void webLocalStorageWrite(String key, String value) {}

void webLocalStorageDelete(String key) {}
