import 'company.dart';

class Salary {
  final int amount;
  final String currency;
  final String period;

  Salary({
    required this.amount,
    required this.currency,
    required this.period,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      amount: json['amount'],
      currency: json['currency'] ?? 'USD',
      period: json['period'] ?? 'monthly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'period': period,
    };
  }

  String get formattedSalary {
    if (currency == 'IDR') {
      // Format untuk Rupiah
      final formattedAmount = (amount / 1000000).toStringAsFixed(0);
      return 'Rp $formattedAmount juta/$period';
    } else {
      return '\$$amount/$period';
    }
  }
}

class Job {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final List<String> requirements;
  final List<String> responsibilities;
  final Salary salary;
  final String location;
  final String jobType;
  final String category;
  final String experienceLevel;
  final List<String> skills;
  final List<String> benefits;
  final DateTime? applicationDeadline;
  final bool isActive;
  final int applicationCount;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Company? company;

  Job({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.requirements,
    required this.responsibilities,
    required this.salary,
    required this.location,
    required this.jobType,
    required this.category,
    required this.experienceLevel,
    required this.skills,
    required this.benefits,
    this.applicationDeadline,
    required this.isActive,
    required this.applicationCount,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    this.company,
  });

  bool get isApplicationDeadlinePassed {
    if (applicationDeadline == null) return false;
    return DateTime.now().isAfter(applicationDeadline!);
  }

  String get formattedJobType {
    switch (jobType) {
      case 'full_time':
        return 'Full Time';
      case 'part_time':
        return 'Part Time';
      case 'contract':
        return 'Contract';
      case 'internship':
        return 'Internship';
      case 'freelance':
        return 'Freelance';
      default:
        return jobType;
    }
  }

  String get formattedExperienceLevel {
    switch (experienceLevel) {
      case 'fresh_graduate':
        return 'Fresh Graduate';
      case '1-2_years':
        return '1-2 Years';
      case '3-5_years':
        return '3-5 Years';
      case '5+_years':
        return '5+ Years';
      default:
        return experienceLevel;
    }
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    // Handle companyId yang bisa berupa string atau object
    String companyId;
    Company? company;

    if (json['companyId'] is Map) {
      // Jika companyId adalah object, ambil _id dan parse company
      companyId = json['companyId']['_id'];
      company = Company.fromJson(json['companyId']);
    } else {
      // Jika companyId adalah string
      companyId = json['companyId'].toString();
      company = null;
    }

    return Job(
      id: json['_id'],
      companyId: companyId,
      title: json['title'],
      description: json['description'],
      requirements: List<String>.from(json['requirements'] ?? []),
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      salary: Salary.fromJson(json['salary']),
      location: json['location'],
      jobType: json['jobType'] ?? 'full_time',
      category: json['category'] ?? 'other',
      experienceLevel: json['experienceLevel'] ?? 'fresh_graduate',
      skills: List<String>.from(json['skills'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      applicationDeadline: json['applicationDeadline'] != null
          ? DateTime.parse(json['applicationDeadline'])
          : null,
      isActive: json['isActive'] ?? true,
      applicationCount: json['applicationCount'] ?? 0,
      views: json['views'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      company: company,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'requirements': requirements,
      'responsibilities': responsibilities,
      'salary': salary.toJson(),
      'location': location,
      'jobType': jobType,
      'category': category,
      'experienceLevel': experienceLevel,
      'skills': skills,
      'benefits': benefits,
      'applicationDeadline': applicationDeadline?.toIso8601String(),
    };
  }
}
