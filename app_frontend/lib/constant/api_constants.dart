import 'package:flutter/foundation.dart';

class ApiConstants {
  // Production deployed backend URL on Render
  static const String productionBaseUrl = 'https://library-app-welh.onrender.com';

  // Can be overridden at build time via --dart-define=BACKEND_URL=http://...
  static const String _envBaseUrl = String.fromEnvironment('BACKEND_URL');

  // Manual override for local/custom testing (e.g. "http://10.0.2.2:8000" or "http://127.0.0.1:8000")
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    // Default to the deployed Render backend
    return productionBaseUrl;
  }

  static String get apiV1 => '$baseUrl/api/v1';

  static String bookContentUrl(int bookId) => '$apiV1/books/$bookId/content';
  static String bookPagesUrl(int bookId, {int page = 1, int pageSize = 2500}) =>
      '$apiV1/books/$bookId/pages?page=$page&pageSize=$pageSize';
  static String bookProgressUrl(int bookId) => '$apiV1/books/$bookId/progress';
}
