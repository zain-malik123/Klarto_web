import 'package:flutter/material.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/widgets/home/todo_list.dart';
import 'package:klarto/widgets/home/toolbar.dart';

class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  final TodosApiService _todosApiService = TodosApiService();
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _todosFuture = _fetchOverdueTodos();
  }

  Future<List<Todo>> _fetchOverdueTodos() async {
    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final result = await _todosApiService.getTodos(filter: 'overdue', date: todayString);
    if (result['success'] && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => Todo.fromJson(json))
          .where((todo) => !todo.isCompleted) // Extra safety check: hide completed todos
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Toolbar(),
        FutureBuilder<List<Todo>>(
          future: _todosFuture,
          builder: (context, snapshot) {
            int todoCount = snapshot.hasData ? snapshot.data!.length : 0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: Row(
                children: [
                  const Text('Overdues', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (snapshot.connectionState == ConnectionState.done)
                    Text('$todoCount Todos', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<List<Todo>>(
            future: _todosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No overdue todos.'));
              }
              return TodoList(todos: snapshot.data!, onTodoChanged: () => setState(() => _todosFuture = _fetchOverdueTodos()));
            },
          ),
        ),
      ],
    );
  }
}