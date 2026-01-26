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
    required String projectId,
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
        'project_id': projectId,
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

  Future<Map<String, dynamic>> getTodos({String? filter, String? date, String? projectId}) async {
    final params = <String, String>{};
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (projectId != null && projectId.isNotEmpty) params['project_id'] = projectId;
    final uri = params.isNotEmpty ? Uri.parse('$_todosUrl').replace(queryParameters: params) : Uri.parse(_todosUrl);
    final headers = await _getHeaders();

    final response = await http.get(
      uri,
      headers: headers,
    );

    final responseBody = json.decode(response.body);
    return {
      'success': response.statusCode == 200, 'data': responseBody, 'message': responseBody is Map ? responseBody['message'] : null
    };
  }

  Future<Map<String, dynamic>> updateTodo({
    required String id,
    String? title,
    String? description,
    bool? isCompleted,
    String? dueDate,
    String? dueTime,
    int? priority,
    String? labelId,
    String? projectName,
    String? projectId,
  }) async {
    final uri = Uri.parse('$_todosUrl/$id');
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (isCompleted != null) body['is_completed'] = isCompleted;
    if (dueDate != null) body['due_date'] = dueDate;
    if (dueTime != null) body['due_time'] = dueTime;
    if (priority != null) body['priority'] = priority;
    if (labelId != null) body['label_id'] = labelId;
    if (projectName != null) body['project_name'] = projectName;
    if (projectId != null) body['project_id'] = projectId;

    final response = await http.patch(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    final responseBody = response.body.isNotEmpty ? json.decode(response.body) : null;
    return {'success': response.statusCode == 200, 'data': responseBody, 'message': responseBody is Map ? responseBody['message'] : null};
  }

  Future<Map<String, dynamic>> updateTodoCompletion({required String id, required bool isCompleted}) async {
    return updateTodo(id: id, isCompleted: isCompleted);
  }

  Future<Map<String, dynamic>> addComment({required String todoId, required String text}) async {
    final uri = Uri.parse('$_todosUrl/comments');
    final headers = await _getHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'todo_id': todoId, 'text': text}),
    );
    return {'success': response.statusCode == 200};
  }

  Future<Map<String, dynamic>> getComments(String todoId) async {
    final uri = Uri.parse('$_todosUrl/$todoId/comments');
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);
    final body = json.decode(response.body);
    return {'success': response.statusCode == 200, 'data': body};
  }

  Future<Map<String, dynamic>> addSubTodo({
    required String todoId,
    required String title,
    String? description,
    String? dueDate,
    String? dueTime,
    int? priority,
    String? labelId,
  }) async {
    final uri = Uri.parse('$_todosUrl/sub-todos');
    final headers = await _getHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'todo_id': todoId,
        'title': title,
        'description': description,
        'due_date': dueDate,
        'due_time': dueTime,
        'priority': priority,
        'label_id': labelId,
      }),
    );
    return {'success': response.statusCode == 200};
  }

  Future<Map<String, dynamic>> getSubTodos(String todoId) async {
    final uri = Uri.parse('$_todosUrl/$todoId/sub-todos');
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);
    final body = json.decode(response.body);
    return {'success': response.statusCode == 200, 'data': body};
  }

  Future<Map<String, dynamic>> toggleSubTodoCompletion({required String id, required bool isCompleted}) async {
    final uri = Uri.parse('$_todosUrl/sub-todos/$id/toggle');
    final headers = await _getHeaders();
    final response = await http.patch(
      uri,
      headers: headers,
      body: json.encode({'is_completed': isCompleted}),
    );
    return {'success': response.statusCode == 200};
  }
}