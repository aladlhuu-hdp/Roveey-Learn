class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.quizType,
    this.moduleId,
    required this.questionText,
    required this.options,
    this.orderIndex = 1,
    this.isActive = true,
  });

  final String id;
  final String quizType;
  final int? moduleId;
  final String questionText;
  final List<String> options;
  final int orderIndex;
  final bool isActive;

  String get question => questionText;
  List<String> get answers => options;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = <String>[];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      quizType: json['quiz_type']?.toString() ?? 'module',
      moduleId: json['module_id'] as int?,
      questionText: json['question_text']?.toString() ?? '',
      options: parsedOptions,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class QuizAnswerSubmission {
  const QuizAnswerSubmission({
    required this.questionId,
    required this.selectedOption,
  });

  final String questionId;
  final int selectedOption;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'question_id': questionId,
        'selected_option': selectedOption,
      };
}

class QuizEvaluation {
  const QuizEvaluation({
    required this.questionId,
    required this.selectedOption,
    required this.correctOptionIndex,
    required this.isCorrect,
    required this.explanation,
  });

  final String questionId;
  final int? selectedOption;
  final int correctOptionIndex;
  final bool isCorrect;
  final String explanation;

  factory QuizEvaluation.fromJson(Map<String, dynamic> json) {
    return QuizEvaluation(
      questionId: json['question_id']?.toString() ?? '',
      selectedOption: json['selected_option'] as int?,
      correctOptionIndex: (json['correct_option_index'] as num?)?.toInt() ?? 0,
      isCorrect: json['is_correct'] as bool? ?? false,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class QuizSubmitResult {
  const QuizSubmitResult({
    required this.assessmentId,
    required this.quizType,
    this.moduleId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.isPassed,
    required this.attemptNumber,
    required this.evaluations,
  });

  final String assessmentId;
  final String quizType;
  final int? moduleId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final bool isPassed;
  final int attemptNumber;
  final List<QuizEvaluation> evaluations;

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) {
    final rawEvaluations = json['evaluations'];
    List<QuizEvaluation> evals = <QuizEvaluation>[];
    if (rawEvaluations is List) {
      evals = rawEvaluations
          .whereType<Map<String, dynamic>>()
          .map(QuizEvaluation.fromJson)
          .toList();
    }

    return QuizSubmitResult(
      assessmentId: json['assessment_id']?.toString() ?? '',
      quizType: json['quiz_type']?.toString() ?? '',
      moduleId: json['module_id'] as int?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      isPassed: json['is_passed'] as bool? ?? false,
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      evaluations: evals,
    );
  }
}
