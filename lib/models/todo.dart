class Todo {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String? dueDate;
  final String? dueTime;
  final int? priority;
  final String? labelName;
  final String? labelColor;
  final String? projectName;

  Todo({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    this.dueDate,
    this.dueTime,
    this.priority,
    this.labelName,
    this.labelColor,
    this.projectName,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool,
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?, // This was the missing piece
      priority: json['priority'] as int?,
      labelName: json['label_name'] as String?,
      labelColor: json['label_color'] as String?,
      projectName: json['project_name'] as String?,
    );
  }

  Todo copyWith({
    bool? isCompleted,
  }) {
    return Todo(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      // copy other fields
    );
  }
}