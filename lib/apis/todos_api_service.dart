import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klarto/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodosApiService {
  static const String _todosUrl = '${AppConfig.baseUrl}/todos';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> createTodo({
    required String title,
    required String description,
    required String projectName,
    required String dueDate,
    required String dueTime,
    required String repeatValue,
    required int priority,
    required String labelId,
  }) async {
    final url = Uri.parse(_todosUrl);
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'title': title,
        'description': description,
        'project_name': projectName,
        'due_date': dueDate,
        'due_time': dueTime,
        'repeat_value': repeatValue,
        'priority': priority,
        'label_id': labelId,
      }),
    );

    final responseBody = json.decode(response.body);
    return {'success': response.statusCode == 201, 'data': responseBody};
  }

  Future<Map<String, dynamic>> getTodos() async {
    final url = Uri.parse(_todosUrl);
    final headers = await _getHeaders();

    final response = await http.get(
      url,
      headers: headers,
    );

    final responseBody = json.decode(response.body);
    return {
      'success': response.statusCode == 200, 'data': responseBody, 'message': responseBody is Map ? responseBody['message'] : null
    };
  }
}