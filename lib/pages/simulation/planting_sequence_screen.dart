import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/protocol_step.dart';
import '../../widgets/common/feedback_card.dart';
import 'field_activity_scaffold.dart';
import 'sequence_diagnostic_screen.dart';

class PlantingSequenceScreen extends StatefulWidget {
  const PlantingSequenceScreen({super.key});

  @override
  State<PlantingSequenceScreen> createState() => _PlantingSequenceScreenState();
}

class _PlantingSequenceScreenState extends State<PlantingSequenceScreen> {
  late List<ProtocolStep> _steps;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _steps = <ProtocolStep>[
      correctPlantingSteps[2],
      correctPlantingSteps[0],
      correctPlantingSteps[3],
      correctPlantingSteps[1],
    ];
  }

  void _checkSequence() {
    final correct =
        List<int>.generate(_steps.length, (index) => _steps[index].id).join(',') == '0,1,2,3';
    setState(() => _isCorrect = correct);
  }

  @override
  Widget build(BuildContext context) {
    return FieldActivityScaffold(
      title: 'Urutan penanaman',
      stepLabel: 'Langkah 4 dari 5 · Susun urutan',
      progress: 0.8,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _checkSequence,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Periksa urutan'),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() {
              _steps = <ProtocolStep>[
                correctPlantingSteps[2],
                correctPlantingSteps[0],
                correctPlantingSteps[3],
                correctPlantingSteps[1],
              ];
              _isCorrect = null;
            }),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Ulangi susunan'),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        children: <Widget>[
          const Text(
            'Susun empat langkah penanaman di zona pasang surut.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Siapkan lokasi dan substrat sebelum memasang propagul.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.seaMist,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.water_drop_outlined, color: AppColors.forest, size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'JENDELA IDEAL  ·  Surut terendah (0–0,4 m)',
                    style: TextStyle(
                      color: AppColors.forestDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _steps.length,
            onReorderItem: (oldIndex, newIndex) => setState(() {
              final item = _steps.removeAt(oldIndex);
              _steps.insert(newIndex, item);
              _isCorrect = null;
            }),
            itemBuilder: (context, index) {
              final step = _steps[index];
              final correctOrder = _isCorrect == true;
              return Container(
                key: ValueKey<int>(step.id),
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: correctOrder ? AppColors.seaMist : AppColors.paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: correctOrder ? AppColors.forest : AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: correctOrder ? AppColors.forest : AppColors.seaMist,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: correctOrder ? Colors.white : AppColors.forest,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 7, top: 4),
                        child: Icon(Icons.drag_indicator_rounded, color: AppColors.muted, size: 20),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isCorrect != null) ...<Widget>[
            const SizedBox(height: 3),
            FeedbackCard(
              correct: _isCorrect!,
              message: _isCorrect!
                  ? 'Urutan tepat. Periksa lokasi dan siapkan substrat sebelum menanam; catat salinitas dasar setelah propagul terpasang.'
                  : 'Masih ada langkah yang tertukar. Siapkan lokasi dan lubang tanam sebelum memasang propagul, lalu catat salinitas setelah penanaman.',
            ),
            if (_isCorrect!) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SequenceDiagnosticScreen()),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Lanjut ke diagnostik urutan'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
