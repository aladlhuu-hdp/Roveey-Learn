import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color forest = Color(0xFF145B56);
const Color forestDeep = Color(0xFF203A38);
const Color leaf = Color(0xFF266863);
const Color accentMint = Color(0xFF06D6A0);
const Color sea = Color(0xFF496361);
const Color sand = Color(0xFFF5F5F7);
const Color paper = Color(0xFFFFFFFF);
const Color ink = Color(0xFF1D1D1F);
const Color muted = Color(0xFF6E6E73);
const Color line = Color(0xFFE5E5EA);

class LocalProfile {
  const LocalProfile({required this.name, required this.email, required this.createdAt});

  final String name;
  final String email;
  final String createdAt;

  String get storageId => sha256.convert(utf8.encode(email.toLowerCase())).toString().substring(0, 16);
}

class LocalAccountStore {
  static const String _accountsKey = 'local_accounts_v1';
  static const String sessionKey = 'local_session_email_v1';

  Future<LocalProfile?> currentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(sessionKey);
    if (email == null) return null;
    final account = _findAccount(prefs.getStringList(_accountsKey) ?? <String>[], email);
    return account == null ? null : _profileFrom(account);
  }

  Future<LocalProfile> register({required String name, required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList(_accountsKey) ?? <String>[];
    if (_findAccount(accounts, email) != null) {
      throw const LocalAuthException('Email ini sudah terdaftar di perangkat. Silakan masuk.');
    }
    final salt = base64UrlEncode(List<int>.generate(16, (_) => math.Random.secure().nextInt(256)));
    final passwordHash = await compute<List<String>, String>(_derivePasswordHash, <String>[password, salt]);
    final createdAt = DateTime.now().toIso8601String();
    final normalizedEmail = email.trim().toLowerCase();
    accounts.add(jsonEncode(<String, String>{
      'name': name.trim(),
      'email': normalizedEmail,
      'createdAt': createdAt,
      'salt': salt,
      'passwordHash': passwordHash,
    }));
    await prefs.setStringList(_accountsKey, accounts);
    await prefs.setString(sessionKey, normalizedEmail);
    return LocalProfile(name: name.trim(), email: normalizedEmail, createdAt: createdAt);
  }

  Future<LocalProfile> signIn({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final account = _findAccount(prefs.getStringList(_accountsKey) ?? <String>[], email);
    if (account == null) throw const LocalAuthException('Email atau kata sandi tidak cocok.');
    final passwordHash = await compute<List<String>, String>(
      _derivePasswordHash,
      <String>[password, account['salt'] as String],
    );
    if (!_constantTimeEquals(passwordHash, account['passwordHash'] as String)) {
      throw const LocalAuthException('Email atau kata sandi tidak cocok.');
    }
    final normalizedEmail = (account['email'] as String).toLowerCase();
    await prefs.setString(sessionKey, normalizedEmail);
    return _profileFrom(account);
  }

  Future<LocalProfile> updateName(LocalProfile profile, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList(_accountsKey) ?? <String>[];
    final index = accounts.indexWhere((record) => _decodeAccount(record)?['email'] == profile.email);
    if (index < 0) throw const LocalAuthException('Profil lokal tidak ditemukan.');
    final account = _decodeAccount(accounts[index])!..['name'] = name.trim();
    accounts[index] = jsonEncode(account);
    await prefs.setStringList(_accountsKey, accounts);
    return _profileFrom(account);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
  }

  Map<String, dynamic>? _findAccount(List<String> accounts, String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final record in accounts) {
      final account = _decodeAccount(record);
      if (account?['email'] == normalizedEmail) return account;
    }
    return null;
  }

  Map<String, dynamic>? _decodeAccount(String record) {
    try {
      return Map<String, dynamic>.from(jsonDecode(record) as Map);
    } catch (_) {
      return null;
    }
  }

  LocalProfile _profileFrom(Map<String, dynamic> account) => LocalProfile(
        name: account['name'] as String,
        email: account['email'] as String,
        createdAt: account['createdAt'] as String,
      );
}

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);
  final String message;
}

String _derivePasswordHash(List<String> arguments) {
  const int iterations = 120000;
  final passwordBytes = utf8.encode(arguments[0]);
  final salt = base64Url.decode(arguments[1]);
  final hmac = Hmac(sha256, passwordBytes);
  final firstBlock = Uint8List(salt.length + 4)..setRange(0, salt.length, salt);
  firstBlock[firstBlock.length - 1] = 1;
  var current = hmac.convert(firstBlock).bytes;
  final derived = Uint8List.fromList(current);
  for (var round = 1; round < iterations; round++) {
    current = hmac.convert(current).bytes;
    for (var index = 0; index < derived.length; index++) {
      derived[index] ^= current[index];
    }
  }
  return base64UrlEncode(derived);
}

bool _constantTimeEquals(String first, String second) {
  final firstBytes = utf8.encode(first);
  final secondBytes = utf8.encode(second);
  var difference = firstBytes.length ^ secondBytes.length;
  final length = math.max(firstBytes.length, secondBytes.length);
  for (var index = 0; index < length; index++) {
    final firstByte = index < firstBytes.length ? firstBytes[index] : 0;
    final secondByte = index < secondBytes.length ? secondBytes[index] : 0;
    difference |= firstByte ^ secondByte;
  }
  return difference == 0;
}

void main() {
  runApp(const RooveyLearnApp());
}

class RooveyLearnApp extends StatelessWidget {
  const RooveyLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accentMint,
      primary: accentMint,
      secondary: forest,
      surface: paper,
    ).copyWith(
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
    );
    return MaterialApp(
      title: 'RooveyLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: scheme,
        scaffoldBackgroundColor: sand,
        dividerColor: line,
        visualDensity: VisualDensity.standard,
        appBarTheme: const AppBarTheme(
          backgroundColor: sand,
          foregroundColor: ink,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accentMint,
            foregroundColor: forestDeep,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: forest,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: forest,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: forestDeep,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: paper,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: forest, width: 1.5)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: paper,
          indicatorColor: accentMint.withValues(alpha: 0.16),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected) ? forest : muted,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected) ? forest : muted,
              fontSize: 10,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w600,
            );
          }),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: ink,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.12,
          ),
          headlineMedium: TextStyle(
            color: ink,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          titleLarge: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w600, height: 1.25),
          titleMedium: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
          bodyLarge: TextStyle(color: ink, height: 1.45),
          bodyMedium: TextStyle(color: ink, height: 1.4),
          bodySmall: TextStyle(color: muted, height: 1.35),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const String _xpKey = 'progress_xp_v1';
  static const String _quizScoreKey = 'progress_quiz_score_v1';
  static const String _completedModulesKey = 'progress_completed_modules_v1';
  static const String _exploredTopicsKey = 'progress_explored_topics_v1';
  static const String _preTestKey = 'progress_pre_test_score_v1';
  static const String _certificateDateKey = 'certificate_issued_at_v1';
  static const String _welcomeCompletedKey = 'welcome_completed_v1';

  int _tab = 0;
  int _xp = 0;
  int? _quizScore;
  int? _preTestScore;
  LocalProfile? _profile;
  String? _certificateIssuedAt;
  bool _hasCompletedWelcome = false;
  bool _isLoadingProgress = true;
  final Set<int> _completedModules = <int>{};
  final Set<String> _exploredTopics = <String>{};
  final LocalAccountStore _accountStore = LocalAccountStore();
  Future<void> _pendingSave = Future<void>.value();

  String _progressKey(String key, [LocalProfile? profile]) {
    return profile == null ? key : '${key}_${profile.storageId}';
  }

  String? get _certificateId {
    final profile = _profile;
    final issuedAt = _certificateIssuedAt;
    if (profile == null || issuedAt == null) return null;
    final year = DateTime.tryParse(issuedAt)?.year;
    if (year == null) return null;
    return 'RLB-$year-${profile.storageId.substring(0, 8).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress({LocalProfile? profile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeProfile = profile ?? await _accountStore.currentProfile();
      final xpKey = _progressKey(_xpKey, activeProfile);
      final quizScoreKey = _progressKey(_quizScoreKey, activeProfile);
      final completedModulesKey = _progressKey(_completedModulesKey, activeProfile);
      final exploredTopicsKey = _progressKey(_exploredTopicsKey, activeProfile);
      final savedModules = prefs.getStringList(completedModulesKey) ?? <String>[];
      final savedTopics = prefs.getStringList(exploredTopicsKey) ?? <String>[];
      if (!mounted) return;
      setState(() {
        _profile = activeProfile;
        _hasCompletedWelcome = prefs.getBool(_welcomeCompletedKey) ?? activeProfile != null;
        _xp = prefs.getInt(xpKey) ?? 0;
        _quizScore = prefs.getInt(quizScoreKey);
        _preTestScore = prefs.getInt(_progressKey(_preTestKey, activeProfile));
        _certificateIssuedAt = prefs.getString(_progressKey(_certificateDateKey, activeProfile));
        _completedModules
          ..clear()
          ..addAll(savedModules.map(int.tryParse).whereType<int>().where((i) => i >= 0 && i < learningModules.length));
        _exploredTopics
          ..clear()
          ..addAll(savedTopics);
        _isLoadingProgress = false;
      });
      await _ensureCertificateIssued();
    } catch (_) {
      // If local storage is unavailable, keep the app usable for this session.
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  Future<void> _ensureCertificateIssued() async {
    final profile = _profile;
    if (profile == null || _completedModules.length != learningModules.length || (_quizScore ?? 0) < 80) return;
    await _pendingSave;
    final prefs = await SharedPreferences.getInstance();
    final key = _progressKey(_certificateDateKey, profile);
    final issuedAt = prefs.getString(key) ?? DateTime.now().toIso8601String();
    if (!prefs.containsKey(key)) await prefs.setString(key, issuedAt);
    if (mounted) setState(() => _certificateIssuedAt = issuedAt);
  }

  void _persistProgress() {
    // Capture an immutable snapshot now, then serialize writes so a slower
    // earlier write cannot overwrite a newer progress state.
    final xp = _xp;
    final quizScore = _quizScore;
    final preTestScore = _preTestScore;
    final profile = _profile;
    final xpKey = _progressKey(_xpKey, profile);
    final quizScoreKey = _progressKey(_quizScoreKey, profile);
    final preTestKey = _progressKey(_preTestKey, profile);
    final completedModulesKey = _progressKey(_completedModulesKey, profile);
    final exploredTopicsKey = _progressKey(_exploredTopicsKey, profile);
    final modules = _completedModules.map((value) => value.toString()).toList()..sort();
    final topics = _exploredTopics.toList()..sort();
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
      // Keep UI interactions available even if a device storage write fails.
      debugPrint('RooveyLearn: gagal menyimpan progres lokal: $error');
    });
  }

  Future<void> _activateProfile(LocalProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeCompletedKey, true);
    await _loadProgress(profile: profile);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openAccount() {
    final Widget screen = _profile == null
        ? LoginScreen(onAuthenticated: _activateProfile)
        : AccountProfileScreen(
            profile: _profile!,
            onNameChanged: _updateProfileName,
            onSignOut: _signOut,
          );
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RegisterScreen(onAuthenticated: _activateProfile)),
    );
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeCompletedKey, true);
    if (mounted) setState(() => _hasCompletedWelcome = true);
  }

  Future<LocalProfile> _updateProfileName(String name) async {
    final updated = await _accountStore.updateName(_profile!, name);
    if (mounted) setState(() => _profile = updated);
    return updated;
  }

  Future<void> _signOut() async {
    await _accountStore.signOut();
    await _loadProgress();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openSequenceActivity() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlantingSequenceScreen()));
  }

  void _openSequenceDiagnostic() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SequenceDiagnosticScreen()));
  }

  void _openRefractometerActivity() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RefractometerCalibrationScreen()));
  }

  void _goTo(int index) => setState(() => _tab = index);

  void _openLesson(int index) {
    final isUnlocked = _completedModules.contains(index) ||
        (index == 0 && (_preTestScore != null || _completedModules.isNotEmpty)) ||
        (index > 0 && _completedModules.contains(index - 1));
    if (!isUnlocked) return;
    final wasCompleted = _completedModules.contains(index);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
          module: learningModules[index],
          alreadyCompleted: wasCompleted,
          onComplete: () {
            setState(() {
              if (_completedModules.add(index)) _xp += 20;
            });
            _persistProgress();
            _ensureCertificateIssued();
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
              builder: (_) => ModuleCompletionScreen(
                module: learningModules[index],
                completedCount: _completedModules.length,
                xpEarned: wasCompleted ? 0 : 20,
                nextModuleTitle: index + 1 < learningModules.length ? learningModules[index + 1].title : null,
              ),
            ));
          },
        ),
      ),
    );
  }

  void _openSimulation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SimulationScreen(
          onComplete: (correct) {
            setState(() => _xp += correct ? 15 : 5);
            _persistProgress();
          },
        ),
      ),
    );
  }

  void _openPreTest() {
    if (_preTestScore != null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          isPreTest: true,
          onComplete: (score) {
            setState(() => _preTestScore = score);
            _persistProgress();
          },
        ),
      ),
    );
  }

  void _openQuiz() {
    if (_completedModules.length < learningModules.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selesaikan semua modul sebelum mengikuti kuis akhir.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          onComplete: (score) {
            setState(() {
              _quizScore = score;
              _xp += (score ~/ 10);
            });
            _persistProgress();
            _ensureCertificateIssued();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(color: forest),
              SizedBox(height: 16),
              Text('Memuat progres belajar...'),
            ],
          ),
        ),
      );
    }
    if (!_hasCompletedWelcome && _profile == null) {
      return WelcomeScreen(
        onRegister: _openRegister,
        onSignIn: _openAccount,
        onContinueAsGuest: _continueAsGuest,
      );
    }

    final pages = <Widget>[
      HomePage(
        xp: _xp,
        completedCount: _completedModules.length,
        profileName: _profile?.name,
        preTestScore: _preTestScore,
        onPreTest: _openPreTest,
        canTakeFinalQuiz: _completedModules.length == learningModules.length,
        onAccount: _openAccount,
        onExplore: () => _goTo(1),
        onLearn: () => _goTo(2),
        onQuiz: _openQuiz,
        onSimulation: _openSimulation,
      ),
      ExplorePage(
        exploredTopics: _exploredTopics,
        onTopicExplored: (id) {
          final isNewTopic = _exploredTopics.add(id);
          if (isNewTopic) _persistProgress();
          setState(() {});
        },
      ),
      LearnPage(
        completedModules: _completedModules,
        preTestScore: _preTestScore,
        canTakeFinalQuiz: _completedModules.length == learningModules.length,
        onOpenPreTest: _openPreTest,
        onOpenModule: _openLesson,
        onOpenQuiz: _openQuiz,
        onOpenSimulation: _openSimulation,
        onOpenSequence: _openSequenceActivity,
        onOpenSequenceDiagnostic: _openSequenceDiagnostic,
        onOpenRefractometer: _openRefractometerActivity,
      ),
      ProgressPage(
        xp: _xp,
        completedModules: _completedModules,
        exploredCount: _exploredTopics.length,
        quizScore: _quizScore,
        preTestScore: _preTestScore,
        profile: _profile,
        certificateId: _certificateId,
        certificateIssuedAt: _certificateIssuedAt,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: IndexedStack(index: _tab, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: paper,
        indicatorColor: accentMint.withValues(alpha: 0.16),
        height: 64,
        onDestinationSelected: _goTo,
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

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onRegister, required this.onSignIn, required this.onContinueAsGuest});

  final VoidCallback onRegister;
  final VoidCallback onSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.spa_rounded, color: forest, size: 28),
                    SizedBox(width: 9),
                    Text('ROOVEYLEARN', style: TextStyle(color: forestDeep, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const MangroveScene(height: 176, showHotspots: false, compact: true),
                ),
                const SizedBox(height: 25),
                const _Eyebrow(label: 'DIGITAL LEARNING FOR MANGROVE COMMUNITIES'),
                const SizedBox(height: 9),
                Text('Belajar untuk\npesisir tangguh.', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                const Text(
                  'Kenali ekosistem, latih keputusan lapangan, dan ikuti perkembangan belajarmu.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 23),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRegister,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Buat akun'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Masuk'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: onContinueAsGuest,
                    icon: const Icon(Icons.explore_outlined, size: 17),
                    label: const Text('Jelajah tanpa akun'),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Akun dan progres tersimpan lokal di perangkat ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef LocalProfileCallback = Future<void> Function(LocalProfile profile);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onAuthenticated});

  final LocalProfileCallback onAuthenticated;

  @override
  Widget build(BuildContext context) => _AccountFormScreen(isRegister: false, onAuthenticated: onAuthenticated);
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.onAuthenticated});

  final LocalProfileCallback onAuthenticated;

  @override
  Widget build(BuildContext context) => _AccountFormScreen(isRegister: true, onAuthenticated: onAuthenticated);
}

class _AccountFormScreen extends StatefulWidget {
  const _AccountFormScreen({required this.isRegister, required this.onAuthenticated});

  final bool isRegister;
  final LocalProfileCallback onAuthenticated;

  @override
  State<_AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<_AccountFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  final LocalAccountStore _accountStore = LocalAccountStore();
  bool _passwordVisible = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final profile = widget.isRegister
          ? await _accountStore.register(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await _accountStore.signIn(email: _emailController.text, password: _passwordController.text);
      if (mounted) await widget.onAuthenticated(profile);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = error is LocalAuthException ? error.message : 'Akun belum dapat diproses. Coba lagi.';
        });
      }
    }
  }

  void _continueWithoutAccount() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _textField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: forest, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFB85C4A))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFB85C4A), width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = widget.isRegister;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.spa_rounded, color: accentMint, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('ROOVEYLEARN', style: TextStyle(color: forestDeep, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('BELAJAR UNTUK PESISIR', style: TextStyle(color: muted, fontSize: 8, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isRegister ? 'Kembali ke masuk' : 'Lanjut tanpa akun',
                      onPressed: isRegister ? () => Navigator.of(context).maybePop() : _continueWithoutAccount,
                      icon: Icon(isRegister ? Icons.arrow_back_rounded : Icons.close_rounded, color: forest),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const MangroveScene(height: 142, showHotspots: false, compact: true),
                ),
                const SizedBox(height: 25),
                _Eyebrow(label: isRegister ? 'MULAI PERJALANANMU' : 'AKUN ROOVEYLEARN'),
                const SizedBox(height: 8),
                Text(
                  isRegister ? 'Buat akun baru.' : 'Selamat datang\nkembali.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 7),
                Text(
                  isRegister
                      ? 'Siapkan ruang untuk menyimpan perjalanan belajarmu.'
                      : 'Masuk untuk melanjutkan perjalanan menjaga pesisir.',
                  style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      if (isRegister) ...<Widget>[
                        _textField(
                          label: 'Nama lengkap',
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[AutofillHints.name],
                          validator: (value) => (value == null || value.trim().length < 2) ? 'Masukkan nama minimal 2 karakter.' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _textField(
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? null : 'Masukkan alamat email yang valid.';
                        },
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        label: 'Kata sandi',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        textInputAction: isRegister ? TextInputAction.next : TextInputAction.done,
                        autofillHints: <String>[isRegister ? AutofillHints.newPassword : AutofillHints.password],
                        obscureText: !_passwordVisible,
                        suffixIcon: IconButton(
                          tooltip: _passwordVisible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          icon: Icon(_passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                        ),
                        validator: (value) => (value == null || value.length < 8) ? 'Kata sandi minimal 8 karakter.' : null,
                      ),
                      if (isRegister) ...<Widget>[
                        const SizedBox(height: 14),
                        _textField(
                          label: 'Ulangi kata sandi',
                          icon: Icons.lock_reset_rounded,
                          controller: _confirmationController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            tooltip: _passwordVisible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            icon: Icon(_passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                          ),
                          validator: (value) => value != _passwordController.text ? 'Kata sandi belum cocok.' : null,
                        ),
                      ],
                      if (!isRegister)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kata sandi lokal tidak dapat dipulihkan. Kata sandi tidak disimpan oleh aplikasi.')),
                            ),
                            child: const Text('Lupa kata sandi?'),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(isRegister ? 'Buat akun' : 'Masuk'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(isRegister ? 'Sudah punya akun?' : 'Belum punya akun?', style: const TextStyle(color: muted, fontSize: 12)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => isRegister
                                ? LoginScreen(onAuthenticated: widget.onAuthenticated)
                                : RegisterScreen(onAuthenticated: widget.onAuthenticated),
                          ),
                        );
                      },
                      child: Text(isRegister ? 'Masuk' : 'Daftar'),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: Color(0xFF9C5143), fontSize: 12)),
                ],
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: const Color(0xFFE9EEE2), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded, color: forest, size: 18),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Akun tersimpan hanya di perangkat ini. Kata sandi tidak disimpan, dan akun tidak tersinkron ke server.',
                          style: TextStyle(color: forestDeep, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: _continueWithoutAccount,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Lanjutkan tanpa akun'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key, required this.profile, required this.onNameChanged, required this.onSignOut});

  final LocalProfile profile;
  final Future<LocalProfile> Function(String name) onNameChanged;
  final Future<void> Function() onSignOut;

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  late LocalProfile _profile = widget.profile;
  bool _isSaving = false;

  Future<void> _editName() async {
    final controller = TextEditingController(text: _profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah nama profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 2) Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final profile = await widget.onNameChanged(name);
      if (mounted) setState(() => _profile = profile);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _memberSince() {
    final date = DateTime.tryParse(_profile.createdAt)?.toLocal();
    if (date == null) return 'Tanggal tidak tersedia';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil saya')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFE8F1EC),
                      child: Text(_profile.name.isEmpty ? '?' : _profile.name[0].toUpperCase(), style: const TextStyle(color: forest, fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_profile.name, style: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(_profile.email, style: const TextStyle(color: muted, fontSize: 13)),
                          const SizedBox(height: 12),
                          Text('Bergabung $_memberSince()', style: const TextStyle(color: muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _editName,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah nama'),
              ),
              const SizedBox(height: 8),
              const _NoteCard(text: 'Profil dan progres akun ini tersimpan di perangkat ini. Akun tidak tersinkron ke server atau perangkat lain.'),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _isSaving ? null : widget.onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Content models
// -----------------------------------------------------------------------------

class LearningModule {
  const LearningModule({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.takeaway,
    required this.icon,
    required this.duration,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String title;
  final String subtitle;
  final String description;
  final String takeaway;
  final IconData icon;
  final String duration;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
}

const List<LearningModule> learningModules = <LearningModule>[
  LearningModule(
    title: 'Kenali Mangrove',
    subtitle: 'Dasar ekosistem mangrove',
    description:
        'Mangrove adalah kelompok tumbuhan yang mampu hidup di wilayah pesisir yang dipengaruhi pasang surut. Setiap jenis memiliki karakteristik dan adaptasi yang berbeda.',
    takeaway:
        'Mangrove bukan hanya pohon di tepi laut. Ia adalah bagian dari ekosistem pesisir yang saling terhubung.',
    icon: Icons.spa_rounded,
    duration: '5 menit',
    question: 'Di mana ekosistem mangrove umumnya tumbuh?',
    options: <String>[
      'Di wilayah pesisir yang dipengaruhi pasang surut',
      'Hanya di puncak gunung',
      'Di gurun tanpa air',
      'Hanya di dalam air tawar yang sangat dingin',
    ],
    correctAnswer: 0,
    explanation:
        'Benar. Mangrove beradaptasi dengan kondisi pesisir, termasuk salinitas, lumpur, dan pasang surut.',
  ),
  LearningModule(
    title: 'Mengapa Mangrove Penting?',
    subtitle: 'Peran mangrove bagi pesisir',
    description:
        'Akar mangrove membantu menahan sedimen, menyediakan tempat berlindung bagi biota, dan dapat mengurangi energi gelombang. Ekosistem ini juga menyimpan karbon dalam biomassa dan sedimennya.',
    takeaway:
        'Melindungi mangrove berarti ikut menjaga pesisir, habitat biota, dan sumber penghidupan masyarakat.',
    icon: Icons.public_rounded,
    duration: '6 menit',
    question: 'Manakah manfaat mangrove bagi kawasan pesisir?',
    options: <String>[
      'Menghilangkan semua bencana alam',
      'Menjadi habitat biota dan membantu menstabilkan sedimen',
      'Mengubah air laut menjadi air tawar',
      'Menghentikan seluruh pasang surut',
    ],
    correctAnswer: 1,
    explanation:
        'Tepat. Mangrove memberi habitat bagi beragam organisme dan membantu menstabilkan sedimen pesisir.',
  ),
  LearningModule(
    title: 'Penanaman Mangrove',
    subtitle: 'Pemulihan dan penanaman',
    description:
        'Keberhasilan rehabilitasi dimulai dari memahami kondisi lokasi. Jenis, hidrologi, substrat, pasang surut, dan kondisi vegetasi yang ada perlu dipertimbangkan sebelum menentukan teknik penanaman.',
    takeaway:
        'Jangan terburu-buru menanam. Pastikan lokasi memang sesuai dan penyebab kerusakan telah dipahami.',
    icon: Icons.grass_rounded,
    duration: '8 menit',
    question: 'Apa langkah awal sebelum melakukan penanaman?',
    options: <String>[
      'Menanam sebanyak mungkin bibit',
      'Melakukan assessment kondisi dan kesesuaian lokasi',
      'Menebang seluruh vegetasi yang ada',
      'Membuat jalur wisata lebih dahulu',
    ],
    correctAnswer: 1,
    explanation:
        'Benar. Assessment membantu menentukan apakah lokasi sesuai dan tindakan rehabilitasi apa yang diperlukan.',
  ),
  LearningModule(
    title: 'Pemeliharaan Bibit',
    subtitle: 'Perawatan bibit',
    description:
        'Penanaman bukan akhir pekerjaan. Bibit perlu diperiksa secara berkala untuk mengetahui gangguan, kerusakan, perubahan kondisi air, sampah, atau penyebab kematian.',
    takeaway:
        'Pantau penyebab masalah terlebih dahulu sebelum memutuskan perawatan atau penanaman ulang.',
    icon: Icons.volunteer_activism_rounded,
    duration: '7 menit',
    question: 'Saat menemukan bibit mati, apa tindakan yang tepat?',
    options: <String>[
      'Langsung menanam ulang tanpa pemeriksaan',
      'Mengabaikannya sampai semua bibit mati',
      'Mencatat kondisi dan mencari penyebab kematian',
      'Menyiramnya dengan air tawar setiap jam',
    ],
    correctAnswer: 2,
    explanation:
        'Tepat. Catat kondisi dan cari penyebabnya agar tindakan berikutnya lebih sesuai dengan kebutuhan lokasi.',
  ),
  LearningModule(
    title: 'Monitoring Mangrove',
    subtitle: 'Pengamatan dan evaluasi',
    description:
        'Monitoring sederhana mencatat jumlah bibit yang hidup, pertumbuhan, kondisi lingkungan, waktu pengamatan, dan lokasi. Data yang konsisten membantu masyarakat mengevaluasi hasil rehabilitasi.',
    takeaway:
        'Catatan lapangan yang konsisten membantu mengubah pengamatan menjadi dasar pengambilan keputusan.',
    icon: Icons.fact_check_rounded,
    duration: '6 menit',
    question: 'Bagaimana menghitung survival rate bibit?',
    options: <String>[
      'Bibit hidup dibagi bibit awal, lalu dikali 100%',
      'Bibit mati dibagi luas pantai',
      'Jumlah daun dikali tinggi pohon',
      'Jumlah bibit awal dikurangi jumlah pengamat',
    ],
    correctAnswer: 0,
    explanation:
        'Benar. Survival rate = jumlah bibit yang hidup ÷ jumlah bibit awal × 100%.',
  ),
];

class ExplorerTopic {
  const ExplorerTopic({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.fact,
    required this.icon,
    required this.x,
    required this.y,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;
  final String fact;
  final IconData icon;
  final double x;
  final double y;
}

const List<ExplorerTopic> explorerTopics = <ExplorerTopic>[
  ExplorerTopic(
    id: 'leaves',
    title: 'Daun Mangrove',
    tagline: 'Adaptasi di lingkungan pesisir',
    description:
        'Daun pada berbagai jenis mangrove memiliki adaptasi yang membantu tumbuhan menghadapi kondisi pesisir, termasuk paparan garam dan panas.',
    fact: 'Bentuk dan karakter daun dapat membantu proses identifikasi jenis.',
    icon: Icons.eco_rounded,
    x: 0.39,
    y: 0.28,
  ),
  ExplorerTopic(
    id: 'roots',
    title: 'Akar Mangrove',
    tagline: 'Struktur penopang kehidupan',
    description:
        'Bentuk akar berbeda menurut jenis mangrove. Akar membantu menopang tumbuhan pada substrat lunak dan menjadi ruang hidup bagi organisme kecil.',
    fact: 'Akar juga membantu memerangkap sedimen di kawasan pesisir.',
    icon: Icons.account_tree_rounded,
    x: 0.57,
    y: 0.57,
  ),
  ExplorerTopic(
    id: 'wildlife',
    title: 'Biota Pesisir',
    tagline: 'Rumah bagi kehidupan',
    description:
        'Area mangrove menjadi tempat mencari makan, berlindung, atau berkembang bagi berbagai ikan, kepiting, moluska, dan satwa lain.',
    fact: 'Jaga habitat dan hindari mengganggu satwa yang ditemukan.',
    icon: Icons.set_meal_rounded,
    x: 0.76,
    y: 0.71,
  ),
  ExplorerTopic(
    id: 'water',
    title: 'Air dan Sedimen',
    tagline: 'Fondasi ekosistem',
    description:
        'Pasang surut, aliran air, dan kondisi substrat memengaruhi jenis mangrove yang dapat tumbuh. Perubahan hidrologi bisa berdampak besar pada keberhasilan rehabilitasi.',
    fact: 'Amati pola genangan dan aliran air sebelum menentukan lokasi tanam.',
    icon: Icons.water_drop_rounded,
    x: 0.17,
    y: 0.73,
  ),
  ExplorerTopic(
    id: 'seedling',
    title: 'Bibit Mangrove',
    tagline: 'Awal dari pemulihan',
    description:
        'Bibit perlu disesuaikan dengan jenis dan kondisi lokasi. Setelah ditanam, kondisinya perlu dipantau secara berkala, bukan ditinggalkan begitu saja.',
    fact: 'Bibit yang bertahan hidup lebih penting daripada sekadar jumlah yang ditanam.',
    icon: Icons.spa_rounded,
    x: 0.88,
    y: 0.87,
  ),
];

// -----------------------------------------------------------------------------
// Home
// -----------------------------------------------------------------------------

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.xp,
    required this.completedCount,
    required this.profileName,
    required this.preTestScore,
    required this.onPreTest,
    required this.canTakeFinalQuiz,
    required this.onAccount,
    required this.onExplore,
    required this.onLearn,
    required this.onQuiz,
    required this.onSimulation,
  });

  final int xp;
  final int completedCount;
  final String? profileName;
  final int? preTestScore;
  final VoidCallback onPreTest;
  final bool canTakeFinalQuiz;
  final VoidCallback onAccount;
  final VoidCallback onExplore;
  final VoidCallback onLearn;
  final VoidCallback onQuiz;
  final VoidCallback onSimulation;

  @override
  Widget build(BuildContext context) {
    final progress = completedCount / learningModules.length;
    final firstName = profileName?.trim().split(RegExp(r'\s+')).first;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          sliver: SliverList.list(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: forest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.spa_rounded, color: accentMint, size: 27),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'ROOVEYLEARN',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.4,
                            color: forestDeep,
                          ),
                        ),
                        Text(
                          'BELAJAR UNTUK PESISIR',
                          style: TextStyle(fontSize: 9, color: muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFD8E4D6)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.bolt_rounded, color: Color(0xFFB48A23), size: 18),
                        const SizedBox(width: 4),
                        Text('$xp XP', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Profil',
                    onPressed: onAccount,
                    visualDensity: VisualDensity.compact,
                    icon: firstName == null || firstName.isEmpty
                        ? const Icon(Icons.person_outline_rounded, color: forest)
                        : CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xFFE4F0DA),
                            child: Text(firstName[0].toUpperCase(), style: const TextStyle(color: forest, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _Eyebrow(label: 'BELAJAR UNTUK PESISIR'),
              const SizedBox(height: 5),
              Text(
                firstName == null || firstName.isEmpty ? 'Halo, Penjaga Pesisir' : 'Halo, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Ekosistem sehat,\npesisir tangguh.', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text('Kenali mangrove, pahami perannya, dan dukung pemulihan pesisir.', style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 21),
              _HeroExploreCard(onTap: onExplore),
              const SizedBox(height: 16),
              _PreTestBanner(score: preTestScore, onTap: onPreTest),
              const SizedBox(height: 25),
              Row(
                children: <Widget>[
                  Expanded(child: _SectionHeading(title: 'Perjalananmu', subtitle: 'Satu langkah kecil berarti.')),
                  TextButton(onPressed: onLearn, child: const Text('Lihat modul')),
                ],
              ),
              const SizedBox(height: 9),
              _ProgressCard(progress: progress, completedCount: completedCount),
              const SizedBox(height: 25),
              const _SectionHeading(title: 'Pilih aktivitas', subtitle: 'Belajar dengan cara yang berbeda.'),
              const SizedBox(height: 13),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.explore_rounded,
                      title: 'Jelajah',
                      detail: 'Temukan rahasia mangrove',
                      tint: const Color(0xFFE1F0DB),
                      onTap: onExplore,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Simulasi',
                      detail: 'Ambil keputusan lapangan',
                      tint: const Color(0xFFDDEFF0),
                      onTap: onSimulation,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _QuizBanner(onTap: onQuiz, enabled: canTakeFinalQuiz),
              const SizedBox(height: 20),
              const Text(
                'KENALI  ·  RAWAT  ·  LINDUNGI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroExploreCard extends StatelessWidget {
  const _HeroExploreCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: forestDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 18, 4),
            child: Row(
              children: <Widget>[
                const Text('JELAJAH INTERAKTIF', style: TextStyle(color: accentMint, fontSize: 10, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.eco_outlined, color: accentMint, size: 19),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 8),
                      Text('Temui kehidupan\ndi hutan mangrove', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w600, height: 1.12)),
                      SizedBox(height: 7),
                      Text('Amati, sentuh, dan temukan.', style: TextStyle(color: Color(0xFFD1E0D4), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(backgroundColor: accentMint, foregroundColor: forestDeep, minimumSize: const Size(48, 46), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Text('Jelajah'), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16)]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          const MangroveScene(height: 158, showHotspots: false, compact: true),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.completedCount});
  final double progress;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(color: const Color(0xFFE7F0D9), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.terrain_rounded, color: forest, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Dasar Pengelolaan Mangrove', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$completedCount dari ${learningModules.length} modul selesai', style: const TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%', style: const TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 19)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: line, color: accentMint),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.detail, required this.tint, required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 42, height: 42, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: forest, size: 22)),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(detail, style: const TextStyle(fontSize: 11, color: muted, height: 1.35)),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerRight, child: Icon(Icons.arrow_forward_rounded, size: 18, color: forest)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreTestBanner extends StatelessWidget {
  const _PreTestBanner({required this.score, required this.onTap});

  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = score != null;
    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: completed ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(completed ? Icons.check_circle_rounded : Icons.assignment_outlined, size: 26, color: forest),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(completed ? 'Pre-test selesai' : 'Mulai dengan pre-test', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(
                      completed ? 'Nilai awal tersimpan: $score%' : 'Ukur pemahaman awal sebelum belajar.',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              if (!completed) const Icon(Icons.arrow_forward_rounded, color: forest, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizBanner extends StatelessWidget {
  const _QuizBanner({required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? paper : const Color(0xFFF0F0F2),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: <Widget>[
              Icon(enabled ? Icons.quiz_rounded : Icons.lock_outline_rounded, size: 28, color: enabled ? forest : muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Kuis akhir', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      enabled ? '5 pertanyaan · nilai post-test' : 'Selesaikan kelima modul untuk membuka kuis.',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              if (enabled) const Icon(Icons.chevron_right_rounded, color: forest),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive mangrove explorer
// -----------------------------------------------------------------------------

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.exploredTopics, required this.onTopicExplored});
  final Set<String> exploredTopics;
  final ValueChanged<String> onTopicExplored;

  void _showTopic(BuildContext context, ExplorerTopic topic) {
    onTopicExplored(topic.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(10))),),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFFE5F0DB), borderRadius: BorderRadius.circular(12)), child: Icon(topic.icon, size: 28, color: forest)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(topic.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)), const SizedBox(height: 3), Text(topic.tagline, style: const TextStyle(color: muted, fontSize: 12))])),
                  const Icon(Icons.check_circle_rounded, color: leaf),
                ],
              ),
              const SizedBox(height: 18),
              Text(topic.description, style: const TextStyle(fontSize: 14, height: 1.55, color: ink)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFFEAF1E3), borderRadius: BorderRadius.circular(10)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Icon(Icons.lightbulb_outline_rounded, color: forest, size: 21), const SizedBox(width: 10), Expanded(child: Text(topic.fact, style: const TextStyle(color: forestDeep, fontWeight: FontWeight.w600, height: 1.4, fontSize: 12)))]),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Lanjut menjelajah'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = exploredTopics.length;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          sliver: SliverList.list(
            children: <Widget>[
              const _Eyebrow(label: 'JELAJAH EKOSISTEM'),
              const SizedBox(height: 9),
              Text('Dengar alam\nbercerita.', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 9),
              const Text('Pilih bagian lanskap untuk mengenali fungsi mangrove dan kehidupan yang bergantung padanya.', style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: line)),
                child: Column(
                  children: <Widget>[
                    MangroveScene(height: 315, showHotspots: true, compact: false, onTopicTap: (topic) => _showTopic(context, topic)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(9, 0, 9, 8),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.touch_app_rounded, size: 19, color: forest),
                          const SizedBox(width: 7),
                          const Expanded(child: Text('Ketuk titik yang berdenyut', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Text('$count/${explorerTopics.length} ditemukan', style: const TextStyle(color: forest, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Temukan di ekosistem', subtitle: 'Objek yang pernah dibuka tetap bisa dipelajari.'),
              const SizedBox(height: 12),
              ...explorerTopics.map((topic) {
                final found = exploredTopics.contains(topic.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TopicTile(topic: topic, explored: found, onTap: () => _showTopic(context, topic)),
                );
              }),
              const SizedBox(height: 8),
              const _NoteCard(text: 'Setelah menjelajah, lanjutkan dengan simulasi agar kamu dapat mencoba mengambil keputusan untuk rehabilitasi mangrove.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.explored, required this.onTap});
  final ExplorerTopic topic;
  final bool explored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: <Widget>[
              Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFE8F0DF), borderRadius: BorderRadius.circular(10)), child: Icon(topic.icon, color: forest, size: 23)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 3), Text(topic.tagline, style: const TextStyle(color: muted, fontSize: 11))])),
              Icon(explored ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded, size: explored ? 20 : 15, color: explored ? leaf : muted),
            ],
          ),
        ),
      ),
    );
  }
}

class MangroveScene extends StatefulWidget {
  const MangroveScene({super.key, required this.height, required this.showHotspots, required this.compact, this.onTopicTap});
  final double height;
  final bool showHotspots;
  final bool compact;
  final ValueChanged<ExplorerTopic>? onTopicTap;

  @override
  State<MangroveScene> createState() => _MangroveSceneState();
}

class _MangroveSceneState extends State<MangroveScene> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _openTopic(ExplorerTopic topic) {
    widget.onTopicTap?.call(topic);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 0 : 21),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => CustomPaint(painter: MangroveScenePainter(phase: _animation.value, compact: widget.compact)),
                ),
                if (widget.showHotspots)
                  ...explorerTopics.map((topic) => Positioned(
                        left: w * topic.x - 24,
                        top: h * topic.y - 24,
                        child: _HotspotButton(icon: topic.icon, onTap: () => _openTopic(topic)),
                      )),
                if (widget.showHotspots)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(30)),
                      child: const Row(children: <Widget>[Icon(Icons.explore_rounded, color: forest, size: 14), SizedBox(width: 5), Text('TELUK MANGROVE · 01', style: TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 9))]),
                    ),
                  ),
                if (!widget.showHotspots && !widget.compact)
                  const Positioned(left: 15, bottom: 13, child: _SceneLabel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HotspotButton extends StatefulWidget {
  const _HotspotButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_HotspotButton> createState() => _HotspotButtonState();
}

class _HotspotButtonState extends State<_HotspotButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1650))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final value = _pulse.value;
          final scale = 0.78 + value * 0.48;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 42.0 * scale,
                height: 42.0 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentMint.withOpacity((1.0 - value) * 0.23),
                  border: Border.all(color: forest.withOpacity((1.0 - value) * 0.38), width: 1.2),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: paper.withOpacity(0.97),
                      border: Border.all(color: accentMint, width: 3),
                      boxShadow: <BoxShadow>[BoxShadow(color: forestDeep.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)],
                    ),
                    child: Icon(widget.icon, color: forest, size: 19),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SceneLabel extends StatelessWidget {
  const _SceneLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: forestDeep.withOpacity(0.82), borderRadius: BorderRadius.circular(14)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(Icons.waves_rounded, size: 15, color: accentMint), SizedBox(width: 6), Text('Ekosistem pesisir', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))]),
    );
  }
}

class MangroveScenePainter extends CustomPainter {
  MangroveScenePainter({required this.phase, required this.compact});
  final double phase;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.61;
    final waterTop = horizon;

    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFB8DED6), Color(0xFFEAF0D8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    final sunCenter = Offset(w * 0.83, h * 0.18);
    canvas.drawCircle(sunCenter, h * 0.105, Paint()..color = const Color(0xFFFFF4C8).withOpacity(0.32));
    canvas.drawCircle(sunCenter, h * 0.066, Paint()..color = const Color(0xFFFFF5D2));

    _drawCloud(canvas, Offset(w * (0.16 + 0.025 * math.sin(phase * math.pi * 2)), h * 0.17), w * 0.15, h * 0.055);
    _drawCloud(canvas, Offset(w * (0.53 - 0.02 * math.sin(phase * math.pi * 2)), h * 0.11), w * 0.11, h * 0.042);

    final farLand = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.18, h * 0.45, w * 0.35, h * 0.53)
      ..quadraticBezierTo(w * 0.63, h * 0.47, w * 0.78, h * 0.52)
      ..quadraticBezierTo(w * 0.91, h * 0.47, w, h * 0.51)
      ..lineTo(w, waterTop + 2)
      ..lineTo(0, waterTop + 2)
      ..close();
    canvas.drawPath(farLand, Paint()..color = const Color(0xFF719D78));

    for (int i = 0; i < 19; i++) {
      final x = w * i / 18;
      final y = h * (0.47 + 0.025 * math.sin(i * 1.9));
      final r = h * (0.035 + (i % 3) * 0.006);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = i.isEven ? const Color(0xFF3D7655) : const Color(0xFF558B61));
    }

    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF69B6B2), Color(0xFF327D82), Color(0xFF205D67)],
      ).createShader(Rect.fromLTWH(0, waterTop, w, h - waterTop));
    canvas.drawRect(Rect.fromLTWH(0, waterTop, w, h - waterTop), waterPaint);

    // Distant water reflections.
    final reflection = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < 15; i++) {
      final x = w * ((i * 0.137 + phase * 0.09) % 1.15) - w * 0.05;
      final y = waterTop + h * (0.045 + (i % 5) * 0.044);
      reflection
        ..color = const Color(0xFFD4F0D9).withOpacity(0.2 + (i % 3) * 0.06)
        ..strokeWidth = 1.2 + (i % 3) * 0.45;
      canvas.drawLine(Offset(x, y), Offset(x + w * (0.035 + (i % 2) * 0.025), y), reflection);
    }

    _drawMangrove(canvas, w * 0.18, h * 0.47, h * 0.25, w * 0.13, seed: 3, waterTop: waterTop, phase: phase);
    _drawMangrove(canvas, w * 0.57, h * 0.43, h * 0.39, w * 0.19, seed: 8, waterTop: waterTop, phase: phase);
    _drawMangrove(canvas, w * 0.9, h * 0.5, h * 0.22, w * 0.13, seed: 5, waterTop: waterTop, phase: phase);

    // Small school of fish in the shallow water.
    _drawFish(canvas, Offset(w * (0.73 + 0.02 * math.sin(phase * math.pi * 2)), h * 0.75), h * 0.028, const Color(0xFFFFD990));
    _drawFish(canvas, Offset(w * (0.82 + 0.018 * math.sin(phase * math.pi * 2 + 1)), h * 0.80), h * 0.019, const Color(0xFFE3F0D8));
    _drawFish(canvas, Offset(w * (0.3 + 0.015 * math.sin(phase * math.pi * 2 + 2)), h * 0.83), h * 0.017, const Color(0xFFFFD990));

    // A seedling near the edge of the water.
    final sx = w * 0.885;
    final sy = h * 0.91;
    final stem = Paint()..color = const Color(0xFF3D6740)..strokeWidth = math.max(1.8, w * 0.006).toDouble()..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(sx, sy), Offset(sx + w * 0.005, sy - h * 0.085), stem);
    _drawLeaf(canvas, Offset(sx - w * 0.015, sy - h * 0.06), w * 0.022, h * 0.012, -0.5, const Color(0xFFB5D66F));
    _drawLeaf(canvas, Offset(sx + w * 0.018, sy - h * 0.078), w * 0.022, h * 0.012, 0.45, const Color(0xFF91C567));

    // Small shoreline grasses.
    final grassPaint = Paint()..color = const Color(0xFF3D744A)..strokeWidth = 1.6..strokeCap = StrokeCap.round;
    for (int i = 0; i < 10; i++) {
      final gx = w * (0.02 + i * 0.025);
      final gy = waterTop + h * 0.018;
      canvas.drawLine(Offset(gx, gy), Offset(gx - w * 0.006, gy - h * (0.025 + (i % 3) * 0.008)), grassPaint);
      canvas.drawLine(Offset(gx, gy), Offset(gx + w * 0.007, gy - h * (0.021 + (i % 2) * 0.009)), grassPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, double height) {
    final paint = Paint()..color = Colors.white.withOpacity(0.56);
    canvas.drawOval(Rect.fromCenter(center: center, width: width, height: height), paint);
    canvas.drawCircle(center.translate(-width * 0.18, -height * 0.1), height * 0.58, paint);
    canvas.drawCircle(center.translate(width * 0.06, -height * 0.24), height * 0.72, paint);
    canvas.drawCircle(center.translate(width * 0.25, -height * 0.02), height * 0.48, paint);
  }

  void _drawMangrove(Canvas canvas, double x, double crownY, double trunkH, double crownW, {required int seed, required double waterTop, required double phase}) {
    final trunkBottom = waterTop + 1;
    final trunkTop = crownY + trunkH * 0.16;
    final sway = math.sin(phase * math.pi * 2 + seed) * crownW * 0.018;
    final trunk = Paint()
      ..color = const Color(0xFF695744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = crownW * 0.15
      ..strokeCap = StrokeCap.round;
    final trunkPath = Path()
      ..moveTo(x, trunkBottom)
      ..cubicTo(x - crownW * 0.08, trunkBottom - trunkH * 0.38, x + sway, trunkTop + trunkH * 0.22, x + sway * 0.55, trunkTop);
    canvas.drawPath(trunkPath, trunk);

    final branch = Paint()
      ..color = const Color(0xFF765F48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = crownW * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x + sway * 0.5, trunkTop + trunkH * 0.17), Offset(x - crownW * 0.34 + sway, crownY + trunkH * 0.03), branch);
    canvas.drawLine(Offset(x + sway * 0.5, trunkTop + trunkH * 0.11), Offset(x + crownW * 0.35 + sway, crownY + trunkH * 0.08), branch);

    final rootPaint = Paint()
      ..color = const Color(0xFF745F4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, crownW * 0.027).toDouble()
      ..strokeCap = StrokeCap.round;
    for (int i = -3; i <= 3; i++) {
      final start = Offset(x + i * crownW * 0.025, waterTop - trunkH * (0.12 + (i.abs() % 2) * 0.02));
      final end = Offset(x + i * crownW * 0.23, waterTop + trunkH * (0.24 + (i.abs() % 3) * 0.025));
      final control = Offset((start.dx + end.dx) / 2 + (i.isNegative ? -1 : 1) * crownW * 0.055, waterTop + trunkH * 0.04);
      final path = Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, rootPaint);
    }

    final leafColors = <Color>[
      const Color(0xFF235D3E),
      const Color(0xFF2F7148),
      const Color(0xFF438453),
      const Color(0xFF5A965C),
      const Color(0xFF36754B),
    ];
    final random = math.Random(seed);
    final crownCenter = Offset(x + sway, crownY + trunkH * 0.015);
    for (int i = 0; i < 31; i++) {
      final dx = (random.nextDouble() * 2 - 1) * crownW * 0.55;
      final dy = (random.nextDouble() * 2 - 1) * trunkH * 0.19;
      final radius = crownW * (0.12 + random.nextDouble() * 0.12);
      final center = crownCenter.translate(dx, dy);
      canvas.drawCircle(center, radius, Paint()..color = leafColors[i % leafColors.length]);
      if (i % 4 == 0) {
        canvas.drawCircle(center.translate(-radius * 0.2, -radius * 0.18), radius * 0.48, Paint()..color = const Color(0xFF75A962).withOpacity(0.5));
      }
    }

    // Floating prop roots are drawn in front of the waterline.
    final knees = Paint()..color = const Color(0xFF826A50)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final rx = x - crownW * 0.27 + crownW * i * 0.13;
      final ry = waterTop + trunkH * (0.08 + (i % 2) * 0.04);
      canvas.drawLine(Offset(rx, ry), Offset(rx + crownW * 0.015, ry - trunkH * 0.07), knees);
    }
  }

  void _drawLeaf(Canvas canvas, Offset center, double width, double height, double rotation, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(-width / 2, 0)
      ..quadraticBezierTo(0, -height * 1.35, width / 2, 0)
      ..quadraticBezierTo(0, height * 1.1, -width / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _drawFish(Canvas canvas, Offset center, double height, Color color) {
    final bodyPaint = Paint()..color = color.withOpacity(0.92);
    canvas.drawOval(Rect.fromCenter(center: center, width: height * 2.0, height: height), bodyPaint);
    final tail = Path()
      ..moveTo(center.dx - height * 0.8, center.dy)
      ..lineTo(center.dx - height * 1.55, center.dy - height * 0.7)
      ..lineTo(center.dx - height * 1.55, center.dy + height * 0.7)
      ..close();
    canvas.drawPath(tail, bodyPaint);
    canvas.drawCircle(Offset(center.dx + height * 0.55, center.dy - height * 0.1), math.max(0.8, height * 0.09).toDouble(), Paint()..color = forestDeep);
  }

  @override
  bool shouldRepaint(covariant MangroveScenePainter oldDelegate) => oldDelegate.phase != phase || oldDelegate.compact != compact;
}

// -----------------------------------------------------------------------------
// Learning modules and knowledge checks
// -----------------------------------------------------------------------------

class LearnPage extends StatelessWidget {
  const LearnPage({super.key, required this.completedModules, required this.preTestScore, required this.canTakeFinalQuiz, required this.onOpenPreTest, required this.onOpenModule, required this.onOpenQuiz, required this.onOpenSimulation, required this.onOpenSequence, required this.onOpenSequenceDiagnostic, required this.onOpenRefractometer});
  final Set<int> completedModules;
  final int? preTestScore;
  final bool canTakeFinalQuiz;
  final VoidCallback onOpenPreTest;
  final ValueChanged<int> onOpenModule;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenSimulation;
  final VoidCallback onOpenSequence;
  final VoidCallback onOpenSequenceDiagnostic;
  final VoidCallback onOpenRefractometer;

  @override
  Widget build(BuildContext context) {
    final done = completedModules.length;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          sliver: SliverList.list(
            children: <Widget>[
              const _Eyebrow(label: 'JALUR BELAJAR'),
              const SizedBox(height: 9),
              Text('Tumbuh bersama\nmangrove.', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 9),
              const Text('Pelajari ekosistem, praktik pemulihan, dan pemantauan melalui lima modul bertahap.', style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(color: forestDeep, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: <Widget>[
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: accentMint.withOpacity(0.16), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.route_rounded, color: accentMint, size: 26)),
                    const SizedBox(width: 13),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('DASAR PENGELOLAAN MANGROVE', style: TextStyle(color: accentMint, fontSize: 9, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text('$done dari ${learningModules.length} modul selesai', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: done / learningModules.length, minHeight: 6, color: accentMint, backgroundColor: Colors.white24))])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _PreTestBanner(score: preTestScore, onTap: onOpenPreTest),
              const SizedBox(height: 22),
              const _SectionHeading(title: 'Materi pembelajaran', subtitle: 'Modul terbuka secara berurutan setelah pre-test.'),
              const SizedBox(height: 13),
              ...List<Widget>.generate(learningModules.length, (index) {
                final completed = completedModules.contains(index);
                final unlocked = completed ||
                    (index == 0 && (preTestScore != null || completedModules.isNotEmpty)) ||
                    (index > 0 && completedModules.contains(index - 1));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _ModuleCard(
                    module: learningModules[index],
                    index: index,
                    completed: completed,
                    unlocked: unlocked,
                    onTap: unlocked ? () => onOpenModule(index) : null,
                  ),
                );
              }),
              const SizedBox(height: 8),
              _WideButton(icon: Icons.psychology_alt_rounded, title: 'Coba simulasi lapangan', subtitle: 'Latih keputusan sebelum diterapkan di lokasi', onTap: onOpenSimulation),
              const SizedBox(height: 10),
              _WideButton(icon: canTakeFinalQuiz ? Icons.quiz_rounded : Icons.lock_outline_rounded, title: 'Kuis akhir', subtitle: canTakeFinalQuiz ? 'Lima modul selesai · ukur pemahaman kembali' : 'Selesaikan semua modul untuk membuka post-test.', onTap: onOpenQuiz, enabled: canTakeFinalQuiz),
              const SizedBox(height: 25),
              const _SectionHeading(title: 'Aktivitas interaktif', subtitle: 'Latih prosedur dan pembacaan data pesisir.'),
              const SizedBox(height: 12),
              _ActivityLaunchCard(icon: Icons.reorder_rounded, title: 'Urutkan langkah penanaman', subtitle: 'Susun empat langkah kerja sesuai urutan lapangan.', tag: 'INTERAKTIF', onTap: onOpenSequence),
              const SizedBox(height: 10),
              _ActivityLaunchCard(icon: Icons.fact_check_outlined, title: 'Diagnostik urutan kerja', subtitle: 'Temukan langkah yang ditempatkan tidak sesuai prosedur.', tag: 'ANALISIS', onTap: onOpenSequenceDiagnostic),
              const SizedBox(height: 10),
              _ActivityLaunchCard(icon: Icons.tune_rounded, title: 'Kalibrasi refraktometer', subtitle: 'Atur koreksi pembacaan dan identifikasi salinitas pori.', tag: 'PENGUKURAN', onTap: onOpenRefractometer),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.index, required this.completed, required this.unlocked, required this.onTap});
  final LearningModule module;
  final int index;
  final bool completed;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: unlocked ? paper : const Color(0xFFF0F1EC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: completed ? const Color(0xFFBBD6B1) : line)),
          child: Row(
            children: <Widget>[
              Container(width: 54, height: 58, decoration: BoxDecoration(color: completed ? const Color(0xFFE1EFDA) : const Color(0xFFF0F0E6), borderRadius: BorderRadius.circular(10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Icon(completed ? Icons.check_circle_rounded : unlocked ? module.icon : Icons.lock_outline_rounded, color: unlocked ? forest : muted, size: 23), const SizedBox(height: 4), Text('0${index + 1}', style: const TextStyle(fontSize: 9, color: muted, fontWeight: FontWeight.w600))])),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(module.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: unlocked ? ink : muted)), const SizedBox(height: 3), Text(module.subtitle, style: const TextStyle(color: muted, fontSize: 10.5)), const SizedBox(height: 7), Row(children: <Widget>[const Icon(Icons.schedule_rounded, size: 13, color: muted), const SizedBox(width: 3), Text(module.duration, style: const TextStyle(color: muted, fontSize: 10)), if (completed) ...<Widget>[const SizedBox(width: 9), const Icon(Icons.verified_rounded, size: 13, color: leaf), const SizedBox(width: 3), const Text('Selesai', style: TextStyle(color: leaf, fontSize: 10, fontWeight: FontWeight.w600))] else if (!unlocked) ...<Widget>[const SizedBox(width: 8), const Text('Terkunci', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600))]])])),
              const SizedBox(width: 8),
              Icon(unlocked ? Icons.chevron_right_rounded : Icons.lock_outline_rounded, color: muted, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.module, required this.alreadyCompleted, required this.onComplete});
  final LearningModule module;
  final bool alreadyCompleted;
  final VoidCallback onComplete;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final isCorrect = _selectedAnswer == module.correctAnswer;
    return Scaffold(
      appBar: AppBar(title: const Text('Modul belajar', style: TextStyle(fontWeight: FontWeight.w600)), actions: <Widget>[Container(margin: const EdgeInsets.only(right: 18), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE3EFD9), borderRadius: BorderRadius.circular(9)), child: const Text('+20 XP', style: TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 11)))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: <Widget>[
          const _Eyebrow(label: 'PELAJARI · AMATI · TERAPKAN'),
          const SizedBox(height: 8),
          Text(module.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 5),
          Text(module.subtitle, style: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
            child: const MangroveScene(height: 195, showHotspots: false, compact: false),
          ),
          const SizedBox(height: 20),
          const _Eyebrow(label: '01 · PAHAMI'),
          const SizedBox(height: 7),
          Text(module.description, style: const TextStyle(color: ink, fontSize: 14, height: 1.6)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE7F0DF), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Icon(Icons.spa_rounded, size: 23, color: forest), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Ingat poin ini', style: TextStyle(color: forest, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text(module.takeaway, style: const TextStyle(color: forestDeep, fontSize: 12, height: 1.5))]))]),
          ),
          const SizedBox(height: 23),
          const _Eyebrow(label: '02 · UJI PEMAHAMAN'),
          const SizedBox(height: 7),
          Text(module.question, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 13),
          ...List<Widget>.generate(module.options.length, (index) {
            final selected = _selectedAnswer == index;
            final reveal = _selectedAnswer != null;
            final correctOption = reveal && index == module.correctAnswer;
            Color borderColor = line;
            Color tileColor = paper;
            if (correctOption) {
              borderColor = leaf;
              tileColor = const Color(0xFFE8F2E2);
            } else if (selected && !isCorrect) {
              borderColor = const Color(0xFFD98A65);
              tileColor = const Color(0xFFFFF0E9);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: reveal ? null : () => setState(() => _selectedAnswer = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: correctOption || selected ? 1.5 : 1)),
                  child: Row(children: <Widget>[Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: correctOption ? leaf : const Color(0xFFF0F0E8), shape: BoxShape.circle), child: correctOption ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : Text(String.fromCharCode(65 + index), style: const TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 11))), const SizedBox(width: 10), Expanded(child: Text(module.options[index], style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600)))]),
                ),
              ),
            );
          }),
          if (_selectedAnswer != null) ...<Widget>[
            const SizedBox(height: 4),
            _FeedbackCard(correct: isCorrect, message: isCorrect ? module.explanation : 'Belum tepat. Coba tinjau kembali materi lalu pilih jawaban lain.'),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: isCorrect ? widget.onComplete : () => setState(() => _selectedAnswer = null), child: Text(isCorrect ? (widget.alreadyCompleted ? 'Selesai · kembali ke jalur' : 'Selesaikan modul · +20 XP') : 'Coba lagi'))),
          ],
          if (_selectedAnswer == null) ...<Widget>[
            const SizedBox(height: 5),
            const Text('Pilih satu jawaban untuk melihat penjelasan dan menyelesaikan materi.', style: TextStyle(color: muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Decision simulation
// -----------------------------------------------------------------------------

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key, required this.onComplete});
  final ValueChanged<bool> onComplete;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  int? _choice;
  bool _rewarded = false;
  final List<String> _options = const <String>[
    'Langsung menanam sebanyak mungkin bibit.',
    'Melakukan assessment kondisi dan kesesuaian lokasi.',
    'Menebang seluruh vegetasi agar area terlihat bersih.',
    'Membuat jalur wisata sebelum memeriksa lokasi.',
  ];

  @override
  Widget build(BuildContext context) {
    final answered = _choice != null;
    final correct = _choice == 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi lapangan', style: TextStyle(fontWeight: FontWeight.w600))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: <Widget>[
          const _Eyebrow(label: 'KAMU ADALAH PENGELOLA MANGROVE'),
          const SizedBox(height: 8),
          Text('Keputusanmu\nberarti.', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Latih pengambilan keputusan sebelum menerapkannya di lapangan.', style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const MangroveScene(height: 180, showHotspots: false, compact: false), Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const _Eyebrow(label: 'SKENARIO 01'), const SizedBox(height: 7), const Text('Sebuah kawasan pesisir akan direhabilitasi. Kamu diminta mengoordinasikan langkah pertama tim.', style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w600)), const SizedBox(height: 8), const Text('Apa yang sebaiknya dilakukan terlebih dahulu?', style: TextStyle(color: muted, fontSize: 12))]))]),
          ),
          const SizedBox(height: 18),
          ...List<Widget>.generate(_options.length, (index) {
            final selected = _choice == index;
            final right = answered && index == 1;
            final wrongSelected = selected && !correct;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: answered ? null : () => setState(() => _choice = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: right ? const Color(0xFFE5F2DF) : wrongSelected ? const Color(0xFFFFF0E8) : paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: right ? leaf : wrongSelected ? const Color(0xFFD98A65) : line, width: right || wrongSelected ? 1.5 : 1)),
                  child: Row(children: <Widget>[Container(width: 31, height: 31, alignment: Alignment.center, decoration: BoxDecoration(color: right ? leaf : const Color(0xFFECEFE5), shape: BoxShape.circle), child: right ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : Text(String.fromCharCode(65 + index), style: const TextStyle(fontWeight: FontWeight.w600, color: forest))), const SizedBox(width: 12), Expanded(child: Text(_options[index], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.4)))]),
                ),
              ),
            );
          }),
          if (answered) ...<Widget>[
            const SizedBox(height: 3),
            _FeedbackCard(correct: correct, message: correct ? 'Tepat. Assessment membantu memahami hidrologi, substrat, pasang surut, dan kondisi vegetasi sebelum memilih tindakan rehabilitasi.' : 'Belum tepat. Penanaman yang berhasil dimulai dengan memahami penyebab kerusakan dan kesesuaian lokasi.'),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (!_rewarded) { widget.onComplete(correct); _rewarded = true; } Navigator.of(context).pop(); }, child: Text(correct ? 'Simpan hasil  +15 XP' : 'Selesai simulasi  +5 XP'))),
            const SizedBox(height: 9),
            const Text('Catatan: simulasi ini untuk pembelajaran dasar. Keputusan lapangan perlu mempertimbangkan panduan teknis dan kondisi lokal.', style: TextStyle(color: muted, fontSize: 10.5, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Quiz
// -----------------------------------------------------------------------------

class QuizQuestion {
  const QuizQuestion({required this.question, required this.answers, required this.correct, required this.explanation});
  final String question;
  final List<String> answers;
  final int correct;
  final String explanation;
}

const List<QuizQuestion> quizQuestions = <QuizQuestion>[
  QuizQuestion(question: 'Apa yang membuat mangrove penting bagi ekosistem pesisir?', answers: <String>['Hanya memperindah pemandangan', 'Menyediakan habitat dan membantu menstabilkan sedimen', 'Menghilangkan seluruh gelombang laut', 'Mengubah air laut menjadi air tawar'], correct: 1, explanation: 'Mangrove mendukung habitat biota dan membantu menahan sedimen.'),
  QuizQuestion(question: 'Apa yang sebaiknya diperiksa sebelum rehabilitasi?', answers: <String>['Warna seragam relawan', 'Jumlah bibit sebanyak-banyaknya', 'Kesesuaian lokasi dan kondisi hidrologi', 'Desain spanduk kegiatan'], correct: 2, explanation: 'Kondisi lokasi menentukan jenis dan tindakan yang sesuai.'),
  QuizQuestion(question: 'Apa tindakan yang tepat saat banyak bibit mati?', answers: <String>['Catat kondisi lalu cari penyebabnya', 'Tanam ulang tanpa memeriksa', 'Berhenti melakukan monitoring', 'Pindahkan semua bibit ke laut dalam'], correct: 0, explanation: 'Mengetahui penyebab membantu tim memilih tindakan perbaikan.'),
  QuizQuestion(question: 'Survival rate menunjukkan ...', answers: <String>['Jumlah jenis ikan yang terlihat', 'Tinggi pasang tertinggi', 'Jumlah relawan yang hadir', 'Persentase bibit yang bertahan hidup'], correct: 3, explanation: 'Survival rate adalah proporsi bibit hidup dibanding jumlah bibit awal.'),
  QuizQuestion(question: 'Apa manfaat monitoring yang konsisten?', answers: <String>['Menghilangkan kebutuhan merawat bibit', 'Membantu mengevaluasi pertumbuhan dan hasil rehabilitasi', 'Menjamin semua bibit tumbuh tanpa risiko', 'Menggantikan semua observasi lapangan'], correct: 1, explanation: 'Data pengamatan yang konsisten mendukung evaluasi dan keputusan selanjutnya.'),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.onComplete, this.isPreTest = false});
  final ValueChanged<int> onComplete;
  final bool isPreTest;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _finished = false;
  bool _saved = false;

  void _next() {
    final current = quizQuestions[_index];
    if (_selected == current.correct) _score += 1;
    if (_index == quizQuestions.length - 1) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _index += 1;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _QuizResultScreen(score: _score, isPreTest: widget.isPreTest, onComplete: () { if (!_saved) { widget.onComplete((_score / quizQuestions.length * 100).round()); _saved = true; } Navigator.of(context).pop(); });
    final question = quizQuestions[_index];
    final answered = _selected != null;
    final correct = _selected == question.correct;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isPreTest ? 'Pre-test mangrove' : 'Post-test mangrove', style: const TextStyle(fontWeight: FontWeight.w600)), actions: <Widget>[Padding(padding: const EdgeInsets.only(right: 20), child: Center(child: Text('${_index + 1} dari ${quizQuestions.length}', style: const TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12))))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        children: <Widget>[
          _Eyebrow(label: widget.isPreTest ? 'TES AWAL' : 'PENILAIAN AKHIR'),
          const SizedBox(height: 8),
          Text(widget.isPreTest ? 'Catat pemahaman awal.' : 'Uji pemahamanmu.', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 17),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (_index + (answered ? 1 : 0)) / quizQuestions.length, color: accentMint, backgroundColor: line, minHeight: 7)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(color: forestDeep, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text('PERTANYAAN 0${_index + 1}', style: const TextStyle(color: accentMint, fontSize: 10, fontWeight: FontWeight.w600)), const SizedBox(height: 12), Text(question.question, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600, height: 1.25)), const SizedBox(height: 15), const Row(children: <Widget>[Icon(Icons.eco_rounded, color: accentMint, size: 19), SizedBox(width: 7), Text('Pilih satu jawaban paling tepat', style: TextStyle(color: Color(0xFFD4E2D6), fontSize: 11))])]),
          ),
          const SizedBox(height: 20),
          ...List<Widget>.generate(question.answers.length, (index) {
            final selected = _selected == index;
            final right = answered && index == question.correct;
            final wrong = selected && !correct;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: answered ? null : () => setState(() => _selected = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: right ? const Color(0xFFE7F1E1) : wrong ? const Color(0xFFFFEFE7) : paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: right ? leaf : wrong ? const Color(0xFFD98A65) : line, width: right || wrong ? 1.5 : 1)),
                  child: Row(children: <Widget>[Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: right ? leaf : const Color(0xFFECEFE5)), child: right ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : Text(String.fromCharCode(65 + index), style: const TextStyle(color: forest, fontWeight: FontWeight.w600))), const SizedBox(width: 11), Expanded(child: Text(question.answers[index], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35)))]),
                ),
              ),
            );
          }),
          if (answered) ...<Widget>[
            const SizedBox(height: 3),
            _FeedbackCard(correct: correct, message: question.explanation),
            const SizedBox(height: 17),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(_index == quizQuestions.length - 1 ? 'Lihat hasil' : 'Pertanyaan berikutnya'))),
          ] else ...<Widget>[
            const SizedBox(height: 7),
            const Text('Setiap jawaban dilengkapi penjelasan agar konsepnya mudah dipahami.', style: TextStyle(fontSize: 11, color: muted)),
          ],
        ],
      ),
    );
  }
}

class _QuizResultScreen extends StatelessWidget {
  const _QuizResultScreen({required this.score, required this.isPreTest, required this.onComplete});
  final int score;
  final bool isPreTest;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final percentage = (score / quizQuestions.length * 100).round();
    final passed = percentage >= 80;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(width: 104, height: 104, decoration: BoxDecoration(color: const Color(0xFFE4F0D9), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFC5DDAE), width: 5)), child: Icon(passed ? Icons.emoji_events_rounded : Icons.spa_rounded, color: forest, size: 52)),
                const SizedBox(height: 25),
                _Eyebrow(label: isPreTest ? 'PRE-TEST SELESAI' : 'POST-TEST SELESAI'),
                const SizedBox(height: 9),
                Text(isPreTest ? 'Nilai awal tersimpan.' : passed ? 'Pemahamanmu semakin kuat.' : 'Terus bertumbuh.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 9),
                Text(isPreTest ? 'Hasil ini menjadi acuan sebelum perjalanan belajar dimulai.' : passed ? 'Kamu telah menuntaskan kuis dasar pengelolaan mangrove.' : 'Tinjau kembali materi, lalu coba lagi. Setiap langkah belajar berarti.', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 24),
                Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)), child: Column(children: <Widget>[Text('$percentage%', style: const TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 47)), const SizedBox(height: 3), Text('$score dari ${quizQuestions.length} jawaban benar', style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 15), ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: percentage / 100, minHeight: 8, color: accentMint, backgroundColor: line)), const SizedBox(height: 13), Text(isPreTest ? 'SKOR AWAL · TANPA XP' : passed ? 'TARGET TERCAPAI · +${percentage ~/ 10} XP' : 'TARGET NILAI: 80%', style: const TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 10))])),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: onComplete, child: Text(isPreTest ? 'Mulai perjalanan belajar' : 'Simpan hasil & kembali'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Module completion feedback
// -----------------------------------------------------------------------------

class ModuleCompletionScreen extends StatelessWidget {
  const ModuleCompletionScreen({super.key, required this.module, required this.completedCount, required this.xpEarned, required this.nextModuleTitle});
  final LearningModule module;
  final int completedCount;
  final int xpEarned;
  final String? nextModuleTitle;

  @override
  Widget build(BuildContext context) {
    final progress = completedCount / learningModules.length;
    return Scaffold(
      backgroundColor: sand,
      appBar: AppBar(leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)), title: const Text('Modul selesai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: <Widget>[
        const SizedBox(height: 14),
        Center(child: Container(width: 76, height: 76, decoration: const BoxDecoration(color: Color(0xFFE7F0EC), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: forest, size: 44))),
        const SizedBox(height: 18),
        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFE7F0EC), borderRadius: BorderRadius.circular(9)), child: const Text('MATERI SELESAI', style: TextStyle(color: forest, fontSize: 9, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 12),
        Text(module.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(xpEarned > 0 ? 'Pemahamanmu bertambah. Satu langkah lagi menuju pengelolaan mangrove yang lebih baik.' : 'Kamu telah meninjau kembali materi yang sudah diselesaikan.', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 22),
        Container(padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 12), decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)), child: Row(children: <Widget>[
          Expanded(child: Column(children: <Widget>[Text(xpEarned > 0 ? '+$xpEarned' : '+0', style: const TextStyle(color: forest, fontSize: 24, fontWeight: FontWeight.w600)), const SizedBox(height: 3), const Text('XP DIDAPAT', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w600))])),
          Container(width: 1, height: 38, color: line),
          Expanded(child: Column(children: <Widget>[Text('$completedCount / ${learningModules.length}', style: const TextStyle(color: forest, fontSize: 24, fontWeight: FontWeight.w600)), const SizedBox(height: 3), const Text('MODUL SELESAI', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w600))])),
          Container(width: 1, height: 38, color: line),
          Expanded(child: Column(children: <Widget>[Text('${(progress * 100).round()}%', style: const TextStyle(color: forest, fontSize: 24, fontWeight: FontWeight.w600)), const SizedBox(height: 3), const Text('PROGRES JALUR', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w600))])),
        ])),
        const SizedBox(height: 17),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)), child: Row(children: <Widget>[Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFE7F0EC), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.tune_rounded, color: forest, size: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('LANGKAH BERIKUTNYA', style: TextStyle(color: forest, fontSize: 9, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text(nextModuleTitle == null ? 'Kamu telah mencapai modul terakhir.' : 'Berikutnya: $nextModuleTitle', style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Lanjutkan belajar dari tab Belajar.', style: TextStyle(color: muted, fontSize: 10.5, height: 1.35))]))])),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Lanjutkan belajar'))),
        const SizedBox(height: 5),
        Center(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kembali ke materi'))),
      ])),
    );
  }
}

// -----------------------------------------------------------------------------
// Stitch-inspired field activities: sequencing, diagnosis, refractometer
// -----------------------------------------------------------------------------

class _ActivityLaunchCard extends StatelessWidget {
  const _ActivityLaunchCard({required this.icon, required this.title, required this.subtitle, required this.tag, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
          child: Row(children: <Widget>[
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE7F0EC), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: forest, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: muted, fontSize: 11.5, height: 1.4)),
              const SizedBox(height: 7),
              Text(tag, style: const TextStyle(color: forest, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: muted),
          ]),
        ),
      ),
    );
  }
}

class _FieldActivityScaffold extends StatelessWidget {
  const _FieldActivityScaffold({required this.title, required this.stepLabel, required this.progress, required this.child, this.bottom});
  final String title;
  final String stepLabel;
  final double progress;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).maybePop()),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        actions: const <Widget>[Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.eco_outlined, color: forest, size: 21))],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: <Widget>[
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[Expanded(child: Text(stepLabel.toUpperCase(), style: const TextStyle(color: forest, fontSize: 9, fontWeight: FontWeight.w600))), const Text('PROTOKOL LAPANGAN', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 9),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: line, color: accentMint)),
          ])),
          Expanded(child: child),
          if (bottom != null) SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 12), child: bottom!)),
        ]),
      ),
    );
  }
}

class _ProtocolStep {
  const _ProtocolStep(this.id, this.title, this.description);
  final int id;
  final String title;
  final String description;
}

const List<_ProtocolStep> _correctPlantingSteps = <_ProtocolStep>[
  _ProtocolStep(0, 'Analisis elevasi substrat dan rentang pasang', 'Tandai acuan pasang purnama rata-rata dan tentukan jendela pasang yang sesuai.'),
  _ProtocolStep(1, 'Gali lubang tanam sedalam akar propagul', 'Siapkan lubang tanam tanpa mengganggu substrat minim oksigen di sekitarnya.'),
  _ProtocolStep(2, 'Ikat propagul dengan ajir bambu belah', 'Tahan propagul dari arus balik menggunakan penyangga yang dapat terurai.'),
  _ProtocolStep(3, 'Catat salinitas awal air pori pascatanam', 'Simpan pembacaan awal salinitas untuk pemantauan berikutnya.'),
];

class PlantingSequenceScreen extends StatefulWidget {
  const PlantingSequenceScreen({super.key});
  @override
  State<PlantingSequenceScreen> createState() => _PlantingSequenceScreenState();
}

class _PlantingSequenceScreenState extends State<PlantingSequenceScreen> {
  late List<_ProtocolStep> _steps;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _steps = <_ProtocolStep>[_correctPlantingSteps[2], _correctPlantingSteps[0], _correctPlantingSteps[3], _correctPlantingSteps[1]];
  }

  void _checkSequence() {
    final correct = List<int>.generate(_steps.length, (index) => _steps[index].id).join(',') == '0,1,2,3';
    setState(() => _isCorrect = correct);
  }

  @override
  Widget build(BuildContext context) {
    return _FieldActivityScaffold(
      title: 'Urutan penanaman', stepLabel: 'Langkah 4 dari 5 · Susun urutan', progress: 0.8,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _checkSequence, icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Periksa urutan'))),
        const SizedBox(height: 4),
        TextButton.icon(onPressed: () => setState(() { _steps = <_ProtocolStep>[_correctPlantingSteps[2], _correctPlantingSteps[0], _correctPlantingSteps[3], _correctPlantingSteps[1]]; _isCorrect = null; }), icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Ulangi susunan')),
      ]),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 18), children: <Widget>[
        const Text('Susun empat langkah penanaman di zona pasang surut.', style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w600, height: 1.22)),
        const SizedBox(height: 8),
        const Text('Siapkan lokasi dan substrat sebelum memasang propagul.', style: TextStyle(color: muted, fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE7F0EC), borderRadius: BorderRadius.circular(10)), child: const Row(children: <Widget>[Icon(Icons.water_drop_outlined, color: forest, size: 19), SizedBox(width: 9), Expanded(child: Text('JENDELA IDEAL  ·  Surut terendah (0–0,4 m)', style: TextStyle(color: forestDeep, fontSize: 10, fontWeight: FontWeight.w600)))])),
        const SizedBox(height: 14),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _steps.length,
          onReorderItem: (oldIndex, newIndex) => setState(() { final item = _steps.removeAt(oldIndex); _steps.insert(newIndex, item); _isCorrect = null; }),
          itemBuilder: (context, index) {
            final step = _steps[index];
            final correctOrder = _isCorrect == true;
            return Container(
              key: ValueKey<int>(step.id),
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: correctOrder ? const Color(0xFFE7F0EC) : paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: correctOrder ? forest : line)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Container(width: 27, height: 27, alignment: Alignment.center, decoration: BoxDecoration(color: correctOrder ? forest : const Color(0xFFE7F0EC), shape: BoxShape.circle), child: Text('${index + 1}', style: TextStyle(color: correctOrder ? Colors.white : forest, fontSize: 11, fontWeight: FontWeight.w600))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(step.title, style: const TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600, height: 1.35)), const SizedBox(height: 4), Text(step.description, style: const TextStyle(color: muted, fontSize: 10.5, height: 1.35))])),
                ReorderableDragStartListener(index: index, child: const Padding(padding: EdgeInsets.only(left: 7, top: 4), child: Icon(Icons.drag_indicator_rounded, color: muted, size: 20))),
              ]),
            );
          },
        ),
        if (_isCorrect != null) ...<Widget>[
          const SizedBox(height: 3),
          _FeedbackCard(correct: _isCorrect!, message: _isCorrect! ? 'Urutan tepat. Periksa lokasi dan siapkan substrat sebelum menanam; catat salinitas dasar setelah propagul terpasang.' : 'Masih ada langkah yang tertukar. Siapkan lokasi dan lubang tanam sebelum memasang propagul, lalu catat salinitas setelah penanaman.'),
          if (_isCorrect!) ...<Widget>[const SizedBox(height: 10), OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SequenceDiagnosticScreen())), icon: const Icon(Icons.fact_check_outlined), label: const Text('Lanjut ke diagnostik urutan'))],
        ],
      ]),
    );
  }
}

class SequenceDiagnosticScreen extends StatefulWidget {
  const SequenceDiagnosticScreen({super.key});
  @override
  State<SequenceDiagnosticScreen> createState() => _SequenceDiagnosticScreenState();
}

class _SequenceDiagnosticScreenState extends State<SequenceDiagnosticScreen> {
  final Set<int> _selectedPositions = <int>{};
  bool _checked = false;
  static const List<String> _diagnosticSteps = <String>[
    'Analisis elevasi substrat dan rentang pasang',
    'Catat salinitas awal air pori pascatanam',
    'Pasang ajir bambu untuk meredam arus gelombang',
    'Gali lubang tanam dan siapkan pengikat propagul',
  ];
  static const Set<int> _misplacedPositions = <int>{1, 3};

  void _check() => setState(() => _checked = true);

  @override
  Widget build(BuildContext context) {
    final correct = _selectedPositions.length == _misplacedPositions.length && _selectedPositions.containsAll(_misplacedPositions);
    return _FieldActivityScaffold(
      title: 'Diagnostik urutan', stepLabel: 'Langkah 5 dari 5 · Protokol lapangan', progress: 1,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _check, icon: const Icon(Icons.rule_rounded), label: const Text('Periksa jawaban'))),
        TextButton(onPressed: () => setState(() { _selectedPositions.clear(); _checked = false; }), child: const Text('Hapus pilihan')),
      ]),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 18), children: <Widget>[
        const Text('Urutan kerja memengaruhi kestabilan tanam.', style: TextStyle(fontSize: 21, color: ink, fontWeight: FontWeight.w600, height: 1.2)),
        const SizedBox(height: 7),
        const Text('Dua langkah berada di posisi yang keliru. Pilih semua langkah yang perlu dipindahkan, lalu periksa jawabanmu.', style: TextStyle(color: muted, fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 16),
        ...List<Widget>.generate(_diagnosticSteps.length, (index) {
          final selected = _selectedPositions.contains(index);
          final misplaced = _misplacedPositions.contains(index);
          final reveal = _checked;
          final correctMark = reveal && !misplaced;
          final wrongMark = reveal && misplaced;
          return Padding(padding: const EdgeInsets.only(bottom: 9), child: InkWell(
            onTap: _checked ? null : () => setState(() { if (selected) { _selectedPositions.remove(index); } else { _selectedPositions.add(index); } }),
            borderRadius: BorderRadius.circular(10),
            child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: wrongMark ? const Color(0xFFFFF0EC) : correctMark ? const Color(0xFFE7F0EC) : selected ? const Color(0xFFE7F0EC) : paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: wrongMark ? const Color(0xFFCB7869) : correctMark ? forest : selected ? forest : line, width: selected || reveal ? 1.3 : 1)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Container(width: 27, height: 27, alignment: Alignment.center, decoration: BoxDecoration(color: wrongMark ? const Color(0xFFB85C4A) : correctMark ? forest : const Color(0xFFE7F0EC), shape: BoxShape.circle), child: reveal ? Icon(wrongMark ? Icons.priority_high_rounded : Icons.check_rounded, color: Colors.white, size: 16) : Text('${index + 1}', style: const TextStyle(color: forest, fontWeight: FontWeight.w600, fontSize: 11))),
                const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(_diagnosticSteps[index], style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600, height: 1.35)), if (reveal && misplaced) ...<Widget>[const SizedBox(height: 6), Text(index == 1 ? 'Pindahkan ke setelah penanaman: salinitas dasar dicatat setelah propagul terpasang.' : 'Pindahkan sebelum memasang ajir: lubang tanam perlu disiapkan lebih dahulu.', style: const TextStyle(color: Color(0xFF9C5143), fontSize: 10.5, height: 1.4))]])),
                if (!_checked) Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: selected ? forest : muted, size: 20),
              ]),
            ),
          ));
        }),
        if (_checked) ...<Widget>[const SizedBox(height: 3), _FeedbackCard(correct: correct, message: correct ? 'Tepat. Salinitas dasar dicatat setelah penanaman, sedangkan lubang tanam perlu disiapkan sebelum memasang ajir.' : 'Belum tepat. Pilih pencatatan salinitas pascatanam dan persiapan lubang tanam sebelum pemasangan ajir.')],
      ]),
    );
  }
}

class RefractometerCalibrationScreen extends StatefulWidget {
  const RefractometerCalibrationScreen({super.key});
  @override
  State<RefractometerCalibrationScreen> createState() => _RefractometerCalibrationScreenState();
}

class _RefractometerCalibrationScreenState extends State<RefractometerCalibrationScreen> {
  double _offset = 0;
  int? _selectedReading;
  bool _confirmed = false;
  static const List<int> _readings = <int>[24, 32, 38, 45];

  @override
  Widget build(BuildContext context) {
    final correctedReading = 35 + _offset.round();
    final isCorrect = correctedReading == 32 && _selectedReading == 32;
    return _FieldActivityScaffold(
      title: 'Kalibrasi refraktometer', stepLabel: 'Unit 3 · Ukur air pori', progress: 0.72,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _selectedReading == null ? null : () => setState(() => _confirmed = true), icon: const Icon(Icons.verified_outlined), label: const Text('Konfirmasi salinitas'))),
        TextButton(onPressed: () => setState(() { _offset = 0; _selectedReading = null; _confirmed = false; }), child: const Text('Atur ulang kalibrasi')),
      ]),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 18), children: <Widget>[
        const Text('Kalibrasi dan baca refraktometer', style: TextStyle(fontSize: 21, color: ink, fontWeight: FontWeight.w600, height: 1.2)),
        const SizedBox(height: 7),
        const Text('Atur koreksi kalibrasi, lalu pilih pembacaan salinitas air pori yang sesuai.', style: TextStyle(color: muted, fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 17),
        Center(child: Container(width: 204, height: 204, decoration: BoxDecoration(shape: BoxShape.circle, color: forestDeep, border: Border.all(color: const Color(0xFFB8D0C8), width: 5)), child: Container(margin: const EdgeInsets.all(11), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF145B56), Color(0xFF203A38), Color(0xFFF7F6F0), Color(0xFFFFFFFF)], stops: <double>[0, .45, .46, 1]), border: Border.all(color: const Color(0xFF9ABAB2), width: 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: accentMint, borderRadius: BorderRadius.circular(4)), child: const Text('AIR PORI', style: TextStyle(color: forestDeep, fontSize: 8, fontWeight: FontWeight.w600)),), const SizedBox(height: 8), Text('$correctedReading', style: const TextStyle(color: forestDeep, fontSize: 35, fontWeight: FontWeight.w600, height: 1)), const Text('PSU', style: TextStyle(color: forestDeep, fontSize: 11, fontWeight: FontWeight.w600)), const SizedBox(height: 5), const Text('HASIL TERKOREKSI', style: TextStyle(color: forestDeep, fontSize: 7, fontWeight: FontWeight.w600))])))),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[const Expanded(child: Text('Koreksi kalibrasi', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),), Text('${_offset >= 0 ? '+' : ''}${_offset.toStringAsFixed(0)} PSU', style: const TextStyle(color: forest, fontSize: 13, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 4),
          const Text('Sesuaikan hingga sampel menunjukkan 32 PSU.', style: TextStyle(color: muted, fontSize: 11)),
          Slider(value: _offset, min: -5, max: 5, divisions: 10, label: '${_offset >= 0 ? '+' : ''}${_offset.toStringAsFixed(0)} PSU', onChanged: (value) => setState(() { _offset = value; _confirmed = false; })),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const <Widget>[Text('−5 PSU', style: TextStyle(color: muted, fontSize: 9)), Text('0', style: TextStyle(color: muted, fontSize: 9)), Text('+5 PSU', style: TextStyle(color: muted, fontSize: 9))]),
        ])),
        const SizedBox(height: 17),
        const Text('Pilih hasil pembacaan', style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._readings.map((reading) {
          final selected = _selectedReading == reading;
          final correctChoice = _confirmed && reading == 32;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(onTap: () => setState(() { _selectedReading = reading; _confirmed = false; }), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12), decoration: BoxDecoration(color: selected ? const Color(0xFFE7F0EC) : paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? forest : line, width: selected ? 1.4 : 1)), child: Row(children: <Widget>[Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? forest : muted, size: 19), const SizedBox(width: 10), Expanded(child: Text('$reading PSU', style: const TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w600))), if (correctChoice) const Icon(Icons.check_circle_rounded, color: forest, size: 18)]))));
        }),
        if (_confirmed) ...<Widget>[const SizedBox(height: 3), _FeedbackCard(correct: isCorrect, message: isCorrect ? 'Reading cocok dengan offset kalibrasi. Nilai 32 PSU berada pada rentang yang dipakai dalam skenario pembelajaran ini untuk contoh lokasi Rhizophora.' : 'Pembacaan belum cocok. Sesuaikan offset sampai tampilan terkoreksi menjadi 32 PSU, lalu pilih 32 PSU sebagai hasil pengamatan.')],
        const SizedBox(height: 8),
        const _NoteCard(text: 'Simulasi edukatif: angka awal 35 PSU dan target 32 PSU merupakan skenario latihan, bukan hasil pengukuran lapangan.'),
      ]),
    );
  }
}

// -----------------------------------------------------------------------------
// Progress and certificate preview
// -----------------------------------------------------------------------------

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.xp, required this.completedModules, required this.exploredCount, required this.quizScore, required this.preTestScore, required this.profile, required this.certificateId, required this.certificateIssuedAt});
  final int xp;
  final Set<int> completedModules;
  final int exploredCount;
  final int? quizScore;
  final int? preTestScore;
  final LocalProfile? profile;
  final String? certificateId;
  final String? certificateIssuedAt;

  @override
  Widget build(BuildContext context) {
    final progress = completedModules.length / learningModules.length;
    final certificateUnlocked = completedModules.length == learningModules.length && (quizScore ?? 0) >= 80 && profile != null && certificateIssuedAt != null && certificateId != null;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          sliver: SliverList.list(
            children: <Widget>[
              const _Eyebrow(label: 'PERJALANAN BELAJARMU'),
              const SizedBox(height: 9),
              Text('Lihat sejauh\nmana kamu tumbuh.', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 19),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('PROGRES PEMBELAJARAN', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text('${(progress * 100).round()}%', style: const TextStyle(color: forestDeep, fontSize: 44, height: 1, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text('$xp XP terkumpul', style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${completedModules.length} dari ${learningModules.length} modul', style: const TextStyle(color: muted, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress, minHeight: 6, color: accentMint, backgroundColor: line),
                    ),
                    const SizedBox(height: 11),
                    Text('$exploredCount dari ${explorerTopics.length} objek ekosistem ditemukan', style: const TextStyle(color: muted, fontSize: 11)),
                  ],
                ),
              ),
              if (preTestScore != null && quizScore != null) ...<Widget>[
                const SizedBox(height: 12),
                _LearningImprovementCard(preTestScore: preTestScore!, postTestScore: quizScore!),
              ],
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Pencapaianmu', subtitle: 'Terbuka berdasarkan aktivitas yang sudah kamu selesaikan.'),
              const SizedBox(height: 12),
              Row(children: <Widget>[Expanded(child: _BadgeCard(title: 'Tunas Penjelajah', desc: 'Buka objek ekosistem', icon: Icons.spa_rounded, unlocked: exploredCount > 0)), const SizedBox(width: 10), Expanded(child: _BadgeCard(title: 'Penjaga Pesisir', desc: 'Temukan 5 objek', icon: Icons.explore_rounded, unlocked: exploredCount >= 5))]),
              const SizedBox(height: 10),
              Row(children: <Widget>[Expanded(child: _BadgeCard(title: 'Ahli Mangrove', desc: 'Nilai kuis minimal 80%', icon: Icons.menu_book_rounded, unlocked: (quizScore ?? 0) >= 80)), const SizedBox(width: 10), Expanded(child: _BadgeCard(title: 'Perawat Mangrove', desc: 'Selesaikan 5 modul', icon: Icons.verified_user_rounded, unlocked: completedModules.length == learningModules.length))]),
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Sertifikat penyelesaian', subtitle: 'Selesaikan kelima modul, raih nilai minimal 80%, dan masuk ke akun.'),
              const SizedBox(height: 12),
              _CertificateCard(
                unlocked: certificateUnlocked,
                hasProfile: profile != null,
                participantName: profile?.name ?? '',
                quizScore: quizScore,
                certificateId: certificateId,
                issuedAt: certificateIssuedAt,
              ),
              const SizedBox(height: 22),
              const _NoteCard(text: 'Progres belajar disimpan secara lokal di perangkat ini. Data tidak tersinkron ke akun atau perangkat lain.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearningImprovementCard extends StatelessWidget {
  const _LearningImprovementCard({required this.preTestScore, required this.postTestScore});

  final int preTestScore;
  final int postTestScore;

  @override
  Widget build(BuildContext context) {
    final difference = postTestScore - preTestScore;
    final improved = difference >= 0;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
      child: Row(
        children: <Widget>[
          Icon(improved ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: improved ? forest : const Color(0xFF9B5B37)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Pre-test $preTestScore%  ·  Post-test $postTestScore%', style: const TextStyle(color: muted, fontSize: 11)),
          ),
          Text('${difference > 0 ? '+' : ''}$difference poin', style: TextStyle(color: improved ? forest : const Color(0xFF9B5B37), fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.title, required this.desc, required this.icon, required this.unlocked});
  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: unlocked ? const Color(0xFFC6DDB9) : line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Container(width: 45, height: 45, decoration: BoxDecoration(color: unlocked ? const Color(0xFFE4F0DA) : const Color(0xFFEDEFE8), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: unlocked ? forest : const Color(0xFF9BA39A), size: 23)), const SizedBox(height: 11), Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: unlocked ? ink : muted)), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 10, color: muted, height: 1.35)), const SizedBox(height: 10), Row(children: <Widget>[Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded, size: 13, color: unlocked ? leaf : muted), const SizedBox(width: 4), Text(unlocked ? 'Terbuka' : 'Terkunci', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: unlocked ? leaf : muted))])]),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.unlocked, required this.hasProfile, required this.participantName, required this.quizScore, required this.certificateId, required this.issuedAt});
  final bool unlocked;
  final bool hasProfile;
  final String participantName;
  final int? quizScore;
  final String? certificateId;
  final String? issuedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: unlocked ? const Color(0xFFE8F0DC) : const Color(0xFFEAECE4), borderRadius: BorderRadius.circular(12), border: Border.all(color: unlocked ? const Color(0xFFBFD5A9) : line)),
      child: Column(children: <Widget>[
        if (unlocked) ...<Widget>[
          const Icon(Icons.verified_rounded, color: forest, size: 30),
          const SizedBox(height: 8),
          const Text('SERTIFIKAT PENYELESAIAN', style: TextStyle(color: forest, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 9),
          const Text('DASAR PENGELOLAAN MANGROVE', textAlign: TextAlign.center, style: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 12),
          const Text('Diberikan kepada', style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(participantName, textAlign: TextAlign.center, style: const TextStyle(color: forestDeep, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('Nilai akhir $quizScore%', style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 10),
          Text('ID $certificateId', style: const TextStyle(color: muted, fontSize: 10)),
          Text('Tanggal ${_certificateDate(issuedAt)}', style: const TextStyle(color: muted, fontSize: 10)),
          const SizedBox(height: 8),
          const Text('Sertifikat diterbitkan lokal pada perangkat ini.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 9)),
        ] else ...<Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.lock_rounded, color: muted, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasProfile ? 'Sertifikat terkunci' : 'Masuk atau daftar untuk menerbitkan sertifikat atas nama peserta.',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ink),
                ),
              ),
            ],
          ),
          if (hasProfile) ...<Widget>[
            const SizedBox(height: 7),
            const Text('Selesaikan kelima modul dan raih nilai post-test minimal 80%.', style: TextStyle(color: muted, fontSize: 11, height: 1.4)),
          ],
        ],
      ]),
    );
  }
}

String _certificateDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Tidak tersedia';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

// -----------------------------------------------------------------------------
// Reusable visual components
// -----------------------------------------------------------------------------

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(color: forest, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4));
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: sand, borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Icon(Icons.info_outline_rounded, color: forest, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: forestDeep, fontSize: 11.5, height: 1.45)))]),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.correct, required this.message});
  final bool correct;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: correct ? const Color(0xFFE5F1DE) : const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(10), border: Border.all(color: correct ? const Color(0xFFC5DDB8) : const Color(0xFFF0CFBE))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Icon(correct ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded, size: 20, color: correct ? forest : const Color(0xFF9B5B37)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(correct ? 'Tepat!' : 'Ayo pikirkan lagi', style: TextStyle(color: correct ? forest : const Color(0xFF9B5B37), fontWeight: FontWeight.w600, fontSize: 12)), const SizedBox(height: 4), Text(message, style: const TextStyle(fontSize: 11.5, height: 1.45, color: ink))]))]),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({required this.icon, required this.title, required this.subtitle, required this.onTap, this.enabled = true});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? paper : const Color(0xFFF0F1EC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
          child: Row(children: <Widget>[Container(width: 43, height: 43, decoration: BoxDecoration(color: const Color(0xFFE5EFDB), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: forest, size: 23)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: muted, fontSize: 10.5))])), const Icon(Icons.arrow_forward_rounded, color: forest, size: 19)]),
        ),
      ),
    );
  }
}
