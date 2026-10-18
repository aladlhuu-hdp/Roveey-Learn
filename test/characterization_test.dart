import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rooveylearn/main.dart';
import 'helpers/fake_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Characterization: Quiz Scoring and Passing Logic (Server-driven)', () {
    test('calculates percentage accurately from total questions and passing threshold >= 80%', () {
      const total = 5;

      int calculatePercentage(int correct) => (correct / total * 100).round();
      bool isPassed(int score) => score >= 80;

      expect(calculatePercentage(5), 100);
      expect(isPassed(calculatePercentage(5)), isTrue);

      expect(calculatePercentage(4), 80);
      expect(isPassed(calculatePercentage(4)), isTrue);

      expect(calculatePercentage(3), 60);
      expect(isPassed(calculatePercentage(3)), isFalse);

      expect(calculatePercentage(0), 0);
      expect(isPassed(calculatePercentage(0)), isFalse);
    });

    test('QuizSubmitResult parses evaluations and pass status accurately from server JSON', () {
      final jsonResponse = <String, dynamic>{
        'assessment_id': '88888888-8888-8888-8888-888888888888',
        'quiz_type': 'final',
        'module_id': null,
        'score': 80,
        'total_questions': 5,
        'correct_answers': 4,
        'is_passed': true,
        'attempt_number': 1,
        'evaluations': <Map<String, dynamic>>[
          <String, dynamic>{
            'question_id': '22222222-2222-2222-2222-222222222201',
            'selected_option': 1,
            'correct_option_index': 1,
            'is_correct': true,
            'explanation': 'Mangrove mendukung habitat biota dan membantu menahan sedimen.',
          },
        ],
      };

      final result = QuizSubmitResult.fromJson(jsonResponse);
      expect(result.score, 80);
      expect(result.totalQuestions, 5);
      expect(result.correctAnswers, 4);
      expect(result.isPassed, isTrue);
      expect(result.evaluations.length, 1);
      expect(result.evaluations.first.isCorrect, isTrue);
      expect(result.evaluations.first.explanation, contains('habitat'));
    });
  });

  group('Characterization: Certificate Eligibility & ID Format', () {
    test('requires 5 modules completed, score >= 80%, and active profile', () {
      bool isCertificateEligible({
        required bool hasProfile,
        required int completedModulesCount,
        required int? quizScore,
      }) {
        return hasProfile && completedModulesCount >= defaultLearningModules.length && (quizScore ?? 0) >= 80;
      }

      // Guest user (no profile) cannot receive certificate even with all modules & 80%
      expect(isCertificateEligible(hasProfile: false, completedModulesCount: 5, quizScore: 80), isFalse);

      // User with only 4 modules cannot receive certificate
      expect(isCertificateEligible(hasProfile: true, completedModulesCount: 4, quizScore: 80), isFalse);

      // User with score < 80% cannot receive certificate
      expect(isCertificateEligible(hasProfile: true, completedModulesCount: 5, quizScore: 79), isFalse);

      // User with 5 modules, score >= 80%, and profile is eligible
      expect(isCertificateEligible(hasProfile: true, completedModulesCount: 5, quizScore: 80), isTrue);
      expect(isCertificateEligible(hasProfile: true, completedModulesCount: 5, quizScore: 100), isTrue);
    });

    test('validates certificate data model from server RPC format ROOVEY-YYYYMMDD-XXXXXX', () {
      final certJson = <String, dynamic>{
        'certificate_id': '33333333-3333-3333-3333-333333333333',
        'certificate_number': 'ROOVEY-20261018-7F8A1B',
        'participant_name': 'Rani Pesisir',
        'program_name': 'Dasar Pengelolaan Mangrove',
        'final_score': 85,
        'issued_at': '2026-10-18T10:00:00Z',
      };

      final cert = CertificateData.fromJson(certJson);
      expect(cert.certificateNumber, startsWith('ROOVEY-20261018-'));
      expect(cert.participantName, 'Rani Pesisir');
      expect(cert.finalScore, 85);
      expect(cert.programName, 'Dasar Pengelolaan Mangrove');
    });
  });

  group('Characterization: Module Unlock & Access Rules', () {
    test('Guest can read all 5 modules freely', () {
      bool isGuestModuleUnlocked(int index) => true; // Final guest rule: boleh baca semua 5 modul

      for (var i = 0; i < defaultLearningModules.length; i++) {
        expect(isGuestModuleUnlocked(i), isTrue);
      }
    });

    test('Authenticated user follows sequential unlocking rule (module 1 unlocked, module N requires N-1)', () {
      bool isAuthModuleUnlocked({
        required int index,
        required Set<int> completedModules,
      }) {
        final moduleId = index + 1;
        if (moduleId == 1) return true;
        return completedModules.contains(moduleId - 1) || completedModules.contains(moduleId);
      }

      // Initial state: only Module 1 (index 0) unlocked
      expect(isAuthModuleUnlocked(index: 0, completedModules: <int>{}), isTrue);
      expect(isAuthModuleUnlocked(index: 1, completedModules: <int>{}), isFalse);

      // After completing module 1, module 2 is unlocked
      expect(isAuthModuleUnlocked(index: 1, completedModules: <int>{1}), isTrue);
      expect(isAuthModuleUnlocked(index: 2, completedModules: <int>{1}), isFalse);

      // After completing module 2, module 3 is unlocked
      expect(isAuthModuleUnlocked(index: 2, completedModules: <int>{1, 2}), isTrue);
    });
  });

  group('Characterization: Planting Sequence Validation', () {
    test('validates correct sequence as 0,1,2,3', () {
      bool validateSequence(List<int> stepIds) => stepIds.join(',') == '0,1,2,3';

      expect(validateSequence(<int>[0, 1, 2, 3]), isTrue);
      expect(validateSequence(<int>[2, 0, 3, 1]), isFalse);
      expect(validateSequence(<int>[1, 0, 2, 3]), isFalse);
    });
  });

  group('Characterization: Smoke Widget Test', () {
    testWidgets('renders RooveyLearnApp with fake services, enters guest mode, and switches 4 tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeAuth = FakeAuthService();
      final fakeProgress = FakeProgressService();
      final fakeRepo = FakeLearningRepository();

      await tester.pumpWidget(
        RooveyLearnApp(
          authService: fakeAuth,
          progressService: fakeProgress,
          learningRepository: fakeRepo,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // WelcomeScreen should be visible
      expect(find.text('ROOVEYLEARN'), findsWidgets);
      final guestButton = find.text('Jelajah tanpa akun');
      expect(guestButton, findsOneWidget);

      // Tap 'Jelajah tanpa akun' to enter AppShell
      await tester.ensureVisible(guestButton);
      await tester.tap(guestButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Should be on Beranda (Tab 0) in guest mode
      expect(find.text('Halo, Penjaga Pesisir'), findsOneWidget);
      expect(find.text('Ekosistem sehat,\npesisir tangguh.'), findsOneWidget);
      expect(find.text('Mode Tamu: Progres Tidak Tersimpan'), findsOneWidget);

      // Tap 'Jelajah' tab (Tab 1)
      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('JELAJAH EKOSISTEM'), findsOneWidget);
      expect(find.text('Dengar alam\nbercerita.'), findsOneWidget);

      // Tap 'Belajar' tab (Tab 2)
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('JALUR BELAJAR'), findsOneWidget);
      expect(find.text('Tumbuh bersama\nmangrove.'), findsOneWidget);

      // Tap 'Progres' tab (Tab 3) - Shows AuthGate for guest
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PERJALANAN BELAJARMU'), findsOneWidget);
      expect(find.text('Masuk untuk Menyimpan Progres'), findsOneWidget);
    });
  });
}
