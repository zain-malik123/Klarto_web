import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:klarto/models/todo.dart';

class TodoList extends StatelessWidget {
  final List<Todo> todos;
  const TodoList({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Add horizontal padding to the list itself
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        return TodoItem(todo: todos[index]);
      },
    );
  }
}

class TodoItem extends StatelessWidget {
  final Todo todo;
  const TodoItem({super.key, required this.todo});

  Color _getPriorityColor(int? priority) {
    switch (priority) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFF59E0B);
      case 3: return const Color(0xFF3D4CD6);
      default: return const Color(0xFF9F9F9F);
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _formatDueDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(todo.priority);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 2.0, right: 8.0),
            child: Icon(
              todo.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
              color: todo.isCompleted ? const Color(0xFF3D4CD6) : priorityColor,
              size: 20,
            ),
          ),
          // Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(todo.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip(Icons.chat_bubble_outline, '3'),
                    if (todo.dueDate != null)
                      _buildInfoChip(Icons.calendar_today_outlined, 'Due: ${_formatDueDate(todo.dueDate)}'),
                    if (todo.labelName != null)
                      _buildInfoChip(Icons.label_outline, todo.labelName!),
                  ],
                )
              ],
            ),
          ),
          // Priority Flag
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SvgPicture.asset(
              'assets/icons/priority.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(priorityColor, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    final chipColor = color ?? const Color(0xFF707070);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: chipColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: chipColor)),
      ],
    );
  }
}