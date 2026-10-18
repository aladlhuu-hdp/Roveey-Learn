import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/quiz_question.dart';
import '../../widgets/common/eyebrow.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.result,
    required this.isPreTest,
    required this.onComplete,
    this.questions = const <QuizQuestion>[],
  });

  final QuizSubmitResult result;
  final bool isPreTest;
  final VoidCallback onComplete;
  final List<QuizQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final passed = result.isPassed;
    final percentage = result.score;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGreenSoft, width: 4),
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.spa_rounded,
                    color: AppColors.forest,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 22),
                Eyebrow(label: isPreTest ? 'PRE-TEST SELESAI' : 'HASIL EVALUASI'),
                const SizedBox(height: 8),
                Text(
                  isPreTest
                      ? 'Nilai awal tersimpan.'
                      : passed
                          ? 'Pemahamanmu semakin kuat.'
                          : 'Terus bertumbuh.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isPreTest
                      ? 'Hasil ini menjadi acuan sebelum perjalanan belajar dimulai.'
                      : passed
                          ? 'Selamat! Kamu telah mencapai standar kelulusan asesmen.'
                          : 'Tinjau kembali materi pembelajaran, lalu coba lagi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                          fontSize: 44,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.correctAnswers} dari ${result.totalQuestions} jawaban benar',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          color: AppColors.accentMint,
                          backgroundColor: AppColors.line,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPreTest
                            ? 'SKOR AWAL · EVALUASI SERVER'
                            : passed
                                ? 'STATUS: LULUS (>= 80%)'
                                : 'STATUS: BELUM LULUS (MINIMAL 80%)',
                        style: TextStyle(
                          color: passed ? AppColors.forest : AppColors.errorDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.evaluations.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pembahasan dari Server',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(result.evaluations.length, (index) {
                    final eval = result.evaluations[index];
                    final question = questions.cast<QuizQuestion?>().firstWhere(
                          (q) => q?.id == eval.questionId,
                          orElse: () => null,
                        );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: eval.isCorrect ? const Color(0xFFF0F7ED) : const Color(0xFFFFF2ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: eval.isCorrect ? AppColors.leaf : AppColors.errorBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                eval.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: eval.isCorrect ? AppColors.leaf : AppColors.errorDark,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question?.questionText ?? 'Soal ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (eval.explanation.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              eval.explanation,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.ink,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onComplete,
                    child: Text(isPreTest ? 'Mulai perjalanan belajar' : 'Simpan hasil & kembali'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
