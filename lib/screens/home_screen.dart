import 'package:flutter/material.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/widgets/home/dock_header_and_form.dart';
import 'package:klarto/widgets/home/todo_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodosApiService _todosApiService = TodosApiService();
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  void _refreshTodos() {
    setState(() {
      _todosFuture = _fetchTodos();
    });
  }

  Future<List<Todo>> _fetchTodos() async {
    final result = await _todosApiService.getTodos();
    if (result['success'] && result['data'] is List) {
      return (result['data'] as List).map((json) => Todo.fromJson(json)).toList();
    }
    // In a real app, you might want to show an error message.
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DockHeaderAndForm(onTodoAdded: _refreshTodos),
          const SizedBox(height: 24),
          FutureBuilder<List<Todo>>(
            future: _todosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No todos yet. Add one above!'));
              }
              final todos = snapshot.data!;
              return TodoList(todos: todos, onTodoChanged: _refreshTodos);
            },
          ),
        ],
      ),
    );
  }
}