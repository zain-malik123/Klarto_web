import 'package:flutter/material.dart';
import 'package:klarto/screens/team_details_screen.dart';
import 'package:klarto/screens/project_details_screen.dart';
import 'package:klarto/screens/filters_and_labels_screen.dart';
import 'package:klarto/screens/notifications_screen.dart';
import 'package:klarto/screens/today_screen.dart';
import 'package:klarto/screens/overdue_screen.dart';
import 'package:klarto/screens/activity_screen.dart';
import 'package:klarto/screens/all_members_screen.dart';
import 'package:klarto/screens/filtered_todos_screen.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/widgets/home/sidebar.dart';
import 'package:klarto/widgets/home/dock_header_and_form.dart';
import 'package:klarto/widgets/home/todo_list.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/apis/todos_api_service.dart';

class MainAppShell extends StatefulWidget {
  final String? initialPage;
  final String? initialFilter;
  final String? initialFilterTitle;
  const MainAppShell({super.key, this.initialPage, this.initialFilter, this.initialFilterTitle});

  @override
  _MainAppShellState createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  late String _selectedPage;
  String? _selectedPageName;
  late Future<List<Todo>> _todosFuture;
  final GlobalKey<SidebarState> _sidebarKey = GlobalKey<SidebarState>();
  // Removed GlobalKey for TodayScreen to avoid duplicate key collisions
  int _overdueCount = 0;
  final TodosApiService _todosApiService = TodosApiService();

  @override
  void initState() {
    super.initState();
    final initFilter = (widget.initialFilter != null && widget.initialFilter!.trim().isNotEmpty) ? widget.initialFilter!.trim() : null;
    _selectedPage = initFilter != null ? 'filter' : (widget.initialPage ?? 'dock');
    _selectedPageName = widget.initialFilterTitle;
    _selectedFilter = initFilter;
    _selectedFilterTitle = widget.initialFilterTitle;
    _refreshTodos();
  }

  String? _selectedFilter;
  String? _selectedFilterTitle;

  void _refreshTodos() {
    setState(() {
      _todosFuture = _fetchTodos();
      // Also refresh sidebar counts/lists
      _sidebarKey.currentState?.refresh();
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

  void _onPageSelected(String pageKey, {String? name}) {
    setState(() {
      _selectedPage = pageKey;
      _selectedPageName = name;
      // Clear any selected filter when switching pages
      _selectedFilter = null;
      _selectedFilterTitle = null;
    });
  }

  Widget _buildCurrentPage() {
    // If a filter was requested, render the filtered todos using the same
    // main-template (toolbar + header + list) by delegating to FilteredTodosScreen.
    if (_selectedFilter != null && _selectedFilter!.isNotEmpty) {
      return FilteredTodosScreen(
        key: ValueKey('filter_$_selectedFilter'),
        title: _selectedFilterTitle ?? _selectedFilter!,
        query: _selectedFilter!
      );
    }
    
    // Handle dynamic team pages
    if (_selectedPage.startsWith('team_')) {
      final teamId = _selectedPage.replaceFirst('team_', '');
      return TeamDetailsScreen(
        key: ValueKey('team_$teamId'), 
        teamName: _selectedPageName ?? teamId,
        onDeleted: () {
          setState(() {
            _selectedPage = 'today';
          });
          _refreshTodos();
        },
      );
    }

    // Handle dynamic project pages
    if (_selectedPage.startsWith('project_')) {
      final projectId = _selectedPage.replaceFirst('project_', '');
      return ProjectDetailsScreen(
        key: ValueKey('project_$projectId'),
        projectName: _selectedPageName ?? 'Project',
        projectId: projectId,
        onDeleted: () {
          setState(() {
            _selectedPage = 'today';
          });
          _refreshTodos();
        },
      );
    }

    switch (_selectedPage) {
      case 'filters_and_labels':
        return const FiltersAndLabelsScreen();
      case 'today':
        return TodayScreen(onNeedsRefresh: _refreshTodos);
      case 'overdue':
        return const OverdueScreen();
      case 'activity':
        return const ActivityScreen();
      case 'notifications':
        return const NotificationsScreen();
      case 'all_members':
        return const AllMembersScreen();
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
                  return TodoList(todos: snapshot.data!, onTodoChanged: _refreshTodos);
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
          Sidebar(
            key: _sidebarKey,
            currentPage: _selectedPage, 
            onPageSelected: _onPageSelected, 
            overdueCount: _overdueCount
          ),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}