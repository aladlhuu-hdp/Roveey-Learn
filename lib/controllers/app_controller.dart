import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/learning_module.dart';
import '../models/quiz_question.dart';
import '../models/user_profile.dart';
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
  int? _quizScore;
  int? _preTestScore;
  UserProfile? _profile;
  CertificateData? _certificate;
  bool _hasCompletedWelcome = false;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _completedModules = <int>{};
  final Set<String> _exploredTopics = <String>{};

  // Getters
  int get tab => _tab;
  int? get quizScore => _quizScore;
  int? get preTestScore => _preTestScore;
  UserProfile? get profile => _profile;
  bool get isAuthenticated => _profile != null;
  CertificateData? get certificate => _certificate;
  String? get certificateIssuedAt => _certificate?.issuedAt;
  String? get certificateId => _certificate?.certificateNumber;
  bool get hasCompletedWelcome => _hasCompletedWelcome;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<int> get completedModules => Set<int>.unmodifiable(_completedModules);
  Set<String> get exploredTopics => Set<String>.unmodifiable(_exploredTopics);

  /// Syarat ikut kuis akhir: harus login dan 5 modul sudah selesai
  bool get canTakeFinalQuiz =>
      isAuthenticated && _completedModules.length >= defaultLearningModules.length;

  /// Aturan akses:
  /// - Tamu boleh membaca SEMUA 5 modul
  /// - Pengguna login mengikuti alur berurutan (modul 1 terbuka; modul N terbuka jika modul N-1 selesai)
  bool isModuleUnlocked(int index) {
    if (!isAuthenticated) return true; // Tamu boleh membaca semua 5 modul
    final moduleId = index + 1;
    if (moduleId == 1) return true;
    return _completedModules.contains(moduleId - 1) || _completedModules.contains(moduleId);
  }

  bool isModuleCompleted(int moduleId) => _completedModules.contains(moduleId);

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final activeProfile = await _authService.currentProfile();
      final welcomeCompleted = await _progressService.hasCompletedWelcome();

      _profile = activeProfile;
      _hasCompletedWelcome = welcomeCompleted || activeProfile != null;

      if (activeProfile != null) {
        await _loadServerProgress(activeProfile);
      } else {
        _completedModules.clear();
        _quizScore = null;
        _preTestScore = null;
        _certificate = null;
      }
    } catch (e) {
      debugPrint('AppController: gagal inisialisasi: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadServerProgress(UserProfile userProfile) async {
    try {
      final data = await _progressService.loadProgress(userProfile);
      _completedModules
        ..clear()
        ..addAll(data.completedModules);
      _quizScore = data.quizScore;
      _preTestScore = data.preTestScore;
      _certificate = data.certificate;
    } catch (e) {
      debugPrint('AppController: gagal mengambil data progres server: $e');
      rethrow;
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
    _profile = null;
    _completedModules.clear();
    _quizScore = null;
    _preTestScore = null;
    _certificate = null;
    notifyListeners();
  }

  Future<void> activateProfile(UserProfile newProfile) async {
    await _progressService.setCompletedWelcome(true);
    _profile = newProfile;
    _hasCompletedWelcome = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadServerProgress(newProfile);
    } catch (e) {
      debugPrint('AppController: gagal memuat progres profil baru: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile> updateProfileName(String name) async {
    if (_profile == null) throw Exception('Profil tidak ditemukan.');
    final updated = await _authService.updateName(_profile!, name);
    _profile = updated;
    notifyListeners();
    return updated;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    _completedModules.clear();
    _quizScore = null;
    _preTestScore = null;
    _certificate = null;
    _exploredTopics.clear();
    notifyListeners();
  }

  /// Menyelesaikan modul lewat RPC server `complete_module`
  Future<void> completeModule(int moduleId) async {
    if (!isAuthenticated) return;

    final response = await _progressService.completeModule(moduleId);
    if (response['success'] == true) {
      _completedModules.add(moduleId);
      notifyListeners();

      // Cek apakah sertifikat bisa diterbitkan otomatis jika kuis akhir >= 80%
      if (_completedModules.length >= defaultLearningModules.length &&
          (_quizScore ?? 0) >= 80 &&
          _certificate == null) {
        await tryIssueCertificate();
      }
    }
  }

  /// Kirim jawaban kuis ke server via RPC `submit_quiz`
  Future<QuizSubmitResult> submitQuiz({
    required String quizType,
    int? moduleId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final result = await _progressService.submitQuiz(
      quizType: quizType,
      moduleId: moduleId,
      answers: answers,
    );

    if (quizType == 'pretest') {
      _preTestScore = result.score;
    } else if (quizType == 'final') {
      _quizScore = _quizScore == null ? result.score : max(_quizScore!, result.score);
      if (result.isPassed && _completedModules.length >= defaultLearningModules.length) {
        await tryIssueCertificate();
      }
    }

    notifyListeners();
    return result;
  }

  /// Menerbitkan sertifikat via RPC server `issue_certificate`
  Future<CertificateData?> tryIssueCertificate() async {
    if (!isAuthenticated) return null;
    try {
      final cert = await _progressService.issueCertificate();
      _certificate = cert;
      notifyListeners();
      return cert;
    } catch (e) {
      debugPrint('AppController: issue certificate info/error: $e');
      return null;
    }
  }

  /// Catat hasil simulasi ke database jika login
  Future<void> recordSimulation({
    required String simulationType,
    int? moduleId,
    required bool isSuccess,
    int score = 100,
    String? feedback,
    Map<String, dynamic>? payload,
  }) async {
    if (!isAuthenticated) return;
    await _progressService.recordSimulationAttempt(
      simulationType: simulationType,
      moduleId: moduleId,
      isSuccess: isSuccess,
      score: score,
      feedback: feedback,
      payload: payload,
    );
  }

  void exploreTopic(String id) {
    if (_exploredTopics.add(id)) {
      notifyListeners();
    }
  }
}
