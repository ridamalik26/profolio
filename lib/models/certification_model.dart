class CertificationModel {
  final String id;
  final String name;
  final String issuer;
  final String year;

  const CertificationModel({
    required this.id,
    required this.name,
    required this.issuer,
    required this.year,
  });

  factory CertificationModel.empty() => CertificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        issuer: '',
        year: '',
      );

  factory CertificationModel.fromMap(Map<String, dynamic> map) => CertificationModel(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'] as String? ?? '',
        issuer: map['issuer'] as String? ?? '',
        year: map['year'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'issuer': issuer,
        'year': year,
      };

  CertificationModel copyWith({
    String? id,
    String? name,
    String? issuer,
    String? year,
  }) => CertificationModel(
        id: id ?? this.id,
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        year: year ?? this.year,
      );
}
