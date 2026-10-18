import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../pages/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.isAuthenticated,
    required this.child,
    this.guestFallback,
    this.featureName,
    this.onLoginSuccess,
  });

  final bool isAuthenticated;
  final Widget child;
  final Widget? guestFallback;
  final String? featureName;
  final LocalProfileCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    if (isAuthenticated) {
      return child;
    }

    return guestFallback ??
        AuthGatePromptCard(
          featureName: featureName ?? 'Fitur ini',
          onLoginSuccess: onLoginSuccess,
        );
  }
}

class AuthGatePromptCard extends StatelessWidget {
  const AuthGatePromptCard({
    super.key,
    required this.featureName,
    this.onLoginSuccess,
  });

  final String featureName;
  final LocalProfileCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.forest, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'Masuk untuk Menyimpan Progres',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.forestDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$featureName membutuhkan akun agar progres pembelajaran, riwayat nilai kuis, dan penerbitan sertifikatmu tersimpan permanen.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LoginScreen(
                      onAuthenticated: onLoginSuccess ?? (_) async {},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Masuk ke Akun'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RegisterScreen(
                      onAuthenticated: onLoginSuccess ?? (_) async {},
                    ),
                  ),
                );
              },
              child: const Text('Daftar Akun Baru'),
            ),
          ),
        ],
      ),
    );
  }
}

class GuestBanner extends StatelessWidget {
  const GuestBanner({
    super.key,
    required this.onLogin,
    this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD599)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB45309),
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Mode Tamu: Progres Tidak Tersimpan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Masuk atau buat akun agar progres belajar dan kuis tersimpan.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onLogin,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.forest,
            ),
            child: const Text(
              'Masuk',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class RequireLogin {
  RequireLogin._();

  static void guard(
    BuildContext context, {
    required bool isAuthenticated,
    required String featureName,
    required VoidCallback onAuthenticatedAction,
    LocalProfileCallback? onLoginSuccess,
  }) {
    if (isAuthenticated) {
      onAuthenticatedAction();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              AuthGatePromptCard(
                featureName: featureName,
                onLoginSuccess: (profile) async {
                  Navigator.of(ctx).pop();
                  if (onLoginSuccess != null) {
                    await onLoginSuccess(profile);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
