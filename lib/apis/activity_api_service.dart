import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klarto/services/api_service.dart';

class ActivityApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getActivities() async {
    try {
      final response = await _apiService.get('/activities');
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
}