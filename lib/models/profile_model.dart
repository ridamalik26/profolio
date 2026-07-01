import 'certification_model.dart';
import 'education_model.dart';
import 'experience_model.dart';
import 'resume_model.dart';

class ProfileModel {
  final String uid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? address;
  final String? photoURL;
  final String? portfolioURL;
  final String? linkedinURL;
  final List<EducationModel> education;
  final List<ExperienceModel> experience;
  final List<String> skills;
  final List<String> languages;
  final List<CertificationModel> certifications;

  // Resume metadata (managed separately by ProfileService)
  final ResumeModel? resume;

  const ProfileModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.address,
    this.photoURL,
    this.portfolioURL,
    this.linkedinURL,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.resume,
  });

  factory ProfileModel.empty({required String uid, required String email}) {
    return ProfileModel(uid: uid, fullName: '', email: email);
  }

  /// [dateOfBirth] is stored as an ISO "yyyy-MM-dd" string (Postgres `date`
  /// column); this renders it as "dd/MM/yyyy" for display.
  String? get formattedDateOfBirth {
    final dob = dateOfBirth;
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('-');
    if (parts.length != 3) return dob;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  factory ProfileModel.fromMap(Map<String, dynamic> d) {
    return ProfileModel(
      uid: d['id'] as String,
      fullName: d['full_name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phoneNumber: d['phone'] as String?,
      dateOfBirth: d['date_of_birth'] as String?,
      address: d['address'] as String?,
      photoURL: d['avatar_url'] as String?,
      portfolioURL: d['portfolio_url'] as String?,
      linkedinURL: d['linkedin_url'] as String?,
      education: _parseList(d['education'], EducationModel.fromMap),
      experience: _parseList(d['experience'], ExperienceModel.fromMap),
      certifications: _parseList(d['certifications'], CertificationModel.fromMap),
      skills: _parseStringList(d['skills']),
      languages: _parseStringList(d['languages']),
      resume: d['resume_url'] != null ? ResumeModel.fromMap(d) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': uid,
        'full_name': fullName,
        'email': email,
        'phone': phoneNumber,
        'date_of_birth': dateOfBirth,
        'address': address,
        'avatar_url': photoURL,
        'portfolio_url': portfolioURL,
        'linkedin_url': linkedinURL,
        'education': education.map((e) => e.toMap()).toList(),
        'experience': experience.map((e) => e.toMap()).toList(),
        'certifications': certifications.map((c) => c.toMap()).toList(),
        'skills': skills,
        'languages': languages,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  ProfileModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? address,
    String? photoURL,
    String? portfolioURL,
    String? linkedinURL,
    List<EducationModel>? education,
    List<ExperienceModel>? experience,
    List<String>? skills,
    List<String>? languages,
    List<CertificationModel>? certifications,
    ResumeModel? resume,
    bool clearPhotoURL = false,
    bool clearResume = false,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      photoURL: clearPhotoURL ? null : (photoURL ?? this.photoURL),
      portfolioURL: portfolioURL ?? this.portfolioURL,
      linkedinURL: linkedinURL ?? this.linkedinURL,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      resume: clearResume ? null : (resume ?? this.resume),
    );
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) => e.toString()).toList();
  }
}
