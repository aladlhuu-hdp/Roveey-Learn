import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_error_mapper.dart';
import '../../models/quiz_question.dart';
import '../../repositories/learning_repository.dart';
import '../../widgets/common/eyebrow.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.onComplete,
    this.isPreTest = false,
    this.moduleId,
    this.quizType,
  });

  final ValueChanged<int> onComplete;
  final bool isPreTest;
  final int? moduleId;
  final String? quizType;

  String get effectiveQuizType =>
      quizType ?? (isPreTest ? 'pretest' : (moduleId != null ? 'module' : 'final'));

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _questions = <QuizQuestion>[];
  bool _isLoading = true;
  String? _loadError;
  int _currentIndex = 0;
  final Map<String, int> _selectedAnswers = <String, int>{};
  bool _isSubmitting = false;
  QuizSubmitResult? _submitResult;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final repository = context.read<LearningRepository>();
      final questions = await repository.getQuizQuestions(
        quizType: widget.effectiveQuizType,
        moduleId: widget.moduleId,
      );

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = AppErrorMapper.toUserMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _selectAnswer(String questionId, int optionIndex) {
    setState(() {
      _selectedAnswers[questionId] = optionIndex;
    });
  }

  Future<void> _submitAllAnswers() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final answersPayload = _questions.map((q) {
      return <String, dynamic>{
        'question_id': q.id,
        'selected_option': _selectedAnswers[q.id] ?? 0,
      };
    }).toList();

    try {
      final controller = context.read<AppController>();
      final result = await controller.submitQuiz(
        quizType: widget.effectiveQuizType,
        moduleId: widget.moduleId,
        answers: answersPayload,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorMessage = AppErrorMapper.toUserMessage(e);
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Gagal Mengirim Jawaban'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _submitAllAnswers();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _nextOrSubmit() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
    } else {
      _submitAllAnswers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitResult != null) {
      return QuizResultScreen(
        result: _submitResult!,
        isPreTest: widget.isPreTest,
        questions: _questions,
        onComplete: () {
          widget.onComplete(_submitResult!.score);
          Navigator.of(context).pop();
        },
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isPreTest ? 'Pre-test' : 'Kuis Evaluasi'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(color: AppColors.forest),
              SizedBox(height: 16),
              Text('Memuat bank soal dari server...'),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isPreTest ? 'Pre-test' : 'Kuis Evaluasi'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded, color: AppColors.errorDark, size: 48),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _fetchQuestions,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      final isPre = widget.effectiveQuizType == 'pretest';
      return Scaffold(
        appBar: AppBar(
          title: Text(isPre ? 'Pre-test' : 'Kuis Evaluasi'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.info_outline_rounded, color: AppColors.forest, size: 48),
                const SizedBox(height: 16),
                Text(
                  isPre ? 'Pre-test Belum Tersedia' : 'Kuis Belum Tersedia',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  isPre
                      ? 'Bank soal untuk pre-test belum tersedia di server. Anda dapat langsung mempelajari materi modul.'
                      : 'Bank soal untuk evaluasi ini belum tersedia di server.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final selectedOption = _selectedAnswers[question.id];
    final isAnswered = selectedOption != null;
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPreTest ? 'Pre-test mangrove' : 'Asesmen akhir mangrove',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_currentIndex + 1} dari ${_questions.length}',
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
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(color: AppColors.forest),
                  SizedBox(height: 16),
                  Text('Menilai jawaban di server...'),
                ],
              ),
            )
          : ListView(
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
                    value: (_currentIndex + (isAnswered ? 1 : 0)) / _questions.length,
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
                        'PERTANYAAN 0${_currentIndex + 1}',
                        style: const TextStyle(
                          color: AppColors.accentMint,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                ...List<Widget>.generate(question.options.length, (optIndex) {
                  final isSelected = selectedOption == optIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _selectAnswer(question.id, optIndex),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE7F1E1) : AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.leaf : AppColors.line,
                            width: isSelected ? 1.5 : 1,
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
                                color: isSelected ? AppColors.leaf : const Color(0xFFECEFE5),
                              ),
                              child: Text(
                                String.fromCharCode(65 + optIndex),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.forest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                question.options[optIndex],
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isAnswered ? _nextOrSubmit : null,
                    child: Text(isLast ? 'Kirim Jawaban' : 'Pertanyaan Berikutnya'),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Penilaian dan pembahasan lengkap akan dievaluasi oleh server setelah dikirim.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
    );
  }
}
