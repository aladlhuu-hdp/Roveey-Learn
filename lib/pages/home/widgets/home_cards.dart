import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/learning_module.dart';
import '../../../widgets/mangrove_scene/mangrove_scene.dart';

class HeroExploreCard extends StatelessWidget {
  const HeroExploreCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.forestDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 18, 4),
            child: Row(
              children: <Widget>[
                Text(
                  'JELAJAH INTERAKTIF',
                  style: TextStyle(
                    color: AppColors.accentMint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(Icons.eco_outlined, color: AppColors.accentMint, size: 19),
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
                      Text(
                        'Temui kehidupan\ndi hutan mangrove',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text('Amati, sentuh, dan temukan.',
                          style: TextStyle(color: Color(0xFFD1E0D4), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentMint,
                    foregroundColor: AppColors.forestDeep,
                    minimumSize: const Size(48, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Jelajah'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
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

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.progress,
    required this.completedCount,
  });

  final double progress;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0D9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.terrain_rounded, color: AppColors.forest, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Dasar Pengelolaan Mangrove',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount dari ${learningModules.length} modul selesai',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.line,
              color: AppColors.accentMint,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.forest, size: 22),
              ),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(detail,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35)),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.forest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreTestBanner extends StatelessWidget {
  const PreTestBanner({super.key, required this.score, required this.onTap});

  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = score != null;
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: completed ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(
                completed ? Icons.check_circle_rounded : Icons.assignment_outlined,
                size: 26,
                color: AppColors.forest,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      completed ? 'Pre-test selesai' : 'Mulai dengan pre-test',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completed
                          ? 'Nilai awal tersimpan: $score%'
                          : 'Ukur pemahaman awal sebelum belajar.',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (!completed)
                const Icon(Icons.arrow_forward_rounded, color: AppColors.forest, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizBanner extends StatelessWidget {
  const QuizBanner({super.key, required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.paper : const Color(0xFFF0F0F2),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: <Widget>[
              Icon(
                enabled ? Icons.quiz_rounded : Icons.lock_outline_rounded,
                size: 28,
                color: enabled ? AppColors.forest : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Kuis akhir', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? '5 pertanyaan · nilai post-test'
                          : 'Selesaikan kelima modul untuk membuka kuis.',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (enabled) const Icon(Icons.chevron_right_rounded, color: AppColors.forest),
            ],
          ),
        ),
      ),
    );
  }
}
