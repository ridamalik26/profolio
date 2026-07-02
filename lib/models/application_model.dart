enum ApplicationStatus { pending, applied, accepted, rejected }

ApplicationStatus applicationStatusFromString(String raw) {
  return ApplicationStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => ApplicationStatus.pending,
  );
}

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String? jobUrl;
  final String? location;
  final String? jobType;
  final String? salary;
  final int? matchScore;
  final ApplicationStatus status;
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;
  final String? resumeUrl;
  final DateTime appliedAt;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.jobUrl,
    this.location,
    this.jobType,
    this.salary,
    this.matchScore,
    this.status = ApplicationStatus.pending,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
    this.resumeUrl,
    required this.appliedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      jobTitle: map['job_title'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
      jobUrl: map['job_url'] as String?,
      location: map['location'] as String?,
      jobType: map['job_type'] as String?,
      salary: map['salary'] as String?,
      matchScore: (map['match_score'] as num?)?.toInt(),
      status: applicationStatusFromString(map['status'] as String? ?? 'pending'),
      applicantName: map['applicant_name'] as String?,
      applicantEmail: map['applicant_email'] as String?,
      applicantPhone: map['applicant_phone'] as String?,
      resumeUrl: map['resume_url'] as String?,
      appliedAt: DateTime.parse(map['applied_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertMap({required String userId}) => {
        'user_id': userId,
        'job_id': jobId,
        'job_title': jobTitle,
        'company_name': companyName,
        'job_url': jobUrl,
        'location': location,
        'job_type': jobType,
        'salary': salary,
        'match_score': matchScore,
        'status': status.name,
        'applicant_name': applicantName,
        'applicant_email': applicantEmail,
        'applicant_phone': applicantPhone,
        'resume_url': resumeUrl,
      };
}
