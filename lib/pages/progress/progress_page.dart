import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/explorer_topic.dart';
import '../../models/learning_module.dart';
import '../../models/local_profile.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/note_card.dart';
import '../../widgets/common/section_heading.dart';
import 'widgets/progress_cards.dart';

export 'widgets/progress_cards.dart' show LearningImprovementCard, BadgeCard, CertificateCard, certificateDate;

class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    required this.xp,
    required this.completedModules,
    required this.exploredCount,
    required this.quizScore,
    required this.preTestScore,
    required this.profile,
    required this.certificateId,
    required this.certificateIssuedAt,
  });

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
    final certificateUnlocked = completedModules.length == learningModules.length &&
        (quizScore ?? 0) >= 80 &&
        profile != null &&
        certificateIssuedAt != null &&
        certificateId != null;

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          sliver: SliverList.list(
            children: <Widget>[
              const Eyebrow(label: 'PERJALANAN BELAJARMU'),
              const SizedBox(height: 9),
              Text('Lihat sejauh\nmana kamu tumbuh.',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 19),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'PROGRES PEMBELAJARAN',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.forestDeep,
                            fontSize: 44,
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              '$xp XP terkumpul',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${completedModules.length} dari ${learningModules.length} modul',
                              style: const TextStyle(color: AppColors.muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        color: AppColors.accentMint,
                        backgroundColor: AppColors.line,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      '$exploredCount dari ${explorerTopics.length} objek ekosistem ditemukan',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (preTestScore != null && quizScore != null) ...<Widget>[
                const SizedBox(height: 12),
                LearningImprovementCard(
                  preTestScore: preTestScore!,
                  postTestScore: quizScore!,
                ),
              ],
              const SizedBox(height: 24),
              const SectionHeading(
                title: 'Pencapaianmu',
                subtitle: 'Terbuka berdasarkan aktivitas yang sudah kamu selesaikan.',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: BadgeCard(
                      title: 'Tunas Penjelajah',
                      desc: 'Buka objek ekosistem',
                      icon: Icons.spa_rounded,
                      unlocked: exploredCount > 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BadgeCard(
                      title: 'Penjaga Pesisir',
                      desc: 'Temukan 5 objek',
                      icon: Icons.explore_rounded,
                      unlocked: exploredCount >= 5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: BadgeCard(
                      title: 'Ahli Mangrove',
                      desc: 'Nilai kuis minimal 80%',
                      icon: Icons.menu_book_rounded,
                      unlocked: (quizScore ?? 0) >= 80,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BadgeCard(
                      title: 'Perawat Mangrove',
                      desc: 'Selesaikan 5 modul',
                      icon: Icons.verified_user_rounded,
                      unlocked: completedModules.length == learningModules.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeading(
                title: 'Sertifikat penyelesaian',
                subtitle:
                    'Selesaikan kelima modul, raih nilai minimal 80%, dan masuk ke akun.',
              ),
              const SizedBox(height: 12),
              CertificateCard(
                unlocked: certificateUnlocked,
                hasProfile: profile != null,
                participantName: profile?.name ?? '',
                quizScore: quizScore,
                certificateId: certificateId,
                issuedAt: certificateIssuedAt,
              ),
              const SizedBox(height: 22),
              const NoteCard(
                text:
                    'Progres belajar disimpan secara lokal di perangkat ini. Data tidak tersinkron ke akun atau perangkat lain.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
