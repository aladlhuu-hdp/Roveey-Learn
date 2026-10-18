import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/learning_module.dart';

class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.module,
    required this.index,
    required this.completed,
    required this.unlocked,
    required this.onTap,
  });

  final LearningModule module;
  final int index;
  final bool completed;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: unlocked ? AppColors.paper : AppColors.surfaceNeutralCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: completed ? AppColors.borderGreen : AppColors.line,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 58,
                decoration: BoxDecoration(
                  color: completed ? const Color(0xFFE1EFDA) : AppColors.surfaceCardMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : unlocked
                              ? module.icon
                              : Icons.lock_outline_rounded,
                      color: unlocked ? AppColors.forest : AppColors.muted,
                      size: 23,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0${index + 1}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      module.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: unlocked ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.subtitle,
                      style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(
                          module.duration,
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                        if (completed) ...<Widget>[
                          const SizedBox(width: 9),
                          const Icon(Icons.verified_rounded, size: 13, color: AppColors.leaf),
                          const SizedBox(width: 3),
                          const Text(
                            'Selesai',
                            style: TextStyle(
                              color: AppColors.leaf,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else if (!unlocked) ...<Widget>[
                          const SizedBox(width: 8),
                          const Text(
                            'Terkunci',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                unlocked ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                color: AppColors.muted,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityLaunchCard extends StatelessWidget {
  const ActivityLaunchCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.seaMist,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.forest, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
