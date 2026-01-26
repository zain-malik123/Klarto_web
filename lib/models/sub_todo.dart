class SubTodo {
  final String id;
  final String todoId;
  final String title;
  final String? description;
  bool isCompleted;
  final String? dueDate;
  final String? dueTime;
  final int? priority;
  final String? labelId;
  final String? labelName;
  final String? labelColor;
  final String? createdAt;

  SubTodo({
    required this.id,
    required this.todoId,
    required this.title,
    this.description,
    required this.isCompleted,
    this.dueDate,
    this.dueTime,
    this.priority,
    this.labelId,
    this.labelName,
    this.labelColor,
    this.createdAt,
  });

  factory SubTodo.fromJson(Map<String, dynamic> json) {
    String? _toString(dynamic val) {
      if (val == null) return null;
      if (val is List && val.isNotEmpty) return val.first.toString();
      return val.toString();
    }

    return SubTodo(
      id: _toString(json['id']) ?? '',
      todoId: _toString(json['todo_id']) ?? '',
      title: _toString(json['title']) ?? '',
      description: _toString(json['description']),
      isCompleted: json['is_completed'] == true,
      dueDate: _toString(json['due_date']),
      dueTime: _toString(json['due_time']),
      priority: json['priority'] is int ? json['priority'] : int.tryParse(json['priority']?.toString() ?? ''),
      labelId: _toString(json['label_id']),
      labelName: _toString(json['label_name']),
      labelColor: _toString(json['label_color']),
      createdAt: _toString(json['created_at']),
    );
  }
}
