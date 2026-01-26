import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/widgets/home/todo_list.dart';
import 'package:klarto/widgets/home/toolbar.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.onNeedsRefresh});

  // Callback to allow parent to trigger a refresh
  final VoidCallback onNeedsRefresh;

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  final TodosApiService _todosApiService = TodosApiService();
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _todosFuture = _fetchTodayTodos();
    // This was causing a "setState during build" error.
    // Deferring it until after the first frame prevents the error.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNeedsRefresh());
  }

  void refresh() {
    setState(() {
      _todosFuture = _fetchTodayTodos();
    });
  }
  Future<List<Todo>> _fetchTodayTodos() async {
    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final result = await _todosApiService.getTodos(filter: 'due_today', date: todayString);
    if (result['success'] && result['data'] is List) {
      return (result['data'] as List).map((json) => Todo.fromJson(json)).toList();
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
              const Text('Today', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(
                DateFormat('E, d MMM').format(DateTime.now()),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<List<Todo>>(
            future: _todosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No todos due today.'));
              }
              return TodoList(todos: snapshot.data!, onTodoChanged: refresh);
            },
          ),
        ),
      ],
    );
  }
}