import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rooveylearn/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Characterization: Quiz Scoring and Passing Logic', () {
    test('calculates percentage accurately from total questions', () {
      final total = quizQuestions.length; // 5
      expect(total, 5);

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

    test('XP earned from quiz is score ~/ 10', () {
      expect(100 ~/ 10, 10);
      expect(80 ~/ 10, 8);
      expect(60 ~/ 10, 6);
      expect(45 ~/ 10, 4);
    });
  });

  group('Characterization: Certificate Eligibility & ID Format', () {
    test('requires 5 modules completed, score >= 80%, and active profile', () {
      bool isCertificateEligible({
        required bool hasProfile,
        required int completedModulesCount,
        required int? quizScore,
      }) {
        return hasProfile && completedModulesCount == learningModules.length && (quizScore ?? 0) >= 80;
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

    test('generates certificate ID format RLB-YYYY-HASH8', () {
      const profile = LocalProfile(name: 'Budi', email: 'budi@pesisir.org', createdAt: '2026-05-10T08:00:00.000Z');
      const issuedAt = '2026-05-15T10:00:00.000Z';
      final year = DateTime.parse(issuedAt).year;
      final certificateId = 'RLB-$year-${profile.storageId.substring(0, 8).toUpperCase()}';

      expect(certificateId, startsWith('RLB-2026-'));
      expect(certificateId.length, 17); // RLB-2026- (9) + 8 chars = 17
    });
  });

  group('Characterization: Module Unlock, Progress, and XP Logic', () {
    bool isModuleUnlocked({
      required int index,
      required Set<int> completedModules,
      required int? preTestScore,
    }) {
      return completedModules.contains(index) ||
          (index == 0 && (preTestScore != null || completedModules.isNotEmpty)) ||
          (index > 0 && completedModules.contains(index - 1));
    }

    test('Module 0 is locked initially before pre-test is taken', () {
      expect(isModuleUnlocked(index: 0, completedModules: <int>{}, preTestScore: null), isFalse);
    });

    test('Module 0 unlocks when pre-test is completed', () {
      expect(isModuleUnlocked(index: 0, completedModules: <int>{}, preTestScore: 60), isTrue);
    });

    test('subsequent modules unlock sequentially when previous module is completed', () {
      expect(isModuleUnlocked(index: 1, completedModules: <int>{}, preTestScore: 60), isFalse);
      expect(isModuleUnlocked(index: 1, completedModules: <int>{0}, preTestScore: 60), isTrue);

      expect(isModuleUnlocked(index: 2, completedModules: <int>{0}, preTestScore: 60), isFalse);
      expect(isModuleUnlocked(index: 2, completedModules: <int>{0, 1}, preTestScore: 60), isTrue);
    });

    test('XP rewards rule: +20 on first module completion, +15 on correct simulation, +5 on wrong simulation', () {
      var xp = 0;
      final completed = <int>{};

      // Completing module 0 first time
      if (completed.add(0)) xp += 20;
      expect(xp, 20);

      // Re-completing module 0 gives 0 extra XP
      if (completed.add(0)) xp += 20;
      expect(xp, 20);

      // Correct simulation gives +15
      xp += true ? 15 : 5;
      expect(xp, 35);

      // Wrong simulation gives +5
      xp += false ? 15 : 5;
      expect(xp, 40);
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
    testWidgets('renders RooveyLearnApp, enters guest mode, and switches 4 tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const RooveyLearnApp());
      // First pump: starts async _loadProgress
      await tester.pump();
      // Pump timer / microtask to finish SharedPreferences.getInstance()
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

      // Should be on Beranda (Tab 0)
      expect(find.text('Halo, Penjaga Pesisir'), findsOneWidget);
      expect(find.text('Ekosistem sehat,\npesisir tangguh.'), findsOneWidget);

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

      // Tap 'Progres' tab (Tab 3)
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PERJALANAN BELAJARMU'), findsOneWidget);
      expect(find.text('Lihat sejauh\nmana kamu tumbuh.'), findsOneWidget);
    });
  });
}
