import 'package:flutter/material.dart';
import 'package:klarto/widgets/todo_item.dart';

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        TodoItem(
          title: 'Design homepage hero section',
          subtaskCount: '3',
          time: 'Fri 13:00',
          tag: 'Work Todos',
        ),
        SizedBox(height: 12),
        TodoItem(
          title: 'Design homepage hero section',
          subtaskCount: '3',
          time: 'Fri 13:00',
          tag: 'Work Todos',
        ),
        SizedBox(height: 12),
        TodoItem(
          title: 'Design homepage hero section',
          subtaskCount: '3',
          time: 'Fri 13:00',
          tag: 'Work Todos',
        ),
        SizedBox(height: 12),
        TodoItem(
          title: 'Design homepage hero section',
          subtaskCount: '3',
          time: 'Fri 13:00',
          tag: 'Work Todos',
        ),
      ],
    );
  }
}