import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_error_mapper.dart';
import '../../models/learning_module.dart';
import '../../models/quiz_question.dart';
import '../../repositories/learning_repository.dart';
import '../../widgets/auth/auth_gate.dart';
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
  final Future<void> Function() onComplete;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _isLoadingMaterials = true;
  String? _materialContent;
  String? _materialTakeaway;
  List<QuizQuestion> _moduleQuestions = <QuizQuestion>[];
  int? _selectedAnswer;
  bool _isSubmitting = false;
  QuizSubmitResult? _quizResult;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final repo = context.read<LearningRepository>();
    try {
      final materials = await repo.getMaterialsForModule(widget.module.id);
      if (materials.isNotEmpty) {
        _materialContent = materials.first.content;
        _materialTakeaway = materials.first.takeaway ?? widget.module.takeaway;
      }
    } catch (_) {
      // Fallback to module fields on network error
    }

    try {
      final questions = await repo.getQuizQuestions(
        quizType: 'module',
        moduleId: widget.module.id,
      );
      _moduleQuestions = questions;
    } catch (_) {
      // Ignore if question fetch fails
    }

    if (mounted) {
      setState(() => _isLoadingMaterials = false);
    }
  }

  Future<void> _handleComplete() async {
    final controller = context.read<AppController>();

    if (!controller.isAuthenticated) {
      RequireLogin.guard(
        context,
        isAuthenticated: false,
        featureName: 'Menandai modul selesai',
        onAuthenticatedAction: () {},
        onLoginSuccess: (profile) async {
          await controller.activateProfile(profile);
          if (mounted) {
            _handleComplete();
          }
        },
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorMsg = AppErrorMapper.toUserMessage(e);
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Gagal Menyelesaikan Modul'),
            content: Text(errorMsg),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _submitModuleQuiz() async {
    if (_moduleQuestions.isEmpty || _selectedAnswer == null) return;
    final controller = context.read<AppController>();

    if (!controller.isAuthenticated) {
      RequireLogin.guard(
        context,
        isAuthenticated: false,
        featureName: 'Kuis modul',
        onAuthenticatedAction: () {},
        onLoginSuccess: (profile) async {
          await controller.activateProfile(profile);
          if (mounted) {
            _submitModuleQuiz();
          }
        },
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final question = _moduleQuestions.first;
      final result = await controller.submitQuiz(
        quizType: 'module',
        moduleId: widget.module.id,
        answers: <Map<String, dynamic>>[
          <String, dynamic>{
            'question_id': question.id,
            'selected_option': _selectedAnswer,
          },
        ],
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _quizResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = AppErrorMapper.toUserMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final contentText = _materialContent ?? module.description;
    final takeawayText = _materialTakeaway ?? module.takeaway;
    final hasModuleQuiz = _moduleQuestions.isNotEmpty;

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
            child: Text(
              'Modul 0${module.orderIndex}',
              style: const TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingMaterials
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(color: AppColors.forest),
                  SizedBox(height: 16),
                  Text('Memuat materi modul...'),
                ],
              ),
            )
          : ListView(
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
                Text(contentText,
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
                              style:
                                  TextStyle(color: AppColors.forest, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              takeawayText,
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
                const SizedBox(height: 24),
                if (hasModuleQuiz) ...<Widget>[
                  const Eyebrow(label: '02 · UJI PEMAHAMAN'),
                  const SizedBox(height: 7),
                  Text(
                    _moduleQuestions.first.questionText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 13),
                  ...List<Widget>.generate(_moduleQuestions.first.options.length, (index) {
                    final isSelected = _selectedAnswer == index;
                    final eval = _quizResult?.evaluations.isNotEmpty == true
                        ? _quizResult!.evaluations.first
                        : null;
                    final isSubmitted = eval != null;
                    final isCorrect = eval?.isCorrect ?? false;
                    final isCorrectOpt = isSubmitted && eval.correctOptionIndex == index;

                    Color borderColor = AppColors.line;
                    Color tileColor = AppColors.paper;

                    if (isSubmitted) {
                      if (isCorrectOpt) {
                        borderColor = AppColors.leaf;
                        tileColor = const Color(0xFFE8F2E2);
                      } else if (isSelected && !isCorrect) {
                        borderColor = AppColors.errorBorder;
                        tileColor = const Color(0xFFFFF0E9);
                      }
                    } else if (isSelected) {
                      borderColor = AppColors.leaf;
                      tileColor = const Color(0xFFE8F2E2);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: InkWell(
                        onTap: isSubmitted ? null : () => setState(() => _selectedAnswer = index),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: (isSelected || isCorrectOpt) ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: (isCorrectOpt || (isSelected && !isSubmitted))
                                      ? AppColors.leaf
                                      : const Color(0xFFF0F0E8),
                                  shape: BoxShape.circle,
                                ),
                                child: isCorrectOpt
                                    ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                                    : Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          color: (isSelected && !isSubmitted)
                                              ? Colors.white
                                              : AppColors.forest,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _moduleQuestions.first.options[index],
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
                  if (_quizResult != null) ...<Widget>[
                    const SizedBox(height: 4),
                    FeedbackCard(
                      correct: _quizResult!.isPassed,
                      message: _quizResult!.evaluations.isNotEmpty
                          ? _quizResult!.evaluations.first.explanation
                          : (_quizResult!.isPassed
                              ? 'Jawaban tepat!'
                              : 'Belum tepat. Tinjau kembali materi.'),
                    ),
                    const SizedBox(height: 15),
                  ],
                  if (_quizResult == null && _selectedAnswer != null) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submitModuleQuiz,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Kirim Jawaban'),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleComplete,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.alreadyCompleted
                                ? 'Kembali ke Jalur Belajar'
                                : 'Selesaikan Modul',
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
