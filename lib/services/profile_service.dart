import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/exceptions/auth_exception.dart';
import '../models/profile_model.dart';

class ProfileService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ProfileService({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<ProfileModel?> profileStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ProfileModel.fromFirestore(snap);
    });
  }

  Future<ProfileModel?> getProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return ProfileModel.fromFirestore(snap);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    try {
      await _userDoc(profile.uid).set(
        profile.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw AuthException('Failed to save profile. Please try again.');
    }
  }

  Future<String> uploadProfilePhoto(String uid, File file) async {
    try {
      final ref = _storage.ref('profile_photos/$uid.jpg');
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw AuthException('Failed to upload photo. Please try again.');
    }
  }

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _storage.ref('profile_photos/$uid.jpg').delete();
    } catch (_) {
      // Ignore — photo might not exist
    }
  }
}
