import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rooveylearn/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('registers and authenticates without persisting the raw password', () async {
    final store = LocalAccountStore();
    final profile = await store.register(
      name: 'Rani Pesisir',
      email: 'RANI@example.org',
      password: 'mangrove-aman-2026',
    );

    expect(profile.email, 'rani@example.org');
    expect(profile.name, 'Rani Pesisir');
    final prefs = await SharedPreferences.getInstance();
    final record = jsonDecode(prefs.getStringList('local_accounts_v1')!.single) as Map<String, dynamic>;
    expect(record.containsKey('password'), isFalse);
    expect(record['salt'], isNotEmpty);
    expect(record['passwordHash'], isNot('mangrove-aman-2026'));

    await store.signOut();
    expect(await store.currentProfile(), isNull);
    final signedIn = await store.signIn(email: 'rani@example.org', password: 'mangrove-aman-2026');
    expect(signedIn.email, profile.email);
    await expectLater(
      store.signIn(email: 'rani@example.org', password: 'kata-sandi-salah'),
      throwsA(isA<LocalAuthException>()),
    );
  });

  test('rejects duplicate emails regardless of capitalization', () async {
    final store = LocalAccountStore();
    await store.register(name: 'Rani', email: 'rani@example.org', password: 'mangrove-aman-2026');

    await expectLater(
      store.register(name: 'Rani Dua', email: 'RANI@example.org', password: 'mangrove-baru-2026'),
      throwsA(isA<LocalAuthException>()),
    );
  });
}