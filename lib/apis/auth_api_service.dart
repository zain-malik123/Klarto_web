import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klarto/config.dart';

class AuthApiService {
  // Centralized base URL for the authentication endpoints.
  static const String _authUrl = '${AppConfig.baseUrl}/auth';

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_authUrl/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 201) {
      // 201 Created: Success
      return {
        'success': true,
        'message': responseBody['message'] ?? 'Signup successful!'
      };
    } else {
      // Handle other status codes (e.g., 400 Bad Request, 409 Conflict)
      return {
        'success': false,
        'message': responseBody['message'] ?? 'An unknown error occurred.'
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_authUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      // 200 OK: Success
      return {
        'success': true,
        'token': responseBody['token'],
        'invited': responseBody['invited'] == true,
      };
    } else {
      // Handle other status codes (400, 401, 403, 500)
      return {'success': false, 'message': responseBody['message']};
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final url = Uri.parse('$_authUrl/request-password-reset');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final responseBody = json.decode(response.body);
        return {'success': false, 'message': responseBody['message'] ?? 'An error occurred.'};
      }
    } catch (e) {
      // Network or other client-side error
      return {'success': false, 'message': 'Failed to connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_authUrl/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'newPassword': newPassword}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'An error occurred.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String token,
  }) async {
    final url = Uri.parse('$_authUrl/verify?token=$token');

    try {
      // The server's verify endpoint is a GET request that redirects.
      // We can make a GET request here to trigger the server-side logic.
      // The server will handle the database update.
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Verification failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect to the server.'};
    }
  }
}