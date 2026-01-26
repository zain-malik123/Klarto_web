import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/models/project.dart';
import 'package:klarto/widgets/add_todo_dialog.dart';
import 'package:klarto/widgets/task_modal.dart';
import 'package:intl/intl.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectName;
  final String? projectId;
  final VoidCallback? onDeleted;

  const ProjectDetailsScreen({
    super.key,
    required this.projectName,
    required this.projectId,
    this.onDeleted,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  // Colors from HTML/CSS
  final Color _bgGray = const Color(0xFFF9F9F9);
  final Color _textBlack = const Color(0xFF252525);
  final Color _textGray = const Color(0xFF707070);
  final Color _borderGray = const Color(0xFFF0F0F0);
  final Color _indigoPrimary = const Color(0xFF3D4CD6);
  final Color _red = const Color(0xFFEF4444);
  final Color _green = const Color(0xFF0B8D3B);
  final Color _orange = const Color(0xFFF36E27);

  final TodosApiService _todosApi = TodosApiService();
  List<Todo> _allTodos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currentSort = 'Default';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjectTodos();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectTodos() async {
    setState(() => _isLoading = true);
    final res = await _todosApi.getTodos(projectId: widget.projectId);
    if (res['success'] == true) {
      final List<dynamic> data = res['data'];
      if (mounted) {
        setState(() {
          _allTodos = data.map((item) => Todo.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${widget.projectName}"? All tasks in this project will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteProject();
    }
  }

  Future<void> _deleteProject() async {
    if (widget.projectId == null) return;
    try {
      final res = await UserApiService().deleteProject(widget.projectId!);
      if (res['success'] == true) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted')));
           if (widget.onDeleted != null) {
             widget.onDeleted!();
           }
        }
      }
    } catch (_) {}
  }

  Future<void> _quickAddTask(String? dateStr) async {
    await showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        initialProject: Project(
          id: widget.projectId ?? '',
          name: widget.projectName,
          color: '#3D4CD6',
          accessType: 'private',
          isFavorite: false,
        ),
        initialDate: dateStr,
        onTodoAdded: _loadProjectTodos,
      ),
    );
  }

  void _showSortMenu() async {
    final result = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0), // Close to where sort is usually
      items: [
        const PopupMenuItem(value: 'Default', child: Text('Default')),
        const PopupMenuItem(value: 'Priority', child: Text('Priority')),
        const PopupMenuItem(value: 'Title', child: Text('Title')),
        const PopupMenuItem(value: 'Date', child: Text('Date')),
      ],
    );
    if (result != null) {
      setState(() => _currentSort = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by search
    List<Todo> filtered = _allTodos.where((t) {
      return t.title.toLowerCase().contains(_searchQuery) ||
             (t.description ?? '').toLowerCase().contains(_searchQuery);
    }).toList();

    // Sort
    if (_currentSort == 'Priority') {
      filtered.sort((a, b) => (a.priority ?? 4).compareTo(b.priority ?? 4));
    } else if (_currentSort == 'Title') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_currentSort == 'Date') {
      filtered.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }

    // Separate todos into sections
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    final today = filtered.where((t) => t.dueDate == todayStr).toList();
    final tomorrow = filtered.where((t) => t.dueDate == tomorrowStr).toList();
    final others = filtered.where((t) => t.dueDate != todayStr && t.dueDate != tomorrowStr).toList();

    return Column(
      children: [
        const Toolbar(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
            Row(
              children: [
                // Project Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _indigoPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                   padding: const EdgeInsets.all(6),
                   child: SvgPicture.asset(
                    'assets/icons/project.svg',
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.projectName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: _textBlack,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF707070)),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Project', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Bar removed as per user request

            // Filter Bar
            Row(
              children: [
                // Search
                Container(
                  width: 250,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _borderGray),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icons/search.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(_textGray, BlendMode.srcIn)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            hintStyle: TextStyle(color: _textGray, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterBtn('Sort by: $_currentSort', 'assets/icons/filters.svg', onTap: _showSortMenu),
                const Spacer(),
                _buildFilterBtn('Customize', 'assets/icons/grid.svg', isIconOnly: true),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Today', today.length, onAdd: () => _quickAddTask(todayStr)),
            if (today.isEmpty)
              _buildEmptySection()
            else
              ...today.map((t) => _buildTaskItem(t)),
            
            const SizedBox(height: 32),

            _buildSectionHeader('Tomorrow', tomorrow.length, onAdd: () => _quickAddTask(tomorrowStr)),
            if (tomorrow.isEmpty)
              _buildEmptySection()
            else
              ...tomorrow.map((t) => _buildTaskItem(t)),

            const SizedBox(height: 32),

            _buildSectionHeader('Others', others.length, onAdd: () => _quickAddTask(null)),
            if (others.isEmpty)
              _buildEmptySection()
            else
              ...others.map((t) => _buildTaskItem(t, isOverdue: t.dueDate != null && t.dueDate!.isNotEmpty && t.dueDate!.compareTo(todayStr) < 0)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  ],
);
  }

  Widget _buildEmptySection() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 16),
      child: Text('No tasks scheduled', style: TextStyle(color: _textGray, fontSize: 14, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildTaskItem(Todo todo, {bool isOverdue = false}) {
    Color priorityColor = Colors.transparent;
    if (todo.priority == 1) priorityColor = _red;
    else if (todo.priority == 2) priorityColor = _orange;
    else if (todo.priority == 3) priorityColor = _indigoPrimary;
    else if (todo.priority == 4) priorityColor = _green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () async {
          await showDialog(
            context: context,
            builder: (context) => TaskModal(
              todo: todo,
              onUpdate: _loadProjectTodos,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderGray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () async {
                  await _todosApi.updateTodoCompletion(id: todo.id, isCompleted: !todo.isCompleted);
                  _loadProjectTodos();
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: priorityColor == Colors.transparent ? _borderGray : priorityColor, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: todo.isCompleted ? Icon(Icons.check, size: 14, color: priorityColor) : null,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _textBlack,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // Date
              if (todo.dueDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: isOverdue ? _red : _textGray),
                    const SizedBox(width: 4),
                    Text(
                      todo.dueDate!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? _red : _textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: _borderGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: _textGray),
    );
  }

  Widget _buildSectionHeader(String title, int count, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          if (onAdd != null) ...[
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle_outline, size: 20, color: _indigoPrimary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
          Icon(Icons.keyboard_arrow_down, size: 20, color: _textBlack),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textBlack,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              color: _textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String label, String iconPath, {bool isIconOnly = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderGray),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconPath, width: 14, height: 14, colorFilter: ColorFilter.mode(_textGray, BlendMode.srcIn)),
            if (!isIconOnly) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: _textGray, fontWeight: FontWeight.w500)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String path, Color placeholderColor) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: placeholderColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
