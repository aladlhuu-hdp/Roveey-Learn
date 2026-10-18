import 'dart:async';
import 'package:rooveylearn/main.dart';

class FakeAuthService implements AuthService {
  UserProfile? _currentUser;
  final StreamController<UserProfile?> _authStream = StreamController<UserProfile?>.broadcast();

  FakeAuthService({UserProfile? initialUser}) : _currentUser = initialUser;

  @override
  Future<UserProfile?> currentProfile() async => _currentUser;

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = UserProfile(
      id: 'fake-user-123',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _currentUser = user;
    _authStream.add(user);
    return user;
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final user = UserProfile(
      id: 'fake-user-123',
      name: email.split('@').first,
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _currentUser = user;
    _authStream.add(user);
    return user;
  }

  @override
  Future<UserProfile> updateName(UserProfile profile, String name) async {
    final updated = profile.copyWith(name: name.trim());
    _currentUser = updated;
    _authStream.add(updated);
    return updated;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStream.add(null);
  }

  @override
  Stream<UserProfile?> authStateChanges() => _authStream.stream;
}

class FakeProgressService implements ProgressService {
  Set<int> completedModules;
  int? quizScore;
  int? preTestScore;
  CertificateData? certificate;
  bool welcomeCompleted;
  final List<Map<String, dynamic>> recordedSimulations = <Map<String, dynamic>>[];

  FakeProgressService({
    Set<int>? completedModules,
    this.quizScore,
    this.preTestScore,
    this.certificate,
    this.welcomeCompleted = false,
  }) : completedModules = completedModules ?? <int>{};

  @override
  Future<ProgressData> loadProgress(UserProfile? profile) async {
    if (profile == null) return ProgressData.empty();
    return ProgressData(
      completedModules: completedModules,
      quizScore: quizScore,
      preTestScore: preTestScore,
      certificate: certificate,
    );
  }

  @override
  Future<Map<String, dynamic>> completeModule(int moduleId) async {
    if (moduleId > 1 && !completedModules.contains(moduleId - 1)) {
      throw Exception('Alur belajar bertahap: Anda harus menyelesaikan modul sebelumnya (Modul ${moduleId - 1}) terlebih dahulu.');
    }
    completedModules.add(moduleId);
    return <String, dynamic>{
      'success': true,
      'message': 'Modul $moduleId berhasil diselesaikan.',
    };
  }

  @override
  Future<QuizSubmitResult> submitQuiz({
    required String quizType,
    int? moduleId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final total = answers.isEmpty ? 5 : answers.length;
    final correct = answers.length; // Fake default: all answers considered correct
    final score = (correct / total * 100).round();
    final isPassed = score >= 80;

    final evaluations = answers.map((ans) {
      return QuizEvaluation(
        questionId: ans['question_id']?.toString() ?? '',
        selectedOption: ans['selected_option'] as int?,
        correctOptionIndex: ans['selected_option'] as int? ?? 0,
        isCorrect: true,
        explanation: 'Penjelasan server: jawaban tepat.',
      );
    }).toList();

    return QuizSubmitResult(
      assessmentId: 'fake-assessment-id-123',
      quizType: quizType,
      moduleId: moduleId,
      score: score,
      totalQuestions: total,
      correctAnswers: correct,
      isPassed: isPassed,
      attemptNumber: 1,
      evaluations: evaluations,
    );
  }

  @override
  Future<CertificateData?> getCertificate(UserProfile profile) async => certificate;

  @override
  Future<CertificateData> issueCertificate() async {
    final cert = CertificateData(
      certificateId: 'fake-cert-uuid',
      certificateNumber: 'ROOVEY-20261018-ABC123',
      participantName: 'Peserta Uji',
      finalScore: quizScore ?? 100,
      issuedAt: DateTime.now().toIso8601String(),
    );
    certificate = cert;
    return cert;
  }

  @override
  Future<void> recordSimulationAttempt({
    required String simulationType,
    int? moduleId,
    required bool isSuccess,
    int score = 100,
    String? feedback,
    Map<String, dynamic>? payload,
  }) async {
    recordedSimulations.add(<String, dynamic>{
      'simulation_type': simulationType,
      'module_id': moduleId,
      'is_success': isSuccess,
      'score': score,
      'feedback': feedback,
      'payload': payload,
    });
  }

  @override
  Future<bool> hasCompletedWelcome() async => welcomeCompleted;

  @override
  Future<void> setCompletedWelcome(bool completed) async {
    welcomeCompleted = completed;
  }
}

class FakeLearningRepository implements LearningRepository {
  final List<LearningModule> modules;
  final List<QuizQuestion> questions;

  FakeLearningRepository({
    List<LearningModule>? modules,
    List<QuizQuestion>? questions,
  })  : modules = modules ?? defaultLearningModules,
        questions = questions ??
            const <QuizQuestion>[
              QuizQuestion(
                id: '22222222-2222-2222-2222-222222222201',
                quizType: 'final',
                questionText: 'Apa yang membuat mangrove penting bagi ekosistem pesisir?',
                options: <String>[
                  'Hanya memperindah pemandangan',
                  'Menyediakan habitat dan membantu menstabilkan sedimen',
                  'Menghilangkan seluruh gelombang laut',
                  'Mengubah air laut menjadi air tawar',
                ],
                orderIndex: 1,
              ),
              QuizQuestion(
                id: '22222222-2222-2222-2222-222222222202',
                quizType: 'final',
                questionText: 'Apa yang sebaiknya diperiksa sebelum rehabilitasi?',
                options: <String>[
                  'Warna seragam relawan',
                  'Jumlah bibit sebanyak-banyaknya',
                  'Kesesuaian lokasi dan kondisi hidrologi',
                  'Desain spanduk kegiatan',
                ],
                orderIndex: 2,
              ),
            ];

  @override
  Future<List<LearningModule>> getModules() async => modules;

  @override
  Future<List<LearningMaterial>> getMaterialsForModule(int moduleId) async {
    return <LearningMaterial>[
      LearningMaterial(
        id: 'mat-$moduleId',
        moduleId: moduleId,
        title: 'Materi Modul $moduleId',
        content: 'Isi materi pengenalan ekosistem mangrove dan fungsinya.',
        takeaway: 'Inti pembelajaran modul $moduleId.',
        orderIndex: 1,
      ),
    ];
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions({
    required String quizType,
    int? moduleId,
  }) async {
    return questions
        .where((q) => q.quizType == quizType && (moduleId == null || q.moduleId == moduleId))
        .toList();
  }

  @override
  List<ExplorerTopic> getExplorerTopics() => explorerTopics;

  @override
  List<ProtocolStep> getPlantingSteps() => correctPlantingSteps;
}

