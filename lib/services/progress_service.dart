import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/quiz_question.dart';
import '../models/user_profile.dart';

class CertificateData {
  const CertificateData({
    required this.certificateId,
    required this.certificateNumber,
    required this.participantName,
    this.programName = 'Dasar Pengelolaan Mangrove',
    required this.finalScore,
    required this.issuedAt,
  });

  final String certificateId;
  final String certificateNumber;
  final String participantName;
  final String programName;
  final int finalScore;
  final String issuedAt;

  factory CertificateData.fromJson(Map<String, dynamic> json) {
    return CertificateData(
      certificateId: json['certificate_id']?.toString() ?? json['id']?.toString() ?? '',
      certificateNumber: json['certificate_number']?.toString() ?? '',
      participantName: json['participant_name']?.toString() ?? '',
      programName: json['program_name']?.toString() ?? 'Dasar Pengelolaan Mangrove',
      finalScore: (json['final_score'] as num?)?.toInt() ?? 0,
      issuedAt: json['issued_at']?.toString() ?? '',
    );
  }
}

class ProgressData {
  const ProgressData({
    required this.completedModules,
    required this.quizScore,
    required this.preTestScore,
    required this.certificate,
    this.exploredTopics = const <String>{},
  });

  final Set<int> completedModules;
  final int? quizScore;
  final int? preTestScore;
  final CertificateData? certificate;
  final Set<String> exploredTopics;

  factory ProgressData.empty() => const ProgressData(
        completedModules: <int>{},
        quizScore: null,
        preTestScore: null,
        certificate: null,
        exploredTopics: <String>{},
      );
}

abstract interface class ProgressService {
  Future<ProgressData> loadProgress(UserProfile? profile);
  Future<Map<String, dynamic>> completeModule(int moduleId);
  Future<QuizSubmitResult> submitQuiz({
    required String quizType,
    int? moduleId,
    required List<Map<String, dynamic>> answers,
  });
  Future<CertificateData?> getCertificate(UserProfile profile);
  Future<CertificateData> issueCertificate();
  Future<void> recordSimulationAttempt({
    required String simulationType,
    int? moduleId,
    required bool isSuccess,
    int score,
    String? feedback,
    Map<String, dynamic>? payload,
  });
  Future<bool> hasCompletedWelcome();
  Future<void> setCompletedWelcome(bool completed);
}

class SupabaseProgressService implements ProgressService {
  SupabaseProgressService([SupabaseClient? client]) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<ProgressData> loadProgress(UserProfile? profile) async {
    if (profile == null || profile.id.isEmpty) {
      return ProgressData.empty();
    }

    try {
      // 1. Ambil modul yang completed
      final progressRows = await _client
          .from('user_module_progress')
          .select('module_id, status')
          .eq('user_id', profile.id)
          .eq('status', 'completed');

      final completedModules = (progressRows as List)
          .map((row) => (row['module_id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();

      // 2. Ambil nilai asesmen
      final assessmentRows = await _client
          .from('assessment_results')
          .select('assessment_type, score, is_passed, completed_at')
          .eq('user_id', profile.id)
          .order('completed_at', ascending: true);

      int? preTestScore;
      int? bestFinalScore;

      for (final row in (assessmentRows as List)) {
        final type = row['assessment_type']?.toString();
        final score = (row['score'] as num?)?.toInt();
        if (score == null) continue;

        if (type == 'pretest') {
          preTestScore = score;
        } else if (type == 'final') {
          bestFinalScore = bestFinalScore == null ? score : max(bestFinalScore, score);
        }
      }

      // 3. Ambil sertifikat aktif
      final certRow = await _client
          .from('certificates')
          .select('id, certificate_number, final_score, issued_at')
          .eq('user_id', profile.id)
          .eq('status', 'active')
          .maybeSingle();

      CertificateData? certificate;
      if (certRow != null) {
        certificate = CertificateData(
          certificateId: certRow['id'].toString(),
          certificateNumber: certRow['certificate_number'].toString(),
          participantName: profile.name,
          finalScore: (certRow['final_score'] as num).toInt(),
          issuedAt: certRow['issued_at'].toString(),
        );
      }

      return ProgressData(
        completedModules: completedModules,
        quizScore: bestFinalScore,
        preTestScore: preTestScore,
        certificate: certificate,
      );
    } catch (e) {
      debugPrint('SupabaseProgressService: gagal memuat progres dari server: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> completeModule(int moduleId) async {
    final response = await _client.rpc(
      'complete_module',
      params: <String, dynamic>{'p_module_id': moduleId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<QuizSubmitResult> submitQuiz({
    required String quizType,
    int? moduleId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _client.rpc(
      'submit_quiz',
      params: <String, dynamic>{
        'p_quiz_type': quizType,
        'p_module_id': moduleId,
        'p_answers': answers,
      },
    );

    return QuizSubmitResult.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<CertificateData?> getCertificate(UserProfile profile) async {
    final row = await _client
        .from('certificates')
        .select('id, certificate_number, final_score, issued_at')
        .eq('user_id', profile.id)
        .eq('status', 'active')
        .maybeSingle();

    if (row == null) return null;

    return CertificateData(
      certificateId: row['id'].toString(),
      certificateNumber: row['certificate_number'].toString(),
      participantName: profile.name,
      finalScore: (row['final_score'] as num).toInt(),
      issuedAt: row['issued_at'].toString(),
    );
  }

  @override
  Future<CertificateData> issueCertificate() async {
    final response = await _client.rpc('issue_certificate');
    final map = Map<String, dynamic>.from(response as Map);
    final certJson = Map<String, dynamic>.from(map['certificate'] as Map);
    return CertificateData.fromJson(certJson);
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
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('simulation_attempts').insert(<String, dynamic>{
        'user_id': user.id,
        'simulation_type': simulationType,
        if (moduleId != null) 'module_id': moduleId,
        'payload': payload ?? <String, dynamic>{},
        'is_success': isSuccess,
        'score': score,
        if (feedback != null) 'feedback_given': feedback,
        'xp_earned': 0,
      });
    } catch (e) {
      debugPrint('SupabaseProgressService: gagal mencatat simulasi: $e');
      // Non-fatal logging
    }
  }

  @override
  Future<bool> hasCompletedWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.welcomeCompletedKey) ?? false;
  }

  @override
  Future<void> setCompletedWelcome(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.welcomeCompletedKey, completed);
  }
}
