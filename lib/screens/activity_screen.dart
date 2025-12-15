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
      final dayKey = DateFormat('E, d MMM').format(activity.createdAt);
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

  Widget _buildActivityCard(Activity activity) {
    // This part is a direct translation of your activity.html design
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assuming a static avatar for now
          Image.asset('assets/images/avatar.png', width: 36, height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF707070), fontFamily: 'Inter'),
                    children: [
                      TextSpan(text: 'You ', style: const TextStyle(color: Color(0xFF383838))),
                      TextSpan(text: activity.description),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(activity.createdAt),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9F9F9F)),
          ),
        ],
      ),
    );
  }
}