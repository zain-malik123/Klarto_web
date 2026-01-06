import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/config.dart';
import 'package:path/path.dart' as p;

class UserApiService {
  static const String _baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> updateProfile({required String name}) async {
    final url = Uri.parse('$_baseUrl/profile');
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({'name': name}),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred.'};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final url = Uri.parse('$_baseUrl/profile/avatar');
    final headers = await _getHeaders();

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      final file = await http.MultipartFile.fromPath(
        'avatar',
        filePath,
        contentType: MediaType('image', p.extension(filePath).replaceAll('.', '')),
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'],
          'profile_picture_url': responseBody['profile_picture_url'],
        };
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to upload avatar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred.'};
    }
  }
}
