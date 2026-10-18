import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_module.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/section_heading.dart';
import '../../widgets/common/wide_button.dart';
import '../home/home_page.dart';
import 'widgets/learn_cards.dart';

export 'widgets/learn_cards.dart' show ModuleCard, ActivityLaunchCard;

class LearnPage extends StatelessWidget {
  const LearnPage({
    super.key,
    required this.completedModules,
    required this.preTestScore,
    required this.canTakeFinalQuiz,
    required this.onOpenPreTest,
    required this.onOpenModule,
    required this.onOpenQuiz,
    required this.onOpenSimulation,
    required this.onOpenSequence,
    required this.onOpenSequenceDiagnostic,
    required this.onOpenRefractometer,
  });

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
              const Eyebrow(label: 'JALUR BELAJAR'),
              const SizedBox(height: 9),
              Text('Tumbuh bersama\nmangrove.', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 9),
              const Text(
                'Pelajari ekosistem, praktik pemulihan, dan pemantauan melalui lima modul bertahap.',
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.forestDeep,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accentMint.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.route_rounded, color: AppColors.accentMint, size: 26),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'DASAR PENGELOLAAN MANGROVE',
                            style: TextStyle(
                              color: AppColors.accentMint,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$done dari ${learningModules.length} modul selesai',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: LinearProgressIndicator(
                              value: done / learningModules.length,
                              minHeight: 6,
                              color: AppColors.accentMint,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PreTestBanner(score: preTestScore, onTap: onOpenPreTest),
              const SizedBox(height: 22),
              const SectionHeading(
                title: 'Materi pembelajaran',
                subtitle: 'Modul terbuka secara berurutan setelah pre-test.',
              ),
              const SizedBox(height: 13),
              ...List<Widget>.generate(learningModules.length, (index) {
                final completed = completedModules.contains(index);
                final unlocked = completed ||
                    (index == 0 && (preTestScore != null || completedModules.isNotEmpty)) ||
                    (index > 0 && completedModules.contains(index - 1));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: ModuleCard(
                    module: learningModules[index],
                    index: index,
                    completed: completed,
                    unlocked: unlocked,
                    onTap: unlocked ? () => onOpenModule(index) : null,
                  ),
                );
              }),
              const SizedBox(height: 8),
              WideButton(
                icon: Icons.psychology_alt_rounded,
                title: 'Coba simulasi lapangan',
                subtitle: 'Latih keputusan sebelum diterapkan di lokasi',
                onTap: onOpenSimulation,
              ),
              const SizedBox(height: 10),
              WideButton(
                icon: canTakeFinalQuiz ? Icons.quiz_rounded : Icons.lock_outline_rounded,
                title: 'Kuis akhir',
                subtitle: canTakeFinalQuiz
                    ? 'Lima modul selesai · ukur pemahaman kembali'
                    : 'Selesaikan semua modul untuk membuka post-test.',
                onTap: onOpenQuiz,
                enabled: canTakeFinalQuiz,
              ),
              const SizedBox(height: 25),
              const SectionHeading(
                title: 'Aktivitas interaktif',
                subtitle: 'Latih prosedur dan pembacaan data pesisir.',
              ),
              const SizedBox(height: 12),
              ActivityLaunchCard(
                icon: Icons.reorder_rounded,
                title: 'Urutkan langkah penanaman',
                subtitle: 'Susun empat langkah kerja sesuai urutan lapangan.',
                tag: 'INTERAKTIF',
                onTap: onOpenSequence,
              ),
              const SizedBox(height: 10),
              ActivityLaunchCard(
                icon: Icons.fact_check_outlined,
                title: 'Diagnostik urutan kerja',
                subtitle: 'Temukan langkah yang ditempatkan tidak sesuai prosedur.',
                tag: 'ANALISIS',
                onTap: onOpenSequenceDiagnostic,
              ),
              const SizedBox(height: 10),
              ActivityLaunchCard(
                icon: Icons.tune_rounded,
                title: 'Kalibrasi refraktometer',
                subtitle: 'Atur koreksi pembacaan dan identifikasi salinitas pori.',
                tag: 'PENGUKURAN',
                onTap: onOpenRefractometer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
