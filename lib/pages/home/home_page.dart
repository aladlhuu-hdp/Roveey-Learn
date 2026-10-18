import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_module.dart';
import '../../widgets/auth/auth_gate.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/section_heading.dart';
import 'widgets/home_cards.dart';

export 'widgets/home_cards.dart'
    show PreTestBanner, QuizBanner, HeroExploreCard, ProgressCard, ActionCard;

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
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

  bool get isGuest => profileName == null || profileName!.isEmpty;

  @override
  Widget build(BuildContext context) {
    final progress = completedCount / defaultLearningModules.length;
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
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.spa_rounded, color: AppColors.accentMint, size: 27),
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
                            color: AppColors.forestDeep,
                          ),
                        ),
                        Text(
                          'BELAJAR UNTUK PESISIR',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.cardOutline),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          '$completedCount/${defaultLearningModules.length} Modul',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Profil',
                    onPressed: onAccount,
                    visualDensity: VisualDensity.compact,
                    icon: isGuest
                        ? const Icon(Icons.person_outline_rounded, color: AppColors.forest)
                        : CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.surfaceGreen,
                            child: Text(
                              firstName![0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.forest,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isGuest) ...<Widget>[
                GuestBanner(onLogin: onAccount),
                const SizedBox(height: 18),
              ],
              const Eyebrow(label: 'BELAJAR UNTUK PESISIR'),
              const SizedBox(height: 5),
              Text(
                isGuest ? 'Halo, Penjaga Pesisir' : 'Halo, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text('Ekosistem sehat,\npesisir tangguh.',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text('Kenali mangrove, pahami perannya, dan dukung pemulihan pesisir.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 21),
              HeroExploreCard(onTap: onExplore),
              const SizedBox(height: 16),
              PreTestBanner(score: preTestScore, onTap: onPreTest),
              const SizedBox(height: 25),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: SectionHeading(
                      title: 'Perjalananmu',
                      subtitle: 'Satu langkah kecil berarti.',
                    ),
                  ),
                  TextButton(onPressed: onLearn, child: const Text('Lihat modul')),
                ],
              ),
              const SizedBox(height: 9),
              ProgressCard(progress: progress, completedCount: completedCount),
              const SizedBox(height: 25),
              const SectionHeading(
                title: 'Pilih aktivitas',
                subtitle: 'Belajar dengan cara yang berbeda.',
              ),
              const SizedBox(height: 13),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ActionCard(
                      icon: Icons.explore_rounded,
                      title: 'Jelajah',
                      detail: 'Temukan rahasia mangrove',
                      tint: const Color(0xFFE1F0DB),
                      onTap: onExplore,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionCard(
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
              QuizBanner(onTap: onQuiz, enabled: canTakeFinalQuiz),
              const SizedBox(height: 20),
              const Text(
                'KENALI  ·  RAWAT  ·  LINDUNGI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
