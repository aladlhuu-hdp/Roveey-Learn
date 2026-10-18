class ProtocolStep {
  const ProtocolStep({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}

const List<ProtocolStep> correctPlantingSteps = <ProtocolStep>[
  ProtocolStep(
    id: 0,
    title: 'Analisis elevasi substrat dan rentang pasang',
    description:
        'Tandai acuan pasang purnama rata-rata dan tentukan jendela pasang yang sesuai.',
  ),
  ProtocolStep(
    id: 1,
    title: 'Gali lubang tanam sedalam akar propagul',
    description:
        'Siapkan lubang tanam tanpa mengganggu substrat minim oksigen di sekitarnya.',
  ),
  ProtocolStep(
    id: 2,
    title: 'Ikat propagul dengan ajir bambu belah',
    description:
        'Tahan propagul dari arus balik menggunakan penyangga yang dapat terurai.',
  ),
  ProtocolStep(
    id: 3,
    title: 'Catat salinitas awal air pori pascatanam',
    description:
        'Simpan pembacaan awal salinitas untuk pemantauan berikutnya.',
  ),
];
