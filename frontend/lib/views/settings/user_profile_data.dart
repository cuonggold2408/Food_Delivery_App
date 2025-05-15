class UserProfile {
  final String fullName;
  final String bio;
  final String email;
  final String phoneNumber;

  UserProfile({
    required this.fullName,
    required this.bio,
    required this.email,
    required this.phoneNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['name'] ?? 'Unknown',
      bio: json['bio'] ?? '',
      email: json['email'] ?? 'Unknown',
      phoneNumber: json['phone_number'] ?? 'Unknown',
    );
  }
}
