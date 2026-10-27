import 'package:flutter/foundation.dart';

class ApiConstants {
  // Can be overridden at build time via --dart-define=BACKEND_URL=http://...
  static const String _envBaseUrl = String.fromEnvironment('BACKEND_URL');

  // Manual override for physical device testing (e.g. "http://192.168.1.100:8000")
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator maps 10.0.2.2 to host machine's localhost
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static String get apiV1 => '$baseUrl/api/v1';

  static String bookContentUrl(int bookId) => '$apiV1/books/$bookId/content';
  static String bookPagesUrl(int bookId, {int page = 1, int pageSize = 2500}) =>
      '$apiV1/books/$bookId/pages?page=$page&pageSize=$pageSize';
  static String bookProgressUrl(int bookId) => '$apiV1/books/$bookId/progress';
}
