import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:klarto/models/todo.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/widgets/task_modal.dart';

class TodoList extends StatefulWidget {
  final List<Todo> todos;
  final VoidCallback? onTodoChanged;
  const TodoList({super.key, required this.todos, this.onTodoChanged});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Add horizontal padding to the list itself
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      itemCount: widget.todos.length,
      itemBuilder: (context, index) {
        final todo = widget.todos[index];
        return TodoItem(
          todo: todo, 
          onChanged: widget.onTodoChanged,
          isSelected: _selectedIds.contains(todo.id),
          onSelect: () => _toggleSelection(todo.id),
        );
      },
    );
  }
}

class TodoItem extends StatefulWidget {
  final Todo todo;
  final VoidCallback? onChanged;
  final bool isSelected;
  final VoidCallback onSelect;

  const TodoItem({
    super.key, 
    required this.todo, 
    this.onChanged,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  late bool _isCompleted;
  bool _loading = false;
  final TodosApiService _api = TodosApiService();

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.todo.isCompleted;
  }

  Color _getPriorityColor(int? priority) {
    switch (priority) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFF59E0B);
      case 3: return const Color(0xFF3D4CD6);
      default: return const Color(0xFF9F9F9F);
    }
  }

  Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF707070);
    }
  }

  String _formatDueDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      String formattedString = DateFormat('EEE').format(date); // e.g., "Fri"

      if (widget.todo.dueTime != null) {
        // The dueTime from DB is 'HH:mm:ss'. We parse it to format it nicely.
        final timeParts = widget.todo.dueTime!.split(':');
        if (timeParts.length >= 2) {
          final dummyDate = DateTime(2000, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]));
          // Use intl's locale-aware time formatting (e.g., "1:00 PM")
          final formattedTime = DateFormat.jm().format(dummyDate);
          formattedString += ' $formattedTime';
        }
      }
      return formattedString;
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the task was marked as completed LOCALLY (but was originally incomplete),
    // hide it immediately for the "straight away" vanish effect.
    // If it was already completed when fetched (e.g. in Completed view), show it.
    if (_isCompleted && !widget.todo.isCompleted) return const SizedBox.shrink();

    final priorityColor = _getPriorityColor(widget.todo.priority);

    return GestureDetector(
      onTap: () async {
        final isControlPressed = HardwareKeyboard.instance.isControlPressed;
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

        if (isControlPressed || isShiftPressed) {
          widget.onSelect();
          return;
        }

        await showDialog(
          context: context,
          builder: (context) => TaskModal(
            todo: widget.todo,
            onUpdate: () {
              if (widget.onChanged != null) widget.onChanged!();
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected ? const Color(0xFFF0F2FF) : Colors.white,
          border: Border.all(
            color: widget.isSelected ? const Color(0xFF3D4CD6) : const Color(0xFFF0F0F0),
            width: widget.isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
        children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: _loading ? null : () {
                    final keys = HardwareKeyboard.instance.logicalKeysPressed;
                    final isControlPressed = keys.contains(LogicalKeyboardKey.controlLeft) || keys.contains(LogicalKeyboardKey.controlRight);
                    final isShiftPressed = keys.contains(LogicalKeyboardKey.shiftLeft) || keys.contains(LogicalKeyboardKey.shiftRight);
                    
                    if (isControlPressed || isShiftPressed) {
                      widget.onSelect();
                    } else {
                      _toggleCompleted();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            (_isCompleted || widget.isSelected) ? Icons.check_box : Icons.check_box_outline_blank,
                            color: (_isCompleted || widget.isSelected) ? const Color(0xFF3D4CD6) : priorityColor,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: Text(widget.todo.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                ),
              ],
            ),
            // Meta Info
            Padding(
              padding: const EdgeInsets.only(left: 28.0, top: 12.0),
              child: Row(
                children: [
                  if (widget.todo.dueDate != null)
                    _buildInfoChip(Icons.calendar_today_outlined, _formatDueDate(widget.todo.dueDate)),
                  const SizedBox(width: 12),
                  if (widget.todo.labelName != null)
                    _buildInfoChip(
                      Icons.label, 
                      widget.todo.labelName!,
                      color: widget.todo.labelColor != null ? _hexToColor(widget.todo.labelColor!) : null,
                    ),
                ],
              ),
            )
        ],
      ),
      ),
    );
  }

  Future<void> _toggleCompleted() async {
    // Do not allow unchecking a completed todo; completed state is final.
    if (_isCompleted) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completed todos cannot be reopened.')));
      return;
    }

    setState(() {
      _loading = true;
      _isCompleted = true; // optimistic: marking completed
    });

    final successResp = await _api.updateTodoCompletion(id: widget.todo.id, isCompleted: true);
    if (successResp['success'] == true) {
      setState(() {
        _loading = false;
      });
      // Notify parent to refresh its list (so the change persists across navigations)
      if (widget.onChanged != null) widget.onChanged!();
    } else {
      // revert on failure
      setState(() {
        _isCompleted = false;
        _loading = false;
      });
      final message = successResp['message'] ?? 'Failed to update todo.';
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    final chipColor = color ?? const Color(0xFF707070);
    return Row( // Changed from Container to Row for simpler structure
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: chipColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: chipColor)),
      ],
    );
  }
}