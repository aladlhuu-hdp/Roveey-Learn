import '../models/explorer_topic.dart';
import '../models/learning_module.dart';
import '../models/protocol_step.dart';
import '../models/quiz_question.dart';

abstract interface class LearningRepository {
  List<LearningModule> getModules();
  List<ExplorerTopic> getExplorerTopics();
  List<QuizQuestion> getQuizQuestions();
  List<ProtocolStep> getPlantingSteps();
}

class LocalLearningRepository implements LearningRepository {
  const LocalLearningRepository();

  @override
  List<LearningModule> getModules() => learningModules;

  @override
  List<ExplorerTopic> getExplorerTopics() => explorerTopics;

  @override
  List<QuizQuestion> getQuizQuestions() => quizQuestions;

  @override
  List<ProtocolStep> getPlantingSteps() => correctPlantingSteps;
}
