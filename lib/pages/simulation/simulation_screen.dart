import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/common/feedback_card.dart';
import '../../widgets/mangrove_scene/mangrove_scene.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key, required this.onComplete});
  final ValueChanged<bool> onComplete;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  int? _choice;
  bool _rewarded = false;
  final List<String> _options = const <String>[
    'Langsung menanam sebanyak mungkin bibit.',
    'Melakukan assessment kondisi dan kesesuaian lokasi.',
    'Menebang seluruh vegetasi agar area terlihat bersih.',
    'Membuat jalur wisata sebelum memeriksa lokasi.',
  ];

  @override
  Widget build(BuildContext context) {
    final answered = _choice != null;
    final correct = _choice == 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulasi lapangan', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: <Widget>[
          const Eyebrow(label: 'KAMU ADALAH PENGELOLA MANGROVE'),
          const SizedBox(height: 8),
          Text('Keputusanmu\nberarti.', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text(
            'Latih pengambilan keputusan sebelum menerapkannya di lapangan.',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MangroveScene(height: 180, showHotspots: false, compact: false),
                Padding(
                  padding: EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Eyebrow(label: 'SKENARIO 01'),
                      SizedBox(height: 7),
                      Text(
                        'Sebuah kawasan pesisir akan direhabilitasi. Kamu diminta mengoordinasikan langkah pertama tim.',
                        style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Apa yang sebaiknya dilakukan terlebih dahulu?',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...List<Widget>.generate(_options.length, (index) {
            final selected = _choice == index;
            final right = answered && index == 1;
            final wrongSelected = selected && !correct;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: answered ? null : () => setState(() => _choice = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: right
                        ? const Color(0xFFE5F2DF)
                        : wrongSelected
                            ? AppColors.errorBg
                            : AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: right
                          ? AppColors.leaf
                          : wrongSelected
                              ? AppColors.errorBorder
                              : AppColors.line,
                      width: right || wrongSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 31,
                        height: 31,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: right ? AppColors.leaf : const Color(0xFFECEFE5),
                          shape: BoxShape.circle,
                        ),
                        child: right
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forest,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _options[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.4,
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
            FeedbackCard(
              correct: correct,
              message: correct
                  ? 'Tepat. Assessment membantu memahami hidrologi, substrat, pasang surut, dan kondisi vegetasi sebelum memilih tindakan rehabilitasi.'
                  : 'Belum tepat. Penanaman yang berhasil dimulai dengan memahami penyebab kerusakan dan kesesuaian lokasi.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_rewarded) {
                    widget.onComplete(correct);
                    _rewarded = true;
                  }
                  Navigator.of(context).pop();
                },
                child: Text(correct ? 'Simpan hasil  +15 XP' : 'Selesai simulasi  +5 XP'),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Catatan: simulasi ini untuk pembelajaran dasar. Keputusan lapangan perlu mempertimbangkan panduan teknis dan kondisi lokal.',
              style: TextStyle(color: AppColors.muted, fontSize: 10.5, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
