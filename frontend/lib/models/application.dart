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
      job: json['jobId'] is Map ? Job.fromJson(json['jobId']) : null,
      user: json['userId'] is Map ? User.fromJson(json['userId']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'coverLetter': coverLetter,
    };
  }
}
