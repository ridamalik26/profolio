import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/certification_model.dart';
import '../models/education_model.dart';
import '../models/experience_model.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

// ── Service ───────────────────────────────────────────────────────────────────

final profileServiceProvider = Provider<ProfileService>((_) => ProfileService());

// ── Profile fetch ─────────────────────────────────────────────────────────────

final profileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.id;
  if (uid == null) return null;
  return ref.watch(profileServiceProvider).getProfile(uid);
});

// ── Edit state ────────────────────────────────────────────────────────────────

class ProfileEditState {
  final List<EducationModel> education;
  final List<ExperienceModel> experience;
  final List<CertificationModel> certifications;
  final List<String> skills;
  final List<String> languages;
  final XFile? pendingPhoto;
  final String? existingPhotoURL;
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const ProfileEditState({
    this.education = const [],
    this.experience = const [],
    this.certifications = const [],
    this.skills = const [],
    this.languages = const [],
    this.pendingPhoto,
    this.existingPhotoURL,
    this.isLoading = false,
    this.error,
    this.isSaved = false,
  });

  ProfileEditState copyWith({
    List<EducationModel>? education,
    List<ExperienceModel>? experience,
    List<CertificationModel>? certifications,
    List<String>? skills,
    List<String>? languages,
    XFile? pendingPhoto,
    String? existingPhotoURL,
    bool? isLoading,
    String? error,
    bool? isSaved,
    bool clearError = false,
    bool clearPendingPhoto = false,
  }) {
    return ProfileEditState(
      education: education ?? this.education,
      experience: experience ?? this.experience,
      certifications: certifications ?? this.certifications,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      pendingPhoto: clearPendingPhoto ? null : (pendingPhoto ?? this.pendingPhoto),
      existingPhotoURL: existingPhotoURL ?? this.existingPhotoURL,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  ProfileEditNotifier(this._service) : super(const ProfileEditState());

  final ProfileService _service;

  void initFromProfile(ProfileModel profile) {
    state = ProfileEditState(
      education: List.from(profile.education),
      experience: List.from(profile.experience),
      certifications: List.from(profile.certifications),
      skills: List.from(profile.skills),
      languages: List.from(profile.languages),
      existingPhotoURL: profile.photoURL,
    );
  }

  void reset() => state = const ProfileEditState();

  // ── Photo ──────────────────────────────────────────────────────────────────

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file != null) {
        state = state.copyWith(pendingPhoto: file);
      }
    } catch (_) {
      state = state.copyWith(error: 'Could not access photos. Check permissions.');
    }
  }

  void removePhoto() {
    state = state.copyWith(
      clearPendingPhoto: true,
      existingPhotoURL: null,
    );
  }

  // ── Education ──────────────────────────────────────────────────────────────

  void addEducation(EducationModel e) {
    state = state.copyWith(education: [...state.education, e]);
  }

  void updateEducation(EducationModel updated) {
    state = state.copyWith(
      education: state.education
          .map((e) => e.id == updated.id ? updated : e)
          .toList(),
    );
  }

  void removeEducation(String id) {
    state = state.copyWith(
      education: state.education.where((e) => e.id != id).toList(),
    );
  }

  // ── Experience ────────────────────────────────────────────────────────────

  void addExperience(ExperienceModel e) {
    state = state.copyWith(experience: [...state.experience, e]);
  }

  void updateExperience(ExperienceModel updated) {
    state = state.copyWith(
      experience: state.experience
          .map((e) => e.id == updated.id ? updated : e)
          .toList(),
    );
  }

  void removeExperience(String id) {
    state = state.copyWith(
      experience: state.experience.where((e) => e.id != id).toList(),
    );
  }

  // ── Certifications ────────────────────────────────────────────────────────

  void addCertification(CertificationModel c) {
    state = state.copyWith(certifications: [...state.certifications, c]);
  }

  void updateCertification(CertificationModel updated) {
    state = state.copyWith(
      certifications: state.certifications
          .map((c) => c.id == updated.id ? updated : c)
          .toList(),
    );
  }

  void removeCertification(String id) {
    state = state.copyWith(
      certifications: state.certifications.where((c) => c.id != id).toList(),
    );
  }

  // ── Skills & Languages ────────────────────────────────────────────────────

  void setSkills(List<String> skills) => state = state.copyWith(skills: skills);

  void setLanguages(List<String> languages) =>
      state = state.copyWith(languages: languages);

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<bool> save({
    required String uid,
    required String fullName,
    required String email,
    required String? phoneNumber,
    required String? dateOfBirth,
    required String? address,
    required String? portfolioURL,
    required String? linkedinURL,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSaved: false);

    try {
      // Upload photo if a new one was picked
      String? photoURL = state.existingPhotoURL;
      if (state.pendingPhoto != null) {
        photoURL = await _service.uploadProfilePhoto(
          uid,
          File(state.pendingPhoto!.path),
        );
        state = state.copyWith(
          existingPhotoURL: photoURL,
          clearPendingPhoto: true,
        );
      }

      final profile = ProfileModel(
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        address: address,
        photoURL: photoURL,
        portfolioURL: portfolioURL,
        linkedinURL: linkedinURL,
        education: state.education,
        experience: state.experience,
        certifications: state.certifications,
        skills: state.skills,
        languages: state.languages,
      );

      await _service.saveProfile(profile);
      state = state.copyWith(isLoading: false, isSaved: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final profileEditProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
        (ref) {
  return ProfileEditNotifier(ref.watch(profileServiceProvider));
});
