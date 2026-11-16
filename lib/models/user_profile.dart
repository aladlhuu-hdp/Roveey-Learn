class UserProfile {
  const UserProfile({
    this.id = '',
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String createdAt;

  String get storageId => id.isNotEmpty ? id : email.trim().toLowerCase();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'createdAt': createdAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? map['created_at']?.toString() ?? '',
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

typedef LocalProfile = UserProfile;

