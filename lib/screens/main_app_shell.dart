import 'package:flutter/material.dart';
import 'package:klarto/screens/home_screen.dart';
import 'package:klarto/screens/filters_and_labels_screen.dart';
import 'package:klarto/widgets/home/sidebar.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  // In a real app, this would be managed by a state management solution
  // like Provider or BLoC. For now, we use a simple state variable.
  String _selectedPage = 'dock';

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
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(currentPage: _selectedPage, onPageSelected: _onPageSelected),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}