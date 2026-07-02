class SavedJobModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String? jobUrl;
  final String? location;
  final String? jobType;
  final String? salary;
  final int? matchScore;
  final DateTime savedAt;

  const SavedJobModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.jobUrl,
    this.location,
    this.jobType,
    this.salary,
    this.matchScore,
    required this.savedAt,
  });

  factory SavedJobModel.fromMap(Map<String, dynamic> map) {
    return SavedJobModel(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      jobTitle: map['job_title'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
      jobUrl: map['job_url'] as String?,
      location: map['location'] as String?,
      jobType: map['job_type'] as String?,
      salary: map['salary'] as String?,
      matchScore: (map['match_score'] as num?)?.toInt(),
      savedAt: DateTime.parse(map['saved_at'] as String).toLocal(),
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
      };
}
