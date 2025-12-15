import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klarto/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabelsApiService {
  static const String _baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> createLabel({
    required String name,
    required String color,
    required bool isFavorite,
  }) async {
    final url = Uri.parse('$_baseUrl/labels');
    
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
        'color': color,
        'is_favorite': isFavorite,
      }),
    );

    final responseBody = json.decode(response.body);
    return {'success': response.statusCode == 201, 'data': responseBody, 'message': responseBody['message']};
  }

  Future<Map<String, dynamic>> getLabels() async {
    final url = Uri.parse('$_baseUrl/labels');
    
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

  Future<Map<String, dynamic>> deleteLabel(String id) async {
    final url = Uri.parse('$_baseUrl/labels/$id');
    
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