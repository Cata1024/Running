import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/env_config.dart';
import '../../core/error/app_error.dart';

class ApiException extends AppError {
  final int statusCode;

  ApiException({
    required this.statusCode,
    required super.message,
    super.originalError,
  }) : super(code: 'api-$statusCode');
}

class ApiService {
  ApiService({
    String? baseUrl,
    FirebaseAuth? auth,
    http.Client? client,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(
          baseUrl ?? EnvConfig.instance.backendApiUrl,
        );

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) {
      throw ApiException(statusCode: 500, message: 'BASE_API_URL is not set');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  void dispose() {
    _client.close();
  }

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(statusCode: 401, message: 'User not authenticated');
    }
    final idToken = await user.getIdToken();
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final headers = await _authHeaders();
    final uri = _uri(path, query);
    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw ApiException(statusCode: 500, message: 'Unsupported HTTP method');
      }
    } catch (error) {
      throw ApiException(
        statusCode: 500,
        message: 'Network error: $error',
        originalError: error,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (error) {
        return response.body;
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: response.body.isNotEmpty ? response.body : response.reasonPhrase ?? 'Request failed',
    );
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final result = await _request('GET', '/profile/$uid');
      if (result is Map<String, dynamic>) return result;
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> upsertUserProfile(String uid, Map<String, dynamic> data) async {
    await _request('PUT', '/profile/$uid', body: data);
  }

  Future<void> patchUserProfile(String uid, Map<String, dynamic> data) async {
    await _request('PATCH', '/profile/$uid', body: data);
  }

  Future<Map<String, dynamic>?> fetchTerritory(String uid) async {
    try {
      final result = await _request('GET', '/territory/$uid');
      if (result is Map<String, dynamic>) return result;
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> upsertTerritory(String uid, Map<String, dynamic> data) async {
    await _request('PUT', '/territory/$uid', body: data);
  }

  Future<List<Map<String, dynamic>>> fetchRuns({int limit = 20}) async {
    final result = await _request('GET', '/runs', query: {
      'limit': limit.toString(),
    });
    if (result is List) {
      return result
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>?> fetchRun(String id) async {
    try {
      final result = await _request('GET', '/runs/$id');
      if (result is Map) return Map<String, dynamic>.from(result);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<String> createRun(Map<String, dynamic> data) async {
    final result = await _request('POST', '/runs', body: data);
    if (result is Map && result['id'] != null) {
      return result['id'].toString();
    }
    throw ApiException(statusCode: 500, message: 'Invalid response creating run');
  }

  Future<void> updateRun(String id, Map<String, dynamic> data) async {
    await _request('PATCH', '/runs/$id', body: data);
  }

  Future<void> deleteRun(String id) async {
    await _request('DELETE', '/runs/$id');
  }
}
