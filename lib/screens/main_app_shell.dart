import 'package:flutter/material.dart';
import 'package:klarto/screens/filters_and_labels_screen.dart';
import 'package:klarto/screens/today_screen.dart';
import 'package:klarto/screens/overdue_screen.dart';
import 'package:klarto/screens/activity_screen.dart';
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
  final GlobalKey<TodayScreenState> _todayScreenKey = GlobalKey<TodayScreenState>();
  int _overdueCount = 0;
  final TodosApiService _todosApiService = TodosApiService();

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  void _refreshTodos() {
    setState(() {
      _todosFuture = _fetchTodos();
      // Also refresh the Today screen if it's visible or might become visible
      // The ?. operator safely handles cases where the key is not yet attached to a widget.
      _todayScreenKey.currentState?.refresh();
    });
  }

  Future<List<Todo>> _fetchTodos() async {
    final result = await _todosApiService.getTodos();
    if (result['success'] && result['data'] is List) {
      final todos = (result['data'] as List).map((json) => Todo.fromJson(json)).toList();
      _updateOverdueCount(todos);
      return todos;
    }
    _updateOverdueCount([]);
    return [];
  }

  void _updateOverdueCount(List<Todo> todos) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final count = todos.where((todo) {
      if (todo.dueDate == null) return false;
      try {
        final dueDate = DateTime.parse(todo.dueDate!);
        return !todo.isCompleted && dueDate.isBefore(todayMidnight);
      } catch (e) {
        return false;
      }
    }).length;
    if (mounted && count != _overdueCount) {
      setState(() => _overdueCount = count);
    }
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
      case 'today':
        return TodayScreen(key: _todayScreenKey, onNeedsRefresh: _refreshTodos);
      case 'overdue':
        return const OverdueScreen();
      case 'activity':
        return const ActivityScreen();
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
          Sidebar(currentPage: _selectedPage, onPageSelected: _onPageSelected, overdueCount: _overdueCount),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}