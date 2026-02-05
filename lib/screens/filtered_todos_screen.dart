import 'package:flutter/material.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/widgets/home/todo_list.dart';
import 'package:klarto/widgets/home/toolbar.dart';

class FilteredTodosScreen extends StatefulWidget {
  final String title;
  final String query; // the filter query string

  const FilteredTodosScreen({super.key, required this.title, required this.query});

  @override
  State<FilteredTodosScreen> createState() => _FilteredTodosScreenState();
}

class _FilteredTodosScreenState extends State<FilteredTodosScreen> {
  final TodosApiService _todosApiService = TodosApiService();
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _todosFuture = _fetchFilteredTodos();
  }

  Future<List<Todo>> _fetchFilteredTodos() async {
    // The filter `query` may correspond to server-side filter keys like
    // 'due_today', 'overdue', 'this_week', 'high_priority', etc.
    // For date-sensitive filters, send the client's local date so the server
    // computes day/week boundaries using the device date rather than server date.
    final dateSensitive = {'due_today', 'today', 'overdue', 'this_week'};
    String? dateParam;
    if (dateSensitive.contains(widget.query.toLowerCase())) {
      final now = DateTime.now();
      dateParam = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }
    final result = await _todosApiService.getTodos(filter: widget.query, date: dateParam);
    if (result['success'] && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => Todo.fromJson(json))
          .where((todo) => widget.query == 'completed' ? todo.isCompleted : !todo.isCompleted)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Toolbar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Row(
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<List<Todo>>(
            future: _todosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No todos for "${widget.title}".'));
              return TodoList(todos: snapshot.data!, onTodoChanged: () => setState(() => _todosFuture = _fetchFilteredTodos()));
            },
          ),
        ),
      ],
    );
  }
}
