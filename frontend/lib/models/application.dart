import 'job.dart';
import 'user.dart';

// Extension for dynamic to handle type conversions
extension TypeConversionExtension on dynamic {
  bool? toBool() {
    var value = this;
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  int? toInt() {
    var value = this;
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// Helper function for Map toBool conversion
bool? mapToBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  if (value is num) return value != 0;
  return null;
}

// Helper function for Map toInt conversion
int? mapToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class Application {
  final String id;
  final String jobId;
  final String userId;
  final String coverLetter;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Job? job;
  final User? user;

  // File information
  final String? resumeUrl;
  final String? resumeFileName;
  final int? resumeFileSize;
  final String? resumeFileType;

  // Additional fields for display
  final String? jobTitle;
  final String? companyName;
  final String? applicantName;
  final String? applicantEmail;
  final String? jobDescription;

  // Status history
  final List<Map<String, dynamic>>? statusHistory;
  final bool? fileDeleted;
  final DateTime? fileDeletedAt;

  Application({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.coverLetter,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.job,
    this.user,
    this.resumeUrl,
    this.resumeFileName,
    this.resumeFileSize,
    this.resumeFileType,
    this.jobTitle,
    this.companyName,
    this.applicantName,
    this.applicantEmail,
    this.jobDescription,
    this.statusHistory,
    this.fileDeleted,
    this.fileDeletedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    // Handle userId that might be ObjectId or string
    String userId = '';
    if (json['userId'] is Map) {
      userId = json['userId']['_id'] ?? json['userId'].toString();
    } else {
      userId = json['userId']?.toString() ?? '';
    }

    // Handle jobId that might be ObjectId or string
    String jobId = '';
    if (json['jobId'] is Map) {
      jobId = json['jobId']['_id'] ?? json['jobId'].toString();
    } else {
      jobId = json['jobId']?.toString() ?? '';
    }

    return Application(
      id: json['_id']?.toString() ?? '',
      jobId: jobId,
      userId: userId,
      coverLetter: json['coverLetter']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      job: json['job'] is Map ? Job.fromJson(json['job']) : null,
      user: json['user'] is Map ? User.fromJson(json['user']) : null,
      resumeUrl: json['resumeUrl']?.toString(),
      resumeFileName: json['resumeFileName']?.toString(),
      resumeFileSize: mapToInt(json['resumeFileSize']),
      resumeFileType: json['resumeFileType']?.toString(),
      jobTitle:
          json['jobTitle']?.toString() ?? json['job']?['title']?.toString(),
      companyName: json['companyName']?.toString() ??
          json['job']?['company']?['companyName']?.toString() ??
          json['job']?['companyName']?.toString(),
      applicantName: json['applicantName']?.toString() ??
          (json['user']?['firstName']?.toString() ?? '') +
              ' ' +
              (json['user']?['lastName']?.toString() ?? ''),
      applicantEmail: json['applicantEmail']?.toString() ??
          json['user']?['email']?.toString(),
      jobDescription: json['jobDescription']?.toString() ??
          json['job']?['description']?.toString(),
      statusHistory: json['statusHistory'] is List
          ? List<Map<String, dynamic>>.from(json['statusHistory'])
          : null,
      fileDeleted: mapToBool(json['fileDeleted']),
      fileDeletedAt: json['fileDeletedAt'] != null
          ? DateTime.parse(json['fileDeletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'coverLetter': coverLetter,
    };
  }
}
