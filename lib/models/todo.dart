class Todo {
  String id;
  String title;
  String? description;
  bool isCompleted;
  String? dueDate;
  String? dueTime;
  int? priority;
  String? labelName;
  String? labelColor;
  String? labelId;
  String? projectName;
  String? projectId;

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
    this.labelId,
    this.projectName,
    this.projectId,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?,
      priority: json['priority'] as int?,
      labelName: json['label_name'] as String?,
      labelColor: json['label_color'] as String?,
      labelId: json['label_id'] as String?,
      projectName: json['project_name'] as String?,
      projectId: json['project_id'] as String?,
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