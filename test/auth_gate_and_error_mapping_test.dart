import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooveylearn/core/utils/app_error_mapper.dart';
import 'package:rooveylearn/main.dart';
import 'package:rooveylearn/widgets/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'helpers/fake_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppErrorMapper Tests', () {
    test('maps 42501 RLS violation to friendly Indonesian message', () {
      const exception = PostgrestException(
        message: 'new row violates row-level security policy for table simulation_attempts',
        code: '42501',
      );
      final userMessage = AppErrorMapper.toUserMessage(exception);
      expect(userMessage, contains('Akses ditolak'));
    });

    test('maps P0001 sequential module violation to friendly Indonesian message', () {
      const exception = PostgrestException(
        message: 'Alur belajar bertahap: Anda harus menyelesaikan modul sebelumnya (Modul 1) terlebih dahulu.',
        code: 'P0001',
      );
      final userMessage = AppErrorMapper.toUserMessage(exception);
      expect(userMessage, contains('Alur belajar bertahap'));
    });

    test('maps P0001 certificate requirement error to friendly Indonesian message', () {
      const exception = PostgrestException(
        message: 'Syarat belum terpenuhi: Anda baru menyelesaikan 3 dari 5 modul pembelajaran wajib.',
        code: 'P0001',
      );
      final userMessage = AppErrorMapper.toUserMessage(exception);
      expect(userMessage, contains('Syarat belum terpenuhi'));
    });

    test('maps P0003 rate limit to friendly Indonesian message', () {
      const exception = PostgrestException(
        message: 'Batas percobaan tercapai: maksimal 3 percobaan asesmen akhir per 24 jam.',
        code: 'P0003',
      );
      final userMessage = AppErrorMapper.toUserMessage(exception);
      expect(userMessage, contains('Batas percobaan tercapai'));
      expect(userMessage, contains('3 kali dalam 24 jam'));
    });

    test('maps 22023 invalid parameter to friendly Indonesian message', () {
      const exception = PostgrestException(
        message: 'Jenis evaluasi tidak valid',
        code: '22023',
      );
      final userMessage = AppErrorMapper.toUserMessage(exception);
      expect(userMessage, contains('tidak valid'));
    });

    test('maps AuthException to friendly Indonesian message', () {
      const invalidCreds = AuthException('Invalid login credentials');
      expect(AppErrorMapper.toUserMessage(invalidCreds), contains('Email atau kata sandi tidak cocok'));

      const alreadyReg = AuthException('User already registered');
      expect(AppErrorMapper.toUserMessage(alreadyReg), contains('Email ini sudah terdaftar'));

      const shortPass = AuthException('Password should be at least 6 characters');
      expect(AppErrorMapper.toUserMessage(shortPass), contains('minimal terdiri dari 6 karakter'));
    });

    test('maps SocketException and network issues to friendly message', () {
      const socketEx = SocketException('Failed host lookup');
      expect(AppErrorMapper.toUserMessage(socketEx), contains('Periksa koneksi internet'));
    });
  });

  group('AuthGate Widget & Guard Tests', () {
    testWidgets('AuthGate renders child when authenticated', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthGate(
              isAuthenticated: true,
              child: Text('Konten Pengguna Terautentikasi'),
            ),
          ),
        ),
      );

      expect(find.text('Konten Pengguna Terautentikasi'), findsOneWidget);
      expect(find.text('Masuk untuk Menyimpan Progres'), findsNothing);
    });

    testWidgets('AuthGate renders prompt card when user is guest', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthGate(
              isAuthenticated: false,
              featureName: 'Sertifikat',
              child: Text('Konten Pengguna Terautentikasi'),
            ),
          ),
        ),
      );

      expect(find.text('Konten Pengguna Terautentikasi'), findsNothing);
      expect(find.text('Masuk untuk Menyimpan Progres'), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);
    });

    testWidgets('RequireLogin.guard blocks guest and shows login modal', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  RequireLogin.guard(
                    ctx,
                    isAuthenticated: false,
                    featureName: 'Kuis Evaluasi',
                    onAuthenticatedAction: () => actionTriggered = true,
                  );
                },
                child: const Text('Buka Kuis'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Kuis'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isFalse);
      expect(find.text('Masuk untuk Menyimpan Progres'), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
    });

    testWidgets('RequireLogin.guard executes action directly when authenticated', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  RequireLogin.guard(
                    ctx,
                    isAuthenticated: true,
                    featureName: 'Kuis Evaluasi',
                    onAuthenticatedAction: () => actionTriggered = true,
                  );
                },
                child: const Text('Buka Kuis'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Kuis'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
      expect(find.text('Masuk untuk Menyimpan Progres'), findsNothing);
    });
  });

  group('RPC Quiz & Progress Flow Tests with AppController', () {
    test('submitQuiz records score and evaluations from server response', () async {
      final fakeAuth = FakeAuthService(
        initialUser: const UserProfile(
          id: 'user-001',
          name: 'Budi Pesisir',
          email: 'budi@pesisir.org',
          createdAt: '2026-10-18T00:00:00Z',
        ),
      );
      final fakeProgress = FakeProgressService();
      final controller = AppController(
        authService: fakeAuth,
        progressService: fakeProgress,
      );

      await controller.init();
      expect(controller.isAuthenticated, isTrue);

      final result = await controller.submitQuiz(
        quizType: 'final',
        answers: <Map<String, dynamic>>[
          <String, dynamic>{'question_id': 'q1', 'selected_option': 1},
          <String, dynamic>{'question_id': 'q2', 'selected_option': 2},
          <String, dynamic>{'question_id': 'q3', 'selected_option': 0},
          <String, dynamic>{'question_id': 'q4', 'selected_option': 3},
          <String, dynamic>{'question_id': 'q5', 'selected_option': 1},
        ],
      );

      expect(result.score, 100);
      expect(result.isPassed, isTrue);
      expect(controller.quizScore, 100);
    });

    test('completeModule enforces sequential prerequisite check', () async {
      final fakeAuth = FakeAuthService(
        initialUser: const UserProfile(
          id: 'user-001',
          name: 'Budi Pesisir',
          email: 'budi@pesisir.org',
          createdAt: '2026-10-18T00:00:00Z',
        ),
      );
      final fakeProgress = FakeProgressService();
      final controller = AppController(
        authService: fakeAuth,
        progressService: fakeProgress,
      );

      await controller.init();

      // Completing module 1 succeeds
      await controller.completeModule(1);
      expect(controller.completedModules.contains(1), isTrue);

      // Completing module 3 before module 2 fails with prerequisite error
      expect(
        () => controller.completeModule(3),
        throwsA(isA<Exception>()),
      );
    });

    test('simulation result recorded for authenticated user and ignored for guest', () async {
      final fakeAuth = FakeAuthService(); // Guest initially
      final fakeProgress = FakeProgressService();
      final controller = AppController(
        authService: fakeAuth,
        progressService: fakeProgress,
      );

      await controller.init();
      expect(controller.isAuthenticated, isFalse);

      // Guest simulation attempt: NOT recorded
      await controller.recordSimulation(
        simulationType: 'decision_making',
        isSuccess: true,
      );
      expect(fakeProgress.recordedSimulations, isEmpty);

      // Log in
      await controller.activateProfile(
        const UserProfile(
          id: 'user-002',
          name: 'Siti',
          email: 'siti@pesisir.org',
          createdAt: '2026-10-18T00:00:00Z',
        ),
      );
      expect(controller.isAuthenticated, isTrue);

      // Authenticated simulation attempt: recorded
      await controller.recordSimulation(
        simulationType: 'decision_making',
        isSuccess: true,
        score: 100,
      );
      expect(fakeProgress.recordedSimulations.length, 1);
      expect(fakeProgress.recordedSimulations.first['simulation_type'], 'decision_making');
    });
  });
}

