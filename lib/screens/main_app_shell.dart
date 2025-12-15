import 'package:flutter/material.dart';
import 'package:klarto/screens/filters_and_labels_screen.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/widgets/home/sidebar.dart';
import 'package:klarto/widgets/home/dock_header_and_form.dart';
import 'package:klarto/widgets/home/todo_list.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/apis/todos_api_service.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  _MainAppShellState createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  String _selectedPage = 'dock';
  late Future<List<Todo>> _todosFuture;
  final TodosApiService _todosApiService = TodosApiService();

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
    return [];
  }

  void _onPageSelected(String pageKey) {
    setState(() {
      _selectedPage = pageKey;
    });
  }

  Widget _buildCurrentPage() {
    switch (_selectedPage) {
      case 'filters_and_labels':
        return const FiltersAndLabelsScreen();
      case 'dock':
      default:
        // The main content for the home screen.
        return Column(
          children: [
            const Toolbar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: DockHeaderAndForm(onTodoAdded: _refreshTodos),
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
                    return const Center(child: Text('No todos yet. Add one above!'));
                  }
                  return TodoList(todos: snapshot.data!);
                },
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Row(
        children: [
          Sidebar(currentPage: _selectedPage, onPageSelected: _onPageSelected),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}