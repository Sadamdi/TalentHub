import 'job.dart';
import 'user.dart';

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

  // Additional fields for display
  final String? jobTitle;
  final String? companyName;
  final String? applicantName;
  final String? applicantEmail;
  final String? jobDescription;

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
    this.jobTitle,
    this.companyName,
    this.applicantName,
    this.applicantEmail,
    this.jobDescription,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['_id'],
      jobId: json['jobId'],
      userId: json['userId'],
      coverLetter: json['coverLetter'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      job: json['job'] is Map ? Job.fromJson(json['job']) : null,
      user: json['user'] is Map ? User.fromJson(json['user']) : null,
      jobTitle: json['jobTitle'] ?? json['job']?['title'],
      companyName: json['companyName'] ?? json['job']?['company'],
      applicantName: json['applicantName'] ??
          (json['user']?['firstName'] ?? '') +
              ' ' +
              (json['user']?['lastName'] ?? ''),
      applicantEmail: json['applicantEmail'] ?? json['user']?['email'],
      jobDescription: json['jobDescription'] ?? json['job']?['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'coverLetter': coverLetter,
    };
  }
}
