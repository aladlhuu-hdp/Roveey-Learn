import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/feedback_card.dart';
import 'field_activity_scaffold.dart';

class SequenceDiagnosticScreen extends StatefulWidget {
  const SequenceDiagnosticScreen({super.key});
  @override
  State<SequenceDiagnosticScreen> createState() => _SequenceDiagnosticScreenState();
}

class _SequenceDiagnosticScreenState extends State<SequenceDiagnosticScreen> {
  final Set<int> _selectedPositions = <int>{};
  bool _checked = false;
  static const List<String> _diagnosticSteps = <String>[
    'Analisis elevasi substrat dan rentang pasang',
    'Catat salinitas awal air pori pascatanam',
    'Pasang ajir bambu untuk meredam arus gelombang',
    'Gali lubang tanam dan siapkan pengikat propagul',
  ];
  static const Set<int> _misplacedPositions = <int>{1, 3};

  void _check() => setState(() => _checked = true);

  @override
  Widget build(BuildContext context) {
    final correct = _selectedPositions.length == _misplacedPositions.length &&
        _selectedPositions.containsAll(_misplacedPositions);
    return FieldActivityScaffold(
      title: 'Diagnostik urutan',
      stepLabel: 'Langkah 5 dari 5 · Protokol lapangan',
      progress: 1,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _check,
              icon: const Icon(Icons.rule_rounded),
              label: const Text('Periksa jawaban'),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selectedPositions.clear();
              _checked = false;
            }),
            child: const Text('Hapus pilihan'),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        children: <Widget>[
          const Text(
            'Urutan kerja memengaruhi kestabilan tanam.',
            style: TextStyle(
              fontSize: 21,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Dua langkah berada di posisi yang keliru. Pilih semua langkah yang perlu dipindahkan, lalu periksa jawabanmu.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 16),
          ...List<Widget>.generate(_diagnosticSteps.length, (index) {
            final selected = _selectedPositions.contains(index);
            final misplaced = _misplacedPositions.contains(index);
            final reveal = _checked;
            final correctMark = reveal && !misplaced;
            final wrongMark = reveal && misplaced;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: _checked
                    ? null
                    : () => setState(() {
                          if (selected) {
                            _selectedPositions.remove(index);
                          } else {
                            _selectedPositions.add(index);
                          }
                        }),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: wrongMark
                        ? AppColors.errorBgSoft
                        : correctMark
                            ? AppColors.seaMist
                            : selected
                                ? AppColors.seaMist
                                : AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: wrongMark
                          ? AppColors.errorBorderAlt
                          : correctMark
                              ? AppColors.forest
                              : selected
                                  ? AppColors.forest
                                  : AppColors.line,
                      width: selected || reveal ? 1.3 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 27,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: wrongMark
                              ? AppColors.error
                              : correctMark
                                  ? AppColors.forest
                                  : AppColors.seaMist,
                          shape: BoxShape.circle,
                        ),
                        child: reveal
                            ? Icon(
                                wrongMark ? Icons.priority_high_rounded : Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _diagnosticSteps[index],
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            if (reveal && misplaced) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                index == 1
                                    ? 'Pindahkan ke setelah penanaman: salinitas dasar dicatat setelah propagul terpasang.'
                                    : 'Pindahkan sebelum memasang ajir: lubang tanam perlu disiapkan lebih dahulu.',
                                style: const TextStyle(
                                  color: AppColors.errorDark,
                                  fontSize: 10.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!_checked)
                        Icon(
                          selected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: selected ? AppColors.forest : AppColors.muted,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_checked) ...<Widget>[
            const SizedBox(height: 3),
            FeedbackCard(
              correct: correct,
              message: correct
                  ? 'Tepat. Salinitas dasar dicatat setelah penanaman, sedangkan lubang tanam perlu disiapkan sebelum memasang ajir.'
                  : 'Belum tepat. Pilih pencatatan salinitas pascatanam dan persiapan lubang tanam sebelum pemasangan ajir.',
            ),
          ],
        ],
      ),
    );
  }
}
