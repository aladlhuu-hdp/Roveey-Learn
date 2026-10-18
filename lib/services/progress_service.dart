import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/local_profile.dart';

class ProgressData {
  const ProgressData({
    required this.xp,
    required this.quizScore,
    required this.preTestScore,
    required this.completedModules,
    required this.exploredTopics,
    required this.certificateIssuedAt,
  });

  final int xp;
  final int? quizScore;
  final int? preTestScore;
  final Set<int> completedModules;
  final Set<String> exploredTopics;
  final String? certificateIssuedAt;

  factory ProgressData.empty() => const ProgressData(
        xp: 0,
        quizScore: null,
        preTestScore: null,
        completedModules: <int>{},
        exploredTopics: <String>{},
        certificateIssuedAt: null,
      );
}

abstract interface class ProgressService {
  Future<ProgressData> loadProgress(LocalProfile? profile);
  Future<void> saveProgress({
    required LocalProfile? profile,
    required int xp,
    required int? quizScore,
    required int? preTestScore,
    required Set<int> completedModules,
    required Set<String> exploredTopics,
  });
  Future<String?> getCertificateIssuedAt(LocalProfile profile);
  Future<void> saveCertificateIssuedAt(LocalProfile profile, String issuedAt);
  Future<bool> hasCompletedWelcome();
  Future<void> setCompletedWelcome(bool completed);
}

class LocalProgressService implements ProgressService {
  Future<void> _pendingSave = Future<void>.value();

  String _progressKey(String key, LocalProfile? profile) {
    return profile == null ? key : '${key}_${profile.storageId}';
  }

  @override
  Future<ProgressData> loadProgress(LocalProfile? profile) async {
    final prefs = await SharedPreferences.getInstance();
    final xpKey = _progressKey(AppConstants.xpKey, profile);
    final quizScoreKey = _progressKey(AppConstants.quizScoreKey, profile);
    final completedModulesKey = _progressKey(AppConstants.completedModulesKey, profile);
    final exploredTopicsKey = _progressKey(AppConstants.exploredTopicsKey, profile);
    final preTestKey = _progressKey(AppConstants.preTestKey, profile);
    final certificateKey = _progressKey(AppConstants.certificateDateKey, profile);

    final savedModules = prefs.getStringList(completedModulesKey) ?? <String>[];
    final savedTopics = prefs.getStringList(exploredTopicsKey) ?? <String>[];

    final completedModules = savedModules
        .map(int.tryParse)
        .whereType<int>()
        .where((i) => i >= 0 && i < 5)
        .toSet();

    return ProgressData(
      xp: prefs.getInt(xpKey) ?? 0,
      quizScore: prefs.getInt(quizScoreKey),
      preTestScore: prefs.getInt(preTestKey),
      completedModules: completedModules,
      exploredTopics: savedTopics.toSet(),
      certificateIssuedAt: prefs.getString(certificateKey),
    );
  }

  @override
  Future<void> saveProgress({
    required LocalProfile? profile,
    required int xp,
    required int? quizScore,
    required int? preTestScore,
    required Set<int> completedModules,
    required Set<String> exploredTopics,
  }) async {
    final xpKey = _progressKey(AppConstants.xpKey, profile);
    final quizScoreKey = _progressKey(AppConstants.quizScoreKey, profile);
    final preTestKey = _progressKey(AppConstants.preTestKey, profile);
    final completedModulesKey = _progressKey(AppConstants.completedModulesKey, profile);
    final exploredTopicsKey = _progressKey(AppConstants.exploredTopicsKey, profile);
    final modules = completedModules.map((value) => value.toString()).toList()..sort();
    final topics = exploredTopics.toList()..sort();

    _pendingSave = _pendingSave.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(xpKey, xp);
      if (quizScore == null) {
        await prefs.remove(quizScoreKey);
      } else {
        await prefs.setInt(quizScoreKey, quizScore);
      }
      if (preTestScore != null) await prefs.setInt(preTestKey, preTestScore);
      await prefs.setStringList(completedModulesKey, modules);
      await prefs.setStringList(exploredTopicsKey, topics);
    }).catchError((Object error) {
      debugPrint('RooveyLearn: gagal menyimpan progres lokal: $error');
    });

    await _pendingSave;
  }

  @override
  Future<String?> getCertificateIssuedAt(LocalProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _progressKey(AppConstants.certificateDateKey, profile);
    return prefs.getString(key);
  }

  @override
  Future<void> saveCertificateIssuedAt(LocalProfile profile, String issuedAt) async {
    await _pendingSave;
    final prefs = await SharedPreferences.getInstance();
    final key = _progressKey(AppConstants.certificateDateKey, profile);
    if (!prefs.containsKey(key)) {
      await prefs.setString(key, issuedAt);
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
