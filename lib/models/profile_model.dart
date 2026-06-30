import 'package:cloud_firestore/cloud_firestore.dart';
import 'education_model.dart';
import 'experience_model.dart';
import 'certification_model.dart';

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
  });

  factory ProfileModel.empty({required String uid, required String email}) {
    return ProfileModel(uid: uid, fullName: '', email: email);
  }

  factory ProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data()!;
    return ProfileModel(
      uid: snap.id,
      fullName: d['fullName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phoneNumber: d['phoneNumber'] as String?,
      dateOfBirth: d['dateOfBirth'] as String?,
      address: d['address'] as String?,
      photoURL: d['photoURL'] as String?,
      portfolioURL: d['portfolioURL'] as String?,
      linkedinURL: d['linkedinURL'] as String?,
      education: _parseList(d['education'], EducationModel.fromMap),
      experience: _parseList(d['experience'], ExperienceModel.fromMap),
      certifications: _parseList(d['certifications'], CertificationModel.fromMap),
      skills: _parseStringList(d['skills']),
      languages: _parseStringList(d['languages']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (address != null) 'address': address,
        if (photoURL != null) 'photoURL': photoURL,
        if (portfolioURL != null) 'portfolioURL': portfolioURL,
        if (linkedinURL != null) 'linkedinURL': linkedinURL,
        'education': education.map((e) => e.toMap()).toList(),
        'experience': experience.map((e) => e.toMap()).toList(),
        'certifications': certifications.map((c) => c.toMap()).toList(),
        'skills': skills,
        'languages': languages,
        'updatedAt': FieldValue.serverTimestamp(),
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
    bool clearPhotoURL = false,
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
