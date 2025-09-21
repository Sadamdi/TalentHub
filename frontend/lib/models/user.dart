class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? location;
  final String? phoneNumber;
  final String? profilePicture;
  final DateTime createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.location,
    this.phoneNumber,
    this.profilePicture,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      role: json['role'],
      location: json['location'],
      phoneNumber: json['phoneNumber'],
      profilePicture: json['profilePicture'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'location': location,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
