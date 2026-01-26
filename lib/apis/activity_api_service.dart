import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klarto/services/api_service.dart';
import 'package:klarto/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        return {'success': false, 'message': 'User ID not found'};
      }

      final response = await _apiService.get('/activities?user_id=$userId');
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Failed to load activities: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error fetching activities: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> logActivity({
    required String activityName,
    required String description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        return {'success': false, 'message': 'User ID not found'};
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/activities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'activity_name': activityName,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Failed to log activity: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error logging activity: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
