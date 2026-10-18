class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.answers,
    required this.correct,
    required this.explanation,
  });

  final String question;
  final List<String> answers;
  final int correct;
  final String explanation;
}

const List<QuizQuestion> quizQuestions = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa yang membuat mangrove penting bagi ekosistem pesisir?',
    answers: <String>[
      'Hanya memperindah pemandangan',
      'Menyediakan habitat dan membantu menstabilkan sedimen',
      'Menghilangkan seluruh gelombang laut',
      'Mengubah air laut menjadi air tawar',
    ],
    correct: 1,
    explanation: 'Mangrove mendukung habitat biota dan membantu menahan sedimen.',
  ),
  QuizQuestion(
    question: 'Apa yang sebaiknya diperiksa sebelum rehabilitasi?',
    answers: <String>[
      'Warna seragam relawan',
      'Jumlah bibit sebanyak-banyaknya',
      'Kesesuaian lokasi dan kondisi hidrologi',
      'Desain spanduk kegiatan',
    ],
    correct: 2,
    explanation: 'Kondisi lokasi menentukan jenis dan tindakan yang sesuai.',
  ),
  QuizQuestion(
    question: 'Apa tindakan yang tepat saat banyak bibit mati?',
    answers: <String>[
      'Catat kondisi lalu cari penyebabnya',
      'Tanam ulang tanpa memeriksa',
      'Berhenti melakukan monitoring',
      'Pindahkan semua bibit ke laut dalam',
    ],
    correct: 0,
    explanation: 'Mengetahui penyebab membantu tim memilih tindakan perbaikan.',
  ),
  QuizQuestion(
    question: 'Survival rate menunjukkan ...',
    answers: <String>[
      'Jumlah jenis ikan yang terlihat',
      'Tinggi pasang tertinggi',
      'Jumlah relawan yang hadir',
      'Persentase bibit yang bertahan hidup',
    ],
    correct: 3,
    explanation: 'Survival rate adalah proporsi bibit hidup dibanding jumlah bibit awal.',
  ),
  QuizQuestion(
    question: 'Apa manfaat monitoring yang konsisten?',
    answers: <String>[
      'Menghilangkan kebutuhan merawat bibit',
      'Membantu mengevaluasi pertumbuhan dan hasil rehabilitasi',
      'Menjamin semua bibit tumbuh tanpa risiko',
      'Menggantikan semua observasi lapangan',
    ],
    correct: 1,
    explanation:
        'Data pengamatan yang konsisten mendukung evaluasi dan keputusan selanjutnya.',
  ),
];
