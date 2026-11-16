import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_error_mapper.dart';
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
    final modules = controller.modules;
    if (index >= modules.length) return;
    final module = modules[index];
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
                    totalModules: controller.totalModules,
                    nextModuleTitle: index + 1 < controller.totalModules
                        ? controller.modules[index + 1].title
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

  void _openSequenceActivity(AppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantingSequenceScreen(
          onComplete: (correct) {
            controller.recordSimulation(
              simulationType: 'planting_sequence',
              moduleId: 3,
              isSuccess: correct,
            );
          },
        ),
      ),
    );
  }

  void _openSequenceDiagnostic(AppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SequenceDiagnosticScreen(
          onComplete: (correct) {
            controller.recordSimulation(
              simulationType: 'sequence_diagnostic',
              moduleId: 3,
              isSuccess: correct,
            );
          },
        ),
      ),
    );
  }

  void _openRefractometerActivity(AppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RefractometerCalibrationScreen(
          onComplete: (correct) {
            controller.recordSimulation(
              simulationType: 'refractometer_calibration',
              moduleId: 3,
              isSuccess: correct,
            );
          },
        ),
      ),
    );
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

    if (controller.errorMessage != null && !controller.hasCompletedWelcome && controller.profile == null) {
      final isConfigError = !SupabaseConfig.isConfigured;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.errorDark),
                const SizedBox(height: 16),
                Text(
                  isConfigError
                      ? 'Konfigurasi Belum Lengkap'
                      : 'Kendala Koneksi Server',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  isConfigError
                      ? 'Kredensial Supabase belum dikonfigurasi. Jalankan aplikasi dengan --dart-define-from-file=env.json sesuai panduan README.'
                      : AppErrorMapper.toUserMessage(controller.errorMessage!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => controller.init(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: controller.continueAsGuest,
                  child: const Text('Lanjut Jelajah (Mode Tamu)'),
                ),
              ],
            ),
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
        totalModules: controller.totalModules,
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
        modules: controller.modules,
        onOpenPreTest: () => _openPreTest(controller),
        onOpenModule: (index) => _openLesson(controller, index),
        onOpenQuiz: () => _openQuiz(controller),
        onOpenSimulation: () => _openSimulation(controller),
        onOpenSequence: () => _openSequenceActivity(controller),
        onOpenSequenceDiagnostic: () => _openSequenceDiagnostic(controller),
        onOpenRefractometer: () => _openRefractometerActivity(controller),
      ),
      ProgressPage(
        completedModules: controller.completedModules,
        totalModules: controller.totalModules,
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
