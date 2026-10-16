class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role; // 'user', 'admin', or 'superAdmin'
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isGoogleUser;
  final bool isAppleUser;
  final bool hasPassword;
  final String createdAt;
  final String updatedAt;
  final String? lastLoginAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.role = 'user',
    this.isActive = true,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isGoogleUser = false,
    this.isAppleUser = false,
    this.hasPassword = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, [String? fallbackUid]) {
    final uid = map['id'] ?? map['uid'] ?? map['_id'] ?? fallbackUid ?? '';
    return UserModel(
      uid: uid.toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'user',
      isActive: map['isActive'] ?? true,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isGoogleUser: map['isGoogleUser'] ?? false,
      isAppleUser: map['isAppleUser'] ?? false,
      hasPassword: map['hasPassword'] ?? true,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? map['createdAt'] ?? '',
      lastLoginAt: map['lastLoginAt']?.toString(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isGoogleUser': isGoogleUser,
      'isAppleUser': isAppleUser,
      'hasPassword': hasPassword,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    bool? isActive,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isGoogleUser,
    bool? isAppleUser,
    bool? hasPassword,
    String? createdAt,
    String? updatedAt,
    String? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      isAppleUser: isAppleUser ?? this.isAppleUser,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
