import 'dart:convert';
import 'package:crypto/crypto.dart';

class LocalProfile {
  const LocalProfile({
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String name;
  final String email;
  final String createdAt;

  String get storageId =>
      sha256.convert(utf8.encode(email.toLowerCase())).toString().substring(0, 16);

  Map<String, dynamic> toMap({String? salt, String? passwordHash}) {
    return <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'createdAt': createdAt,
      if (salt != null) 'salt': salt,
      if (passwordHash != null) 'passwordHash': passwordHash,
    };
  }

  factory LocalProfile.fromMap(Map<String, dynamic> map) {
    return LocalProfile(
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
