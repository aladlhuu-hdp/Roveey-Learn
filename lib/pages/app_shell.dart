import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/learning_module.dart';
import '../widgets/auth/auth_gate.dart';
import 'auth/account_profile_screen.dart';
import 'auth/login_screen.dart';
import 'auth/welcome_screen.dart';
import 'explore/explore_page.dart';
import 'home/home_page.dart';
import 'learn/learn_page.dart';
import 'learn/lesson_screen.dart';
import 'learn/module_completion_screen.dart';
import 'progress/progress_page.dart';
import 'quiz/quiz_screen.dart';
import 'simulation/planting_sequence_screen.dart';
import 'simulation/refractometer_calibration_screen.dart';
import 'simulation/sequence_diagnostic_screen.dart';
import 'simulation/simulation_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _openAccount(AppController controller) {
    final profile = controller.profile;
    final Widget screen = profile == null
        ? LoginScreen(onAuthenticated: controller.activateProfile)
        : AccountProfileScreen(
            profile: profile,
            onNameChanged: controller.updateProfileName,
            onSignOut: controller.signOut,
          );
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openRegister(AppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(onAuthenticated: controller.activateProfile),
      ),
    );
  }

  void _openLesson(AppController controller, int index) {
    if (!controller.isModuleUnlocked(index)) return;
    final module = defaultLearningModules[index];
    final wasCompleted = controller.isModuleCompleted(module.id);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
          module: module,
          alreadyCompleted: wasCompleted,
          onComplete: () async {
            await controller.completeModule(module.id);
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => ModuleCompletionScreen(
                    module: module,
                    completedCount: controller.completedModules.length,
                    nextModuleTitle: index + 1 < defaultLearningModules.length
                        ? defaultLearningModules[index + 1].title
                        : null,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _openSimulation(AppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SimulationScreen(
          onComplete: (correct) {
            controller.recordSimulation(
              simulationType: 'decision_making',
              isSuccess: correct,
            );
          },
        ),
      ),
    );
  }

  void _openPreTest(AppController controller) {
    if (!controller.isAuthenticated) {
      RequireLogin.guard(
        context,
        isAuthenticated: false,
        featureName: 'Pre-test',
        onAuthenticatedAction: () {},
        onLoginSuccess: (profile) async {
          await controller.activateProfile(profile);
          if (mounted) _openPreTest(controller);
        },
      );
      return;
    }

    if (controller.preTestScore != null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          isPreTest: true,
          onComplete: (_) {},
        ),
      ),
    );
  }

  void _openQuiz(AppController controller) {
    if (!controller.isAuthenticated) {
      RequireLogin.guard(
        context,
        isAuthenticated: false,
        featureName: 'Asesmen Akhir',
        onAuthenticatedAction: () {},
        onLoginSuccess: (profile) async {
          await controller.activateProfile(profile);
          if (mounted) _openQuiz(controller);
        },
      );
      return;
    }

    if (!controller.canTakeFinalQuiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selesaikan seluruh 5 modul sebelum mengikuti Asesmen Akhir.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          quizType: 'final',
          onComplete: (_) {},
        ),
      ),
    );
  }

  void _openSequenceActivity() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PlantingSequenceScreen()));
  }

  void _openSequenceDiagnostic() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SequenceDiagnosticScreen()));
  }

  void _openRefractometerActivity() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RefractometerCalibrationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(color: AppColors.forest),
              SizedBox(height: 16),
              Text('Memuat data RooveyLearn...'),
            ],
          ),
        ),
      );
    }

    if (!controller.hasCompletedWelcome && controller.profile == null) {
      return WelcomeScreen(
        onRegister: () => _openRegister(controller),
        onSignIn: () => _openAccount(controller),
        onContinueAsGuest: controller.continueAsGuest,
      );
    }

    final pages = <Widget>[
      HomePage(
        completedCount: controller.completedModules.length,
        profileName: controller.profile?.name,
        preTestScore: controller.preTestScore,
        onPreTest: () => _openPreTest(controller),
        canTakeFinalQuiz: controller.canTakeFinalQuiz,
        onAccount: () => _openAccount(controller),
        onExplore: () => controller.goToTab(1),
        onLearn: () => controller.goToTab(2),
        onQuiz: () => _openQuiz(controller),
        onSimulation: () => _openSimulation(controller),
      ),
      ExplorePage(
        exploredTopics: controller.exploredTopics,
        onTopicExplored: controller.exploreTopic,
      ),
      LearnPage(
        completedModules: controller.completedModules,
        preTestScore: controller.preTestScore,
        canTakeFinalQuiz: controller.canTakeFinalQuiz,
        isGuest: !controller.isAuthenticated,
        isModuleUnlocked: controller.isModuleUnlocked,
        onOpenPreTest: () => _openPreTest(controller),
        onOpenModule: (index) => _openLesson(controller, index),
        onOpenQuiz: () => _openQuiz(controller),
        onOpenSimulation: () => _openSimulation(controller),
        onOpenSequence: _openSequenceActivity,
        onOpenSequenceDiagnostic: _openSequenceDiagnostic,
        onOpenRefractometer: _openRefractometerActivity,
      ),
      ProgressPage(
        completedModules: controller.completedModules,
        exploredCount: controller.exploredTopics.length,
        quizScore: controller.quizScore,
        preTestScore: controller.preTestScore,
        profile: controller.profile,
        certificateId: controller.certificateId,
        certificateIssuedAt: controller.certificateIssuedAt,
        onLogin: () => _openAccount(controller),
        onClaimCertificate: () => controller.tryIssueCertificate(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: IndexedStack(index: controller.tab, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.tab,
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.accentMint.withValues(alpha: 0.16),
        height: 64,
        onDestinationSelected: controller.goToTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Jelajah',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Belajar',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progres',
          ),
        ],
      ),
    );
  }
}
