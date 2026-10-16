/// Centralized application constants (storage keys, thresholds, scoring).
abstract final class AppConstants {
  // SharedPreferences Keys
  static const String accountsKey = 'local_accounts_v1';
  static const String sessionKey = 'local_session_email_v1';
  static const String xpKey = 'progress_xp_v1';
  static const String quizScoreKey = 'progress_quiz_score_v1';
  static const String completedModulesKey = 'progress_completed_modules_v1';
  static const String exploredTopicsKey = 'progress_explored_topics_v1';
  static const String preTestKey = 'progress_pre_test_score_v1';
  static const String certificateDateKey = 'certificate_issued_at_v1';
  static const String welcomeCompletedKey = 'welcome_completed_v1';

  // Scoring & Certification
  static const int quizPassingScore = 80;
  static const int xpPerModule = 20;
  static const int xpSimulationCorrect = 15;
  static const int xpSimulationWrong = 5;

  // Maximum content width for responsive layout
  static const double maxContentWidth = 780;
  static const double maxAuthCardWidth = 520;
}
