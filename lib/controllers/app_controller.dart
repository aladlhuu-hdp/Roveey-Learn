import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/learning_module.dart';
import '../models/local_profile.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required AuthService authService,
    required ProgressService progressService,
  })  : _authService = authService,
        _progressService = progressService;

  final AuthService _authService;
  final ProgressService _progressService;

  int _tab = 0;
  int _xp = 0;
  int? _quizScore;
  int? _preTestScore;
  LocalProfile? _profile;
  String? _certificateIssuedAt;
  bool _hasCompletedWelcome = false;
  bool _isLoading = true;
  final Set<int> _completedModules = <int>{};
  final Set<String> _exploredTopics = <String>{};

  // Getters
  int get tab => _tab;
  int get xp => _xp;
  int? get quizScore => _quizScore;
  int? get preTestScore => _preTestScore;
  LocalProfile? get profile => _profile;
  String? get certificateIssuedAt => _certificateIssuedAt;
  bool get hasCompletedWelcome => _hasCompletedWelcome;
  bool get isLoading => _isLoading;
  Set<int> get completedModules => Set<int>.unmodifiable(_completedModules);
  Set<String> get exploredTopics => Set<String>.unmodifiable(_exploredTopics);
  bool get canTakeFinalQuiz => _completedModules.length == learningModules.length;

  String? get certificateId {
    final prof = _profile;
    final issued = _certificateIssuedAt;
    if (prof == null || issued == null) return null;
    final year = DateTime.tryParse(issued)?.year;
    if (year == null) return null;
    return 'RLB-$year-${prof.storageId.substring(0, 8).toUpperCase()}';
  }

  bool isModuleUnlocked(int index) {
    return _completedModules.contains(index) ||
        (index == 0 && (_preTestScore != null || _completedModules.isNotEmpty)) ||
        (index > 0 && _completedModules.contains(index - 1));
  }

  Future<void> init() async {
    try {
      final activeProfile = await _authService.currentProfile();
      final welcomeCompleted = await _progressService.hasCompletedWelcome();
      final data = await _progressService.loadProgress(activeProfile);

      _profile = activeProfile;
      _hasCompletedWelcome = welcomeCompleted || activeProfile != null;
      _xp = data.xp;
      _quizScore = data.quizScore;
      _preTestScore = data.preTestScore;
      _certificateIssuedAt = data.certificateIssuedAt;
      _completedModules
        ..clear()
        ..addAll(data.completedModules);
      _exploredTopics
        ..clear()
        ..addAll(data.exploredTopics);
      _isLoading = false;
      notifyListeners();

      await _ensureCertificateIssued();
    } catch (e) {
      debugPrint('AppController: failed to load progress: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void goToTab(int index) {
    if (_tab != index) {
      _tab = index;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    await _progressService.setCompletedWelcome(true);
    _hasCompletedWelcome = true;
    notifyListeners();
  }

  Future<void> activateProfile(LocalProfile newProfile) async {
    await _progressService.setCompletedWelcome(true);
    _profile = newProfile;
    _hasCompletedWelcome = true;
    _isLoading = true;
    notifyListeners();

    final data = await _progressService.loadProgress(newProfile);
    _xp = data.xp;
    _quizScore = data.quizScore;
    _preTestScore = data.preTestScore;
    _certificateIssuedAt = data.certificateIssuedAt;
    _completedModules
      ..clear()
      ..addAll(data.completedModules);
    _exploredTopics
      ..clear()
      ..addAll(data.exploredTopics);
    _isLoading = false;
    notifyListeners();

    await _ensureCertificateIssued();
  }

  Future<LocalProfile> updateProfileName(String name) async {
    if (_profile == null) throw const LocalAuthException('Profil tidak ditemukan.');
    final updated = await _authService.updateName(_profile!, name);
    _profile = updated;
    notifyListeners();
    return updated;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    _isLoading = true;
    notifyListeners();

    final data = await _progressService.loadProgress(null);
    _xp = data.xp;
    _quizScore = data.quizScore;
    _preTestScore = data.preTestScore;
    _certificateIssuedAt = data.certificateIssuedAt;
    _completedModules
      ..clear()
      ..addAll(data.completedModules);
    _exploredTopics
      ..clear()
      ..addAll(data.exploredTopics);
    _isLoading = false;
    notifyListeners();
  }

  void completeModule(int index) {
    final firstTime = _completedModules.add(index);
    if (firstTime) {
      _xp += AppConstants.xpPerModule;
    }
    notifyListeners();
    _persistProgress();
    _ensureCertificateIssued();
  }

  void completeSimulation(bool correct) {
    _xp += correct ? AppConstants.xpSimulationCorrect : AppConstants.xpSimulationWrong;
    notifyListeners();
    _persistProgress();
  }

  void completePreTest(int score) {
    _preTestScore = score;
    notifyListeners();
    _persistProgress();
  }

  void completeQuiz(int score) {
    _quizScore = score;
    _xp += (score ~/ 10);
    notifyListeners();
    _persistProgress();
    _ensureCertificateIssued();
  }

  void exploreTopic(String id) {
    final isNew = _exploredTopics.add(id);
    if (isNew) {
      notifyListeners();
      _persistProgress();
    }
  }

  void _persistProgress() {
    _progressService.saveProgress(
      profile: _profile,
      xp: _xp,
      quizScore: _quizScore,
      preTestScore: _preTestScore,
      completedModules: _completedModules,
      exploredTopics: _exploredTopics,
    );
  }

  Future<void> _ensureCertificateIssued() async {
    final prof = _profile;
    if (prof == null ||
        _completedModules.length != learningModules.length ||
        (_quizScore ?? 0) < AppConstants.quizPassingScore) {
      return;
    }
    final existingDate = await _progressService.getCertificateIssuedAt(prof);
    final issuedAt = existingDate ?? DateTime.now().toIso8601String();
    if (existingDate == null) {
      await _progressService.saveCertificateIssuedAt(prof, issuedAt);
    }
    _certificateIssuedAt = issuedAt;
    notifyListeners();
  }
}
