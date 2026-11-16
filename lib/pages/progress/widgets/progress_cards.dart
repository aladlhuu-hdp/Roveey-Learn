import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LearningImprovementCard extends StatelessWidget {
  const LearningImprovementCard({
    super.key,
    required this.preTestScore,
    required this.postTestScore,
  });

  final int preTestScore;
  final int postTestScore;

  @override
  Widget build(BuildContext context) {
    final difference = postTestScore - preTestScore;
    final improved = difference >= 0;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            improved ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: improved ? AppColors.forest : AppColors.warningBrown,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pre-test $preTestScore%  ·  Post-test $postTestScore%',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          Text(
            '${difference > 0 ? '+' : ''}$difference poin',
            style: TextStyle(
              color: improved ? AppColors.forest : AppColors.warningBrown,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  const BadgeCard({
    super.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unlocked ? AppColors.badgeGreen : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: unlocked ? AppColors.surfaceGreen : const Color(0xFFEDEFE8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: unlocked ? AppColors.forest : const Color(0xFF9BA39A),
              size: 23,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.ink : AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: AppColors.muted, fontSize: 10, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                size: 13,
                color: unlocked ? AppColors.leaf : AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                unlocked ? 'Terbuka' : 'Terkunci',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? AppColors.leaf : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.unlocked,
    required this.hasProfile,
    required this.participantName,
    required this.quizScore,
    required this.certificateId,
    required this.issuedAt,
  });

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
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFE8F0DC) : const Color(0xFFEAECE4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unlocked ? AppColors.borderGreenMuted : AppColors.line),
      ),
      child: Column(
        children: <Widget>[
          if (unlocked) ...<Widget>[
            const Icon(Icons.verified_rounded, color: AppColors.forest, size: 30),
            const SizedBox(height: 8),
            const Text(
              'SERTIFIKAT PENYELESAIAN',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'DASAR PENGELOLAAN MANGROVE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Diberikan kepada',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              participantName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.forestDeep,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text('Nilai akhir $quizScore%',
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 10),
            Text('ID $certificateId',
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            Text('Tanggal ${certificateDate(issuedAt)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            const SizedBox(height: 8),
            const Text(
              'Sertifikat digital resmi terverifikasi server RooveyLearn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 9.5),
            ),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.lock_rounded, color: AppColors.muted, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasProfile
                        ? 'Sertifikat terkunci'
                        : 'Masuk atau daftar untuk menerbitkan sertifikat atas nama peserta.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            if (hasProfile) ...<Widget>[
              const SizedBox(height: 7),
              const Text(
                'Selesaikan kelima modul dan raih nilai asesmen akhir minimal 80%.',
                style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String certificateDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Tidak tersedia';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
