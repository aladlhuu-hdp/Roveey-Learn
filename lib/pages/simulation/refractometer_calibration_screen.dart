import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/feedback_card.dart';
import '../../widgets/common/note_card.dart';
import 'field_activity_scaffold.dart';

class RefractometerCalibrationScreen extends StatefulWidget {
  const RefractometerCalibrationScreen({super.key});
  @override
  State<RefractometerCalibrationScreen> createState() => _RefractometerCalibrationScreenState();
}

class _RefractometerCalibrationScreenState extends State<RefractometerCalibrationScreen> {
  double _offset = 0;
  int? _selectedReading;
  bool _confirmed = false;
  static const List<int> _readings = <int>[24, 32, 38, 45];

  @override
  Widget build(BuildContext context) {
    final correctedReading = 35 + _offset.round();
    final isCorrect = correctedReading == 32 && _selectedReading == 32;
    return FieldActivityScaffold(
      title: 'Kalibrasi refraktometer',
      stepLabel: 'Unit 3 · Ukur air pori',
      progress: 0.72,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedReading == null
                  ? null
                  : () => setState(() => _confirmed = true),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Konfirmasi salinitas'),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _offset = 0;
              _selectedReading = null;
              _confirmed = false;
            }),
            child: const Text('Atur ulang kalibrasi'),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        children: <Widget>[
          const Text(
            'Kalibrasi dan baca refraktometer',
            style: TextStyle(
              fontSize: 21,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Atur koreksi kalibrasi, lalu pilih pembacaan salinitas air pori yang sesuai.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 17),
          Center(
            child: Container(
              width: 204,
              height: 204,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.forestDeep,
                border: Border.all(color: AppColors.refractometerBorder, width: 5),
              ),
              child: Container(
                margin: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFF145B56),
                      Color(0xFF203A38),
                      Color(0xFFF7F6F0),
                      Color(0xFFFFFFFF),
                    ],
                    stops: <double>[0, .45, .46, 1],
                  ),
                  border: Border.all(color: AppColors.refractometerInnerBorder, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AIR PORI',
                        style: TextStyle(
                          color: AppColors.forestDeep,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correctedReading',
                      style: const TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 35,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'PSU',
                      style: TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'HASIL TERKOREKSI',
                      style: TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Koreksi kalibrasi',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_offset >= 0 ? '+' : ''}${_offset.toStringAsFixed(0)} PSU',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sesuaikan hingga sampel menunjukkan 32 PSU.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                Slider(
                  value: _offset,
                  min: -5,
                  max: 5,
                  divisions: 10,
                  label: '${_offset >= 0 ? '+' : ''}${_offset.toStringAsFixed(0)} PSU',
                  onChanged: (value) => setState(() {
                    _offset = value;
                    _confirmed = false;
                  }),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('−5 PSU', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                    Text('0', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                    Text('+5 PSU', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Pilih hasil pembacaan',
            style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._readings.map((reading) {
            final selected = _selectedReading == reading;
            final correctChoice = _confirmed && reading == 32;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() {
                  _selectedReading = reading;
                  _confirmed = false;
                }),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.seaMist : AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.forest : AppColors.line,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected ? AppColors.forest : AppColors.muted,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$reading PSU',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (correctChoice)
                        const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_confirmed) ...<Widget>[
            const SizedBox(height: 3),
            FeedbackCard(
              correct: isCorrect,
              message: isCorrect
                  ? 'Reading cocok dengan offset kalibrasi. Nilai 32 PSU berada pada rentang yang dipakai dalam skenario pembelajaran ini untuk contoh lokasi Rhizophora.'
                  : 'Pembacaan belum cocok. Sesuaikan offset sampai tampilan terkoreksi menjadi 32 PSU, lalu pilih 32 PSU sebagai hasil pengamatan.',
            ),
          ],
          const SizedBox(height: 8),
          const NoteCard(
            text:
                'Simulasi edukatif: angka awal 35 PSU dan target 32 PSU merupakan skenario latihan, bukan hasil pengukuran lapangan.',
          ),
        ],
      ),
    );
  }
}
