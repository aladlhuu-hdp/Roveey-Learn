import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/quiz_question.dart';
import '../../widgets/common/eyebrow.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.score,
    required this.isPreTest,
    required this.onComplete,
  });

  final int score;
  final bool isPreTest;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final percentage = (score / quizQuestions.length * 100).round();
    final passed = percentage >= 80;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGreenSoft, width: 5),
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.spa_rounded,
                    color: AppColors.forest,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 25),
                Eyebrow(label: isPreTest ? 'PRE-TEST SELESAI' : 'POST-TEST SELESAI'),
                const SizedBox(height: 9),
                Text(
                  isPreTest
                      ? 'Nilai awal tersimpan.'
                      : passed
                          ? 'Pemahamanmu semakin kuat.'
                          : 'Terus bertumbuh.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 9),
                Text(
                  isPreTest
                      ? 'Hasil ini menjadi acuan sebelum perjalanan belajar dimulai.'
                      : passed
                          ? 'Kamu telah menuntaskan kuis dasar pengelolaan mangrove.'
                          : 'Tinjau kembali materi, lalu coba lagi. Setiap langkah belajar berarti.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                          fontSize: 47,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$score dari ${quizQuestions.length} jawaban benar',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          color: AppColors.accentMint,
                          backgroundColor: AppColors.line,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        isPreTest
                            ? 'SKOR AWAL · TANPA XP'
                            : passed
                                ? 'TARGET TERCAPAI · +${percentage ~/ 10} XP'
                                : 'TARGET NILAI: 80%',
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
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
