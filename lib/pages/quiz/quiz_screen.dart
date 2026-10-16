import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/quiz_question.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/feedback_card.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.onComplete, this.isPreTest = false});
  final ValueChanged<int> onComplete;
  final bool isPreTest;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _finished = false;
  bool _saved = false;

  void _next() {
    final current = quizQuestions[_index];
    if (_selected == current.correct) _score += 1;
    if (_index == quizQuestions.length - 1) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _index += 1;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return QuizResultScreen(
        score: _score,
        isPreTest: widget.isPreTest,
        onComplete: () {
          if (!_saved) {
            widget.onComplete((_score / quizQuestions.length * 100).round());
            _saved = true;
          }
          Navigator.of(context).pop();
        },
      );
    }
    final question = quizQuestions[_index];
    final answered = _selected != null;
    final correct = _selected == question.correct;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPreTest ? 'Pre-test mangrove' : 'Post-test mangrove',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_index + 1} dari ${quizQuestions.length}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        children: <Widget>[
          Eyebrow(label: widget.isPreTest ? 'TES AWAL' : 'PENILAIAN AKHIR'),
          const SizedBox(height: 8),
          Text(
            widget.isPreTest ? 'Catat pemahaman awal.' : 'Uji pemahamanmu.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_index + (answered ? 1 : 0)) / quizQuestions.length,
              color: AppColors.accentMint,
              backgroundColor: AppColors.line,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: AppColors.forestDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PERTANYAAN 0${_index + 1}',
                  style: const TextStyle(
                    color: AppColors.accentMint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 15),
                const Row(
                  children: <Widget>[
                    Icon(Icons.eco_rounded, color: AppColors.accentMint, size: 19),
                    SizedBox(width: 7),
                    Text(
                      'Pilih satu jawaban paling tepat',
                      style: TextStyle(color: Color(0xFFD4E2D6), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List<Widget>.generate(question.answers.length, (index) {
            final selected = _selected == index;
            final right = answered && index == question.correct;
            final wrong = selected && !correct;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: answered ? null : () => setState(() => _selected = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: right
                        ? const Color(0xFFE7F1E1)
                        : wrong
                            ? AppColors.errorBgLight
                            : AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: right
                          ? AppColors.leaf
                          : wrong
                              ? AppColors.errorBorder
                              : AppColors.line,
                      width: right || wrong ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: right ? AppColors.leaf : const Color(0xFFECEFE5),
                        ),
                        child: right
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          question.answers[index],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (answered) ...<Widget>[
            const SizedBox(height: 3),
            FeedbackCard(correct: correct, message: question.explanation),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _index == quizQuestions.length - 1 ? 'Lihat hasil' : 'Pertanyaan berikutnya',
                ),
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 7),
            const Text(
              'Setiap jawaban dilengkapi penjelasan agar konsepnya mudah dipahami.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
