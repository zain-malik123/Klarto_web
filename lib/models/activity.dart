class Activity {
  final int id;
  final String activityName;
  final String? description;
  final DateTime createdAt;
  final String userName;

  Activity({
    required this.id,
    required this.activityName,
    this.description,
    required this.createdAt,
    required this.userName,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      activityName: json['activity_name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String,
    );
  }
}