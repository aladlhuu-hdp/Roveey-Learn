import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

abstract interface class AuthService {
  Future<UserProfile?> currentProfile();
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  });
  Future<UserProfile> signIn({
    required String email,
    required String password,
  });
  Future<UserProfile> updateName(UserProfile profile, String name);
  Future<void> signOut();
  Stream<UserProfile?> authStateChanges();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService([SupabaseClient? client]) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<UserProfile?> currentProfile() async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser ?? session?.user;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select('id, name, email, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserProfile(
          id: data['id']?.toString() ?? user.id,
          name: data['name']?.toString() ?? user.userMetadata?['name']?.toString() ?? '',
          email: data['email']?.toString() ?? user.email ?? '',
          createdAt: data['created_at']?.toString() ?? user.createdAt,
        );
      }
    } catch (_) {
      // Fallback to auth metadata if network or profile query fails
    }

    final metaName = user.userMetadata?['name']?.toString();
    final fallbackName = (metaName != null && metaName.isNotEmpty)
        ? metaName
        : (user.email?.split('@').first ?? 'Pengguna');

    return UserProfile(
      id: user.id,
      name: fallbackName,
      email: user.email ?? '',
      createdAt: user.createdAt,
    );
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();

    final response = await _client.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: <String, dynamic>{'name': trimmedName},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Pendaftaran gagal. Pengguna tidak terbuat.');
    }

    return UserProfile(
      id: user.id,
      name: trimmedName,
      email: trimmedEmail,
      createdAt: user.createdAt,
    );
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final response = await _client.auth.signInWithPassword(
      email: trimmedEmail,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Autentikasi gagal.');
    }

    try {
      final data = await _client
          .from('profiles')
          .select('id, name, email, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserProfile(
          id: data['id']?.toString() ?? user.id,
          name: data['name']?.toString() ?? user.userMetadata?['name']?.toString() ?? '',
          email: data['email']?.toString() ?? trimmedEmail,
          createdAt: data['created_at']?.toString() ?? user.createdAt,
        );
      }
    } catch (_) {
      // Ignore profile fetch failure and fallback to user metadata
    }

    final metaName = user.userMetadata?['name']?.toString();
    final fallbackName = (metaName != null && metaName.isNotEmpty)
        ? metaName
        : trimmedEmail.split('@').first;

    return UserProfile(
      id: user.id,
      name: fallbackName,
      email: trimmedEmail,
      createdAt: user.createdAt,
    );
  }

  @override
  Future<UserProfile> updateName(UserProfile profile, String name) async {
    final trimmedName = name.trim();
    await _client
        .from('profiles')
        .update(<String, dynamic>{'name': trimmedName})
        .eq('id', profile.id);

    try {
      await _client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{'name': trimmedName}),
      );
    } catch (_) {
      // Non-fatal if metadata update fails
    }

    return profile.copyWith(name: trimmedName);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Stream<UserProfile?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return currentProfile();
    });
  }
}
