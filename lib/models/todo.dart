class Todo {
  final String id;
  final String title;
  final String description;
  final String? dueDate;
  final String? dueTime;
  final int? priority;
  final bool isCompleted;
  final String? labelName;
  final String? labelColor;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.dueTime,
    this.priority,
    required this.isCompleted,
    this.labelName,
    this.labelColor,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'],
      dueTime: json['due_time'],
      priority: json['priority'],
      isCompleted: json['is_completed'],
      labelName: json['label_name'],
      labelColor: json['label_color'],
    );
  }
}