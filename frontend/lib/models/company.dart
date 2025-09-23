class Company {
  final String id;
  final String companyName;
  final String description;
  final String? logo;
  final String? website;
  final String? industry;
  final String? location;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.companyName,
    required this.description,
    this.logo,
    this.website,
    this.industry,
    this.location,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'],
      companyName: json['companyName'],
      description: json['description'] ?? '',
      logo: json['logo'],
      website: json['website'],
      industry: json['industry'],
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'description': description,
      'logo': logo,
      'website': website,
      'industry': industry,
      'location': location,
    };
  }
}
