class Project {
  final String id;
  final String name;
  final String color;
  final String accessType;
  final bool isFavorite;

  Project({
    required this.id,
    required this.name,
    required this.color,
    required this.accessType,
    required this.isFavorite,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#000000',
      accessType: json['access_type'] as String? ?? 'private',
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }
}
