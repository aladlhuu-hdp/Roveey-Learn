import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/password_hasher.dart';
import '../models/local_profile.dart';

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  Future<LocalProfile?> currentProfile();
  Future<LocalProfile> register({
    required String name,
    required String email,
    required String password,
  });
  Future<LocalProfile> signIn({
    required String email,
    required String password,
  });
  Future<LocalProfile> updateName(LocalProfile profile, String name);
  Future<void> signOut();
}

class LocalAuthService implements AuthService {
  static const String _accountsKey = AppConstants.accountsKey;
  static const String sessionKey = AppConstants.sessionKey;

  @override
  Future<LocalProfile?> currentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(sessionKey);
    if (email == null) return null;
    final account = _findAccount(prefs.getStringList(_accountsKey) ?? <String>[], email);
    return account == null ? null : _profileFrom(account);
  }

  @override
  Future<LocalProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList(_accountsKey) ?? <String>[];
    if (_findAccount(accounts, email) != null) {
      throw const LocalAuthException('Email ini sudah terdaftar di perangkat. Silakan masuk.');
    }
    final salt = PasswordHasher.generateSalt(16);
    final passwordHash = await PasswordHasher.hashPassword(password: password, salt: salt);
    final createdAt = DateTime.now().toIso8601String();
    final normalizedEmail = email.trim().toLowerCase();
    accounts.add(jsonEncode(<String, String>{
      'name': name.trim(),
      'email': normalizedEmail,
      'createdAt': createdAt,
      'salt': salt,
      'passwordHash': passwordHash,
    }));
    await prefs.setStringList(_accountsKey, accounts);
    await prefs.setString(sessionKey, normalizedEmail);
    return LocalProfile(name: name.trim(), email: normalizedEmail, createdAt: createdAt);
  }

  @override
  Future<LocalProfile> signIn({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final account = _findAccount(prefs.getStringList(_accountsKey) ?? <String>[], email);
    if (account == null) throw const LocalAuthException('Email atau kata sandi tidak cocok.');
    final passwordHash = await PasswordHasher.hashPassword(
      password: password,
      salt: account['salt'] as String,
    );
    if (!PasswordHasher.constantTimeEquals(passwordHash, account['passwordHash'] as String)) {
      throw const LocalAuthException('Email atau kata sandi tidak cocok.');
    }
    final normalizedEmail = (account['email'] as String).toLowerCase();
    await prefs.setString(sessionKey, normalizedEmail);
    return _profileFrom(account);
  }

  @override
  Future<LocalProfile> updateName(LocalProfile profile, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList(_accountsKey) ?? <String>[];
    final index = accounts.indexWhere((record) => _decodeAccount(record)?['email'] == profile.email);
    if (index < 0) throw const LocalAuthException('Profil lokal tidak ditemukan.');
    final account = _decodeAccount(accounts[index])!..['name'] = name.trim();
    accounts[index] = jsonEncode(account);
    await prefs.setStringList(_accountsKey, accounts);
    return _profileFrom(account);
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
  }

  Map<String, dynamic>? _findAccount(List<String> accounts, String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final record in accounts) {
      final account = _decodeAccount(record);
      if (account?['email'] == normalizedEmail) return account;
    }
    return null;
  }

  Map<String, dynamic>? _decodeAccount(String record) {
    try {
      return Map<String, dynamic>.from(jsonDecode(record) as Map);
    } catch (_) {
      return null;
    }
  }

  LocalProfile _profileFrom(Map<String, dynamic> account) => LocalProfile(
        name: account['name'] as String,
        email: account['email'] as String,
        createdAt: account['createdAt'] as String,
      );
}

/// Kept for backward compatibility with existing tests
typedef LocalAccountStore = LocalAuthService;
