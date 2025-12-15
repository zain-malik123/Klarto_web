import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klarto/config.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For getting the token

class FiltersApiService {
  static const String _baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> createFilter({
    required String name,
    required String query,
    required String color,
    required bool isFavorite,
    String? description,
  }) async {
    final url = Uri.parse('$_baseUrl/filters');
    
    // In a real app, the token would be stored securely after login.
    // For now, we assume it's in SharedPreferences.
    // TODO: Replace this with a proper token management solution.
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated. Please log in again.'};
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'query': query,
        'color': color,
        'is_favorite': isFavorite,
        'description': description,
      }),
    );

    final responseBody = json.decode(response.body);
    return {'success': response.statusCode == 201, 'data': responseBody, 'message': responseBody['message']};
  }

  Future<Map<String, dynamic>> getFilters() async {
    final url = Uri.parse('$_baseUrl/filters');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated. Please log in again.'};
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseBody = json.decode(response.body);
    return {'success': response.statusCode == 200, 'data': responseBody, 'message': responseBody is Map ? responseBody['message'] : 'Failed to parse response.'};
  }

  Future<Map<String, dynamic>> deleteFilter(String id) async {
    final url = Uri.parse('$_baseUrl/filters/$id');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated. Please log in again.'};
    }

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseBody = json.decode(response.body);
    return {'success': response.statusCode == 200, 'message': responseBody['message']};
  }
}