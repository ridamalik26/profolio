class ExperienceModel {
  final String id;
  final String role;
  final String company;
  final String duration;
  final String description;

  const ExperienceModel({
    required this.id,
    required this.role,
    required this.company,
    required this.duration,
    required this.description,
  });

  factory ExperienceModel.empty() => ExperienceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: '',
        company: '',
        duration: '',
        description: '',
      );

  factory ExperienceModel.fromMap(Map<String, dynamic> map) => ExperienceModel(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        role: map['role'] as String? ?? '',
        company: map['company'] as String? ?? '',
        duration: map['duration'] as String? ?? '',
        description: map['description'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role,
        'company': company,
        'duration': duration,
        'description': description,
      };

  ExperienceModel copyWith({
    String? id,
    String? role,
    String? company,
    String? duration,
    String? description,
  }) => ExperienceModel(
        id: id ?? this.id,
        role: role ?? this.role,
        company: company ?? this.company,
        duration: duration ?? this.duration,
        description: description ?? this.description,
      );
}
