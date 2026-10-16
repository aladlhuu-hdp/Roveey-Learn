import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_module.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/feedback_card.dart';
import '../../widgets/mangrove_scene/mangrove_scene.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.module,
    required this.alreadyCompleted,
    required this.onComplete,
  });

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
      appBar: AppBar(
        title: const Text('Modul belajar', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 18),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EFD9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              '+20 XP',
              style: TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: <Widget>[
          const Eyebrow(label: 'PELAJARI · AMATI · TERAPKAN'),
          const SizedBox(height: 8),
          Text(module.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 5),
          Text(
            module.subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const MangroveScene(height: 195, showHotspots: false, compact: false),
          ),
          const SizedBox(height: 20),
          const Eyebrow(label: '01 · PAHAMI'),
          const SizedBox(height: 7),
          Text(module.description,
              style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.6)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0DF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.spa_rounded, size: 23, color: AppColors.forest),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Ingat poin ini',
                        style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        module.takeaway,
                        style: const TextStyle(
                          color: AppColors.forestDeep,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          const Eyebrow(label: '02 · UJI PEMAHAMAN'),
          const SizedBox(height: 7),
          Text(
            module.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 13),
          ...List<Widget>.generate(module.options.length, (index) {
            final selected = _selectedAnswer == index;
            final reveal = _selectedAnswer != null;
            final correctOption = reveal && index == module.correctAnswer;
            Color borderColor = AppColors.line;
            Color tileColor = AppColors.paper;
            if (correctOption) {
              borderColor = AppColors.leaf;
              tileColor = const Color(0xFFE8F2E2);
            } else if (selected && !isCorrect) {
              borderColor = AppColors.errorBorder;
              tileColor = const Color(0xFFFFF0E9);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: reveal ? null : () => setState(() => _selectedAnswer = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                      width: correctOption || selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: correctOption ? AppColors.leaf : const Color(0xFFF0F0E8),
                          shape: BoxShape.circle,
                        ),
                        child: correctOption
                          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                          : Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                color: AppColors.forest,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          module.options[index],
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_selectedAnswer != null) ...<Widget>[
            const SizedBox(height: 4),
            FeedbackCard(
              correct: isCorrect,
              message: isCorrect
                  ? module.explanation
                  : 'Belum tepat. Coba tinjau kembali materi lalu pilih jawaban lain.',
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isCorrect ? widget.onComplete : () => setState(() => _selectedAnswer = null),
                child: Text(
                  isCorrect
                      ? (widget.alreadyCompleted
                          ? 'Selesai · kembali ke jalur'
                          : 'Selesaikan modul · +20 XP')
                      : 'Coba lagi',
                ),
              ),
            ),
          ],
          if (_selectedAnswer == null) ...<Widget>[
            const SizedBox(height: 5),
            const Text(
              'Pilih satu jawaban untuk melihat penjelasan dan menyelesaikan materi.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
