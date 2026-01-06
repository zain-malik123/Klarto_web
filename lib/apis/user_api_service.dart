import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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

  Future<Map<String, dynamic>> uploadAvatar({Uint8List? bytes, String? fileName}) async {
    final url = Uri.parse('$_baseUrl/profile/avatar');
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';

    if (bytes == null || bytes.isEmpty) {
      return {'success': false, 'message': 'No image bytes provided.'};
    }

    try {
      final ext = (fileName != null) ? p.extension(fileName).toLowerCase() : '.png';
      String subtype = 'png';
      if (ext == '.jpg' || ext == '.jpeg') subtype = 'jpeg';
      else if (ext == '.gif') subtype = 'gif';
      else if (ext == '.webp') subtype = 'webp';

      final mime = 'image/$subtype';
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$base64Str';

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'avatar_base64': dataUri}),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'],
          'profile_picture_base64': responseBody['profile_picture_base64'],
        };
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to upload avatar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred.'};
    }
  }

  Future<Map<String, dynamic>> inviteTeam(List<String> emails) async {
    final url = Uri.parse('$_baseUrl/team/invite');
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'emails': emails}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'results': body['results']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Failed to invite'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred.'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$_baseUrl/profile');
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';

    try {
      final response = await http.get(url, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'name': body['name'],
          'email': body['email'],
          'profile_picture_base64': body['profile_picture_base64'],
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred.'};
    }
  }

  Future<Map<String, dynamic>> setPasswordForInvite({required String token, required String password}) async {
    final url = Uri.parse('$_baseUrl/team/invite/set-password');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'token': token, 'password': password}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'token': body['token']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Failed to set password for invite'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred.'};
    }
  }
}
