import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'pages/app_shell.dart';
import 'repositories/learning_repository.dart';
import 'services/auth_service.dart';
import 'services/progress_service.dart';

// Exports for backward compatibility with existing tests and modules
export 'controllers/app_controller.dart';
export 'core/constants/app_colors.dart';
export 'core/constants/app_constants.dart';
export 'core/theme/app_theme.dart';
export 'models/explorer_topic.dart';
export 'models/learning_module.dart';
export 'models/local_profile.dart';
export 'models/protocol_step.dart';
export 'models/quiz_question.dart';
export 'pages/app_shell.dart';
export 'repositories/learning_repository.dart';
export 'services/auth_service.dart';
export 'services/progress_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RooveyLearnApp());
}

class RooveyLearnApp extends StatelessWidget {
  const RooveyLearnApp({
    super.key,
    this.authService,
    this.progressService,
    this.learningRepository,
  });

  final AuthService? authService;
  final ProgressService? progressService;
  final LearningRepository? learningRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => authService ?? LocalAuthService(),
        ),
        Provider<ProgressService>(
          create: (_) => progressService ?? LocalProgressService(),
        ),
        Provider<LearningRepository>(
          create: (_) => learningRepository ?? const LocalLearningRepository(),
        ),
        ChangeNotifierProvider<AppController>(
          create: (ctx) => AppController(
            authService: ctx.read<AuthService>(),
            progressService: ctx.read<ProgressService>(),
          )..init(),
        ),
      ],
      child: MaterialApp(
        title: 'RooveyLearn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppShell(),
      ),
    );
  }
}
