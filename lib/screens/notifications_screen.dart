import 'package:flutter/material.dart';
import 'package:klarto/widgets/home/toolbar.dart';
import 'package:klarto/apis/todos_api_service.dart';
import 'package:klarto/models/todo.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TodosApiService _todosApi = TodosApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayNotifications();
  }

  Future<void> _loadTodayNotifications() async {
    setState(() => _isLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await _todosApi.getTodos();
    
    if (res['success'] == true && res['data'] is List) {
      final List<dynamic> allTodos = res['data'];
      final List<Map<String, dynamic>> generated = [];
      
      for (final item in allTodos) {
        final todo = Todo.fromJson(item as Map<String, dynamic>);
        if (todo.dueDate == today) {
          generated.add({
            'actor': todo.title,
            'action': 'is due',
            'target': 'Today',
            'time': todo.dueTime ?? 'All day',
            'type': 'timer',
            'read': false,
            'id': todo.id,
          });
        }
      }

      if (mounted) {
        setState(() {
          _notifications = generated;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 0 = All, 1 = Unread, 2 = Read
  int _selectedTab = 0; // default to All

  void _selectTab(int idx) => setState(() => _selectedTab = idx);

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['read'] = true;
      }
      _selectedTab = 2; // switch to Read
    });
  }

  void _toggleReadFor(int index) {
    setState(() {
      _notifications[index]['read'] = !_notifications[index]['read'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Column(
        children: [
          Toolbar(),
          Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    final filtered = _selectedTab == 0
      ? _notifications
      : _selectedTab == 1
        ? _notifications.where((n) => n['read'] == false).toList()
        : _notifications.where((n) => n['read'] == true).toList();

    return Column(
      children: [
        // Reuse the shared Toolbar so the top-right buttons match other pages
        const Toolbar(),
        // Header: title + tabs + "Mark All As Read"
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // All tab
                      GestureDetector(
                        onTap: () => _selectTab(0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.black : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('All', style: TextStyle(color: _selectedTab == 0 ? Colors.white : const Color(0xFF707070), fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Unread tab
                      GestureDetector(
                        onTap: () => _selectTab(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.black : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Unread', style: TextStyle(color: _selectedTab == 1 ? Colors.white : const Color(0xFF707070), fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Read tab
                      GestureDetector(
                        onTap: () => _selectTab(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 2 ? Colors.black : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Read', style: TextStyle(color: _selectedTab == 2 ? Colors.white : const Color(0xFF707070), fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right side control
              Row(
                children: [
                   IconButton(
                    onPressed: _loadTodayNotifications,
                    icon: const Icon(Icons.refresh, color: Color(0xFF3D4CD6), size: 18),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B4AD6).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Mark All As Read', style: TextStyle(color: Color(0xFF3D4CD6), fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        if (filtered.isEmpty) 
          Expanded(child: Center(child: Text('No notifications for today', style: TextStyle(color: Colors.grey[500]))))
        else
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              // map back to original index for toggle
              final item = filtered[i];
              final originalIndex = _notifications.indexOf(item);
              final n = item;
              return InkWell(
                onTap: () => _toggleReadFor(originalIndex),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // larger avatar like the HTML reference
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: n['type'] == 'timer'
                              ? const Icon(Icons.timer, color: Color(0xFF3D4CD6))
                              : const Icon(Icons.person, color: Color(0xFF3D4CD6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // replicate HTML inline bold spans: actor + action + target
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: n['actor'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                TextSpan(text: ' ${n['action']} ', style: const TextStyle(color: Color(0xFF252525))),
                                TextSpan(text: n['target'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            const SizedBox(height: 6),
                            Text(n['time'] ?? '', style: const TextStyle(color: Color(0xFF707070))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 8),
                          // show unread dot only when notification is unread
                          if (n['read'] == false)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D4CD6),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: const Color(0x3D4CD61F)),
                              ),
                            )
                          else
                            const SizedBox(width: 14, height: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
