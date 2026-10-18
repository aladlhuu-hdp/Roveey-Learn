import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/mangrove_scene/mangrove_scene.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onRegister,
    required this.onSignIn,
    required this.onContinueAsGuest,
  });

  final VoidCallback onRegister;
  final VoidCallback onSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxAuthCardWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.spa_rounded, color: AppColors.forest, size: 28),
                    SizedBox(width: 9),
                    Text(
                      'ROOVEYLEARN',
                      style: TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const MangroveScene(height: 176, showHotspots: false, compact: true),
                ),
                const SizedBox(height: 25),
                const Eyebrow(label: 'DIGITAL LEARNING FOR MANGROVE COMMUNITIES'),
                const SizedBox(height: 9),
                Text('Belajar untuk\npesisir tangguh.', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                const Text(
                  'Kenali ekosistem, latih keputusan lapangan, dan ikuti perkembangan belajarmu.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
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
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
