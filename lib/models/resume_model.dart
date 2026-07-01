class ResumeModel {
  /// Storage path within the private `resumes` bucket (e.g. "uid/resume.pdf"),
  /// not a directly-usable URL — resolve a signed URL on demand to view/download.
  final String storagePath;
  final String fileName;
  final String uploadDate; // ISO 8601
  final int fileSizeBytes;
  final String contentType;

  const ResumeModel({
    required this.storagePath,
    required this.fileName,
    required this.uploadDate,
    required this.fileSizeBytes,
    required this.contentType,
  });

  factory ResumeModel.fromMap(Map<String, dynamic> map) => ResumeModel(
        storagePath: map['resume_url'] as String? ?? '',
        fileName: map['resume_filename'] as String? ?? 'resume',
        uploadDate: map['resume_uploaded_at'] as String? ?? '',
        fileSizeBytes: (map['resume_file_size_bytes'] as num?)?.toInt() ?? 0,
        contentType: map['resume_content_type'] as String? ?? 'application/pdf',
      );

  // Stored as individual columns on the `users` row (not nested)
  Map<String, dynamic> toMap() => {
        'resume_url': storagePath,
        'resume_filename': fileName,
        'resume_uploaded_at': uploadDate,
        'resume_file_size_bytes': fileSizeBytes,
        'resume_content_type': contentType,
      };

  bool get isPDF => contentType == 'application/pdf';

  String get extension {
    if (fileName.contains('.')) return fileName.split('.').last.toUpperCase();
    return isPDF ? 'PDF' : 'DOCX';
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(uploadDate).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return uploadDate;
    }
  }
}
