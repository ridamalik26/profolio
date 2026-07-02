import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/exceptions/auth_exception.dart';
import '../models/application_model.dart';
import '../models/saved_job_model.dart';

class ApplicationService {
  final SupabaseClient _client;

  ApplicationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String _applicationsTable = 'applications';
  static const String _savedJobsTable = 'saved_jobs';

  // ── Applications ─────────────────────────────────────────────────────────

  Future<List<ApplicationModel>> getApplications(String uid) async {
    final rows = await _client
        .from(_applicationsTable)
        .select()
        .eq('user_id', uid)
        .order('applied_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => ApplicationModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<bool> hasApplied(String uid, String jobId) async {
    final row = await _client
        .from(_applicationsTable)
        .select('id')
        .eq('user_id', uid)
        .eq('job_id', jobId)
        .maybeSingle();
    return row != null;
  }

  Future<void> submitApplication(ApplicationModel application, String uid) async {
    try {
      await _client
          .from(_applicationsTable)
          .upsert(application.toInsertMap(userId: uid), onConflict: 'user_id,job_id');
    } on PostgrestException catch (e) {
      throw AuthException('Failed to submit application: ${e.message}');
    } catch (e) {
      throw AuthException('Failed to submit application: $e');
    }
  }

  Future<void> updateStatus(String applicationId, ApplicationStatus status) async {
    try {
      await _client
          .from(_applicationsTable)
          .update({'status': status.name}).eq('id', applicationId);
    } catch (e) {
      throw const AuthException('Failed to update application status.');
    }
  }

  // ── Saved jobs ───────────────────────────────────────────────────────────

  Future<List<SavedJobModel>> getSavedJobs(String uid) async {
    final rows = await _client
        .from(_savedJobsTable)
        .select()
        .eq('user_id', uid)
        .order('saved_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => SavedJobModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isSaved(String uid, String jobId) async {
    final row = await _client
        .from(_savedJobsTable)
        .select('id')
        .eq('user_id', uid)
        .eq('job_id', jobId)
        .maybeSingle();
    return row != null;
  }

  Future<void> saveJob(SavedJobModel job, String uid) async {
    try {
      await _client
          .from(_savedJobsTable)
          .upsert(job.toInsertMap(userId: uid), onConflict: 'user_id,job_id');
    } on PostgrestException catch (e) {
      throw AuthException('Failed to save job: ${e.message}');
    } catch (e) {
      throw AuthException('Failed to save job: $e');
    }
  }

  Future<void> unsaveJob(String uid, String jobId) async {
    try {
      await _client
          .from(_savedJobsTable)
          .delete()
          .eq('user_id', uid)
          .eq('job_id', jobId);
    } catch (e) {
      throw const AuthException('Failed to remove saved job.');
    }
  }
}
