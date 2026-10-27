import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/api_constants.dart';

class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.isActive = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Reader',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  AuthUser? _currentUser;

  String? get token => _token;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        'X-Device-Id': 'flutter-client',
      };

  /// Login with email and password via backend REST API
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/auth/login');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _token = data['access_token'] as String?;
        if (data['user'] is Map) {
          _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          _currentUser = AuthUser(id: 1, email: email, fullName: 'Reader');
        }
        return _currentUser!;
      } else {
        String msg = 'Login failed (HTTP ${response.statusCode})';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is List) {
              msg = detail
                  .map((e) => e is Map && e['msg'] != null ? e['msg'].toString() : e.toString())
                  .join(', ');
            } else {
              msg = detail.toString();
            }
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      if (e.toString().contains('Failed to connect') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        throw Exception(
          'Cannot connect to backend server at ${ApiConstants.baseUrl}. '
          'Please ensure the FastAPI backend is running.',
        );
      }
      rethrow;
    }
  }

  /// Register a new user account via backend REST API
  Future<AuthUser> register({
    required String email,
    required String password,
    String fullName = 'Reader',
  }) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/auth/register');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'full_name': fullName.trim().isEmpty ? 'Reader' : fullName.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _token = data['access_token'] as String?;
        if (data['user'] is Map) {
          _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          _currentUser = AuthUser(id: 1, email: email, fullName: fullName);
        }
        return _currentUser!;
      } else {
        String msg = 'Registration failed (HTTP ${response.statusCode})';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is List) {
              msg = detail
                  .map((e) => e is Map && e['msg'] != null ? e['msg'].toString() : e.toString())
                  .join(', ');
            } else {
              msg = detail.toString();
            }
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      if (e.toString().contains('Failed to connect') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        throw Exception(
          'Cannot connect to backend server at ${ApiConstants.baseUrl}. '
          'Please ensure the FastAPI backend is running.',
        );
      }
      rethrow;
    }
  }

  /// Logs out the user
  void logout() {
    _token = null;
    _currentUser = null;
  }
}
