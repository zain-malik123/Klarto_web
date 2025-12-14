import 'package:flutter/material.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/widgets/home/dock_header_and_form.dart';
import 'package:klarto/widgets/home/todo_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(120, 28, 120, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DockHeaderAndForm(),
                  const SizedBox(height: 32),
                  const TodoList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}