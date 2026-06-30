class EducationModel {
  final String id;
  final String degree;
  final String institution;
  final String year;

  const EducationModel({
    required this.id,
    required this.degree,
    required this.institution,
    required this.year,
  });

  factory EducationModel.empty()  => EducationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        degree: '',
        institution: '',
        year: '',
      );

  factory EducationModel.fromMap(Map<String, dynamic> map) => EducationModel(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        degree: map['degree'] as String? ?? '',
        institution: map['institution'] as String? ?? '',
        year: map['year'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'degree': degree,
        'institution': institution,
        'year': year,
      };

  EducationModel copyWith({
    String? id,
    String? degree,
    String? institution,
    String? year,
  }) => EducationModel(
        id: id ?? this.id,
        degree: degree ?? this.degree,
        institution: institution ?? this.institution,
        year: year ?? this.year,
      );
}
