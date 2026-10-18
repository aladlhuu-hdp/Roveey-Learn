import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_module.dart';

class ModuleCompletionScreen extends StatelessWidget {
  const ModuleCompletionScreen({
    super.key,
    required this.module,
    required this.completedCount,
    required this.nextModuleTitle,
  });

  final LearningModule module;
  final int completedCount;
  final String? nextModuleTitle;

  @override
  Widget build(BuildContext context) {
    final progress = completedCount / defaultLearningModules.length;
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Modul selesai',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: <Widget>[
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.seaMist,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 44),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.seaMist,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'MATERI SELESAI',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(module.title,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Pemahamanmu bertambah. Progres belajar telah tersimpan ke sistem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          '$completedCount / ${defaultLearningModules.length}',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'MODUL SELESAI',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 38, color: AppColors.line),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'PROGRES JALUR',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 38, color: AppColors.line),
                  const Expanded(
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.cloud_done_rounded, color: AppColors.forest, size: 24),
                        SizedBox(height: 3),
                        Text(
                          'TERSIMPAN',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.seaMist,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.forest, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'LANGKAH BERIKUTNYA',
                          style: TextStyle(
                            color: AppColors.forest,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          nextModuleTitle == null
                              ? 'Kamu telah mencapai modul terakhir.'
                              : 'Berikutnya: $nextModuleTitle',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lanjutkan belajar dari tab Belajar.',
                          style: TextStyle(color: AppColors.muted, fontSize: 10.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Lanjutkan belajar'),
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali ke materi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
