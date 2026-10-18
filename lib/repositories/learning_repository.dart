import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/explorer_topic.dart';
import '../models/learning_module.dart';
import '../models/protocol_step.dart';
import '../models/quiz_question.dart';

abstract interface class LearningRepository {
  Future<List<LearningModule>> getModules();
  Future<List<LearningMaterial>> getMaterialsForModule(int moduleId);
  Future<List<QuizQuestion>> getQuizQuestions({
    required String quizType,
    int? moduleId,
  });
  List<ExplorerTopic> getExplorerTopics();
  List<ProtocolStep> getPlantingSteps();
}

class SupabaseLearningRepository implements LearningRepository {
  SupabaseLearningRepository([SupabaseClient? client]) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<LearningModule>> getModules() async {
    try {
      final rows = await _client
          .from('learning_modules')
          .select()
          .eq('status', 'published')
          .order('order_index', ascending: true);

      final list = (rows as List)
          .map((row) => LearningModule.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('SupabaseLearningRepository: failed to fetch modules: $e');
    }
    return defaultLearningModules;
  }

  @override
  Future<List<LearningMaterial>> getMaterialsForModule(int moduleId) async {
    try {
      final rows = await _client
          .from('learning_materials')
          .select()
          .eq('module_id', moduleId)
          .eq('status', 'published')
          .order('order_index', ascending: true);

      return (rows as List)
          .map((row) => LearningMaterial.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      debugPrint('SupabaseLearningRepository: failed to fetch materials: $e');
      rethrow;
    }
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions({
    required String quizType,
    int? moduleId,
  }) async {
    try {
      var query = _client
          .from('quiz_questions')
          .select('id, quiz_type, module_id, question_text, options, order_index, is_active')
          .eq('quiz_type', quizType)
          .eq('is_active', true);

      if (moduleId != null) {
        query = query.eq('module_id', moduleId);
      }

      final rows = await query.order('order_index', ascending: true);

      return (rows as List)
          .map((row) => QuizQuestion.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      debugPrint('SupabaseLearningRepository: failed to fetch quiz questions: $e');
      rethrow;
    }
  }

  @override
  List<ExplorerTopic> getExplorerTopics() => explorerTopics;

  @override
  List<ProtocolStep> getPlantingSteps() => correctPlantingSteps;
}
