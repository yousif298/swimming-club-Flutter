class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        isActive: json['isActive'] as bool,
      );
}
