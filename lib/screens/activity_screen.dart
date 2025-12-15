import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:klarto/apis/activity_api_service.dart';
import 'package:klarto/models/activity.dart';
import 'package:klarto/widgets/home/toolbar.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<List<Activity>> _activityFuture;
  final ActivityApiService _activityApiService = ActivityApiService();

  @override
  void initState() {
    super.initState();
    _activityFuture = _fetchActivities();
  }

  Future<List<Activity>> _fetchActivities() async {
    final result = await _activityApiService.getActivities();
    if (result['success'] && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => Activity.fromJson(json))
          .toList();
    }
    return [];
  }

  Map<String, List<Activity>> _groupActivitiesByDay(List<Activity> activities) {
    final Map<String, List<Activity>> grouped = {};
    for (var activity in activities) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final activityDate = DateTime(activity.createdAt.year, activity.createdAt.month, activity.createdAt.day);

      String dayKey;
      if (activityDate == today) {
        dayKey = 'Today - ${DateFormat('d MMM').format(activity.createdAt)}';
      } else if (activityDate == yesterday) {
        dayKey = 'Yesterday - ${DateFormat('d MMM').format(activity.createdAt)}';
      } else {
        dayKey = DateFormat('E, d MMM').format(activity.createdAt);
      }
      if (grouped[dayKey] == null) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(activity);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Toolbar(),
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Row(
            children: [
              Text('Activity',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<List<Activity>>(
            future: _activityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text('No activities yet.'));
              }

              final groupedActivities = _groupActivitiesByDay(snapshot.data!);
              final dayKeys = groupedActivities.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: dayKeys.length,
                itemBuilder: (context, index) {
                  final day = dayKeys[index];
                  final activitiesForDay = groupedActivities[day]!;
                  return _buildDaySection(day, activitiesForDay);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDaySection(String day, List<Activity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(day,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF383838))),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ...activities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('HH:mm').format(timestamp);
    }
  }

  Widget _buildActivityCard(Activity activity) {
    // Parse the description to separate the main action from the detail.
    // e.g., "User added a new todo: \"My new todo\""
    String mainAction = activity.description ?? activity.activityName;
    String? detail;
    if (activity.description?.contains(':') ?? false) {
      final parts = activity.description!.split(':');
      mainAction = parts.first.trim();
      if (parts.length > 1) {
        detail = parts.sublist(1).join(':').trim().replaceAll('"', '');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Assuming a static avatar for now
          Image.asset('assets/images/avatar.png', width: 36, height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF707070), fontFamily: 'Inter'),
                    children: [
                      TextSpan(text: '${activity.userName} ', style: const TextStyle(color: Color(0xFF383838), fontWeight: FontWeight.w500)),
                      TextSpan(text: mainAction.toLowerCase()),
                      if (detail != null)
                        TextSpan(text: ' - $detail', style: const TextStyle(color: Color(0xFF383838), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // This part is static from the design as the data is not in the DB
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED7FDE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: Color(0xFFED7FDE)),
                          SizedBox(width: 4),
                          Text("Ashar's Team", style: TextStyle(fontSize: 11, color: Color(0xFF707070))),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTimestamp(activity.createdAt),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9F9F9F)),
          ),
        ],
      ),
    );
  }
}