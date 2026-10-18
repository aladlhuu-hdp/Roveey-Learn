import 'package:flutter/material.dart';

class LearningModule {
  const LearningModule({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.takeaway,
    required this.icon,
    required this.duration,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String title;
  final String subtitle;
  final String description;
  final String takeaway;
  final IconData icon;
  final String duration;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
}

const List<LearningModule> learningModules = <LearningModule>[
  LearningModule(
    title: 'Kenali Mangrove',
    subtitle: 'Dasar ekosistem mangrove',
    description:
        'Mangrove adalah kelompok tumbuhan yang mampu hidup di wilayah pesisir yang dipengaruhi pasang surut. Setiap jenis memiliki karakteristik dan adaptasi yang berbeda.',
    takeaway:
        'Mangrove bukan hanya pohon di tepi laut. Ia adalah bagian dari ekosistem pesisir yang saling terhubung.',
    icon: Icons.spa_rounded,
    duration: '5 menit',
    question: 'Di mana ekosistem mangrove umumnya tumbuh?',
    options: <String>[
      'Di wilayah pesisir yang dipengaruhi pasang surut',
      'Hanya di puncak gunung',
      'Di gurun tanpa air',
      'Hanya di dalam air tawar yang sangat dingin',
    ],
    correctAnswer: 0,
    explanation:
        'Benar. Mangrove beradaptasi dengan kondisi pesisir, termasuk salinitas, lumpur, dan pasang surut.',
  ),
  LearningModule(
    title: 'Mengapa Mangrove Penting?',
    subtitle: 'Peran mangrove bagi pesisir',
    description:
        'Akar mangrove membantu menahan sedimen, menyediakan tempat berlindung bagi biota, dan dapat mengurangi energi gelombang. Ekosistem ini juga menyimpan karbon dalam biomassa dan sedimennya.',
    takeaway:
        'Melindungi mangrove berarti ikut menjaga pesisir, habitat biota, dan sumber penghidupan masyarakat.',
    icon: Icons.public_rounded,
    duration: '6 menit',
    question: 'Manakah manfaat mangrove bagi kawasan pesisir?',
    options: <String>[
      'Menghilangkan semua bencana alam',
      'Menjadi habitat biota dan membantu menstabilkan sedimen',
      'Mengubah air laut menjadi air tawar',
      'Menghentikan seluruh pasang surut',
    ],
    correctAnswer: 1,
    explanation:
        'Tepat. Mangrove memberi habitat bagi beragam organisme dan membantu menstabilkan sedimen pesisir.',
  ),
  LearningModule(
    title: 'Penanaman Mangrove',
    subtitle: 'Pemulihan dan penanaman',
    description:
        'Keberhasilan rehabilitasi dimulai dari memahami kondisi lokasi. Jenis, hidrologi, substrat, pasang surut, dan kondisi vegetasi yang ada perlu dipertimbangkan sebelum menentukan teknik penanaman.',
    takeaway:
        'Jangan terburu-buru menanam. Pastikan lokasi memang sesuai dan penyebab kerusakan telah dipahami.',
    icon: Icons.grass_rounded,
    duration: '8 menit',
    question: 'Apa langkah awal sebelum melakukan penanaman?',
    options: <String>[
      'Menanam sebanyak mungkin bibit',
      'Melakukan assessment kondisi dan kesesuaian lokasi',
      'Menebang seluruh vegetasi yang ada',
      'Membuat jalur wisata lebih dahulu',
    ],
    correctAnswer: 1,
    explanation:
        'Benar. Assessment membantu menentukan apakah lokasi sesuai dan tindakan rehabilitasi apa yang diperlukan.',
  ),
  LearningModule(
    title: 'Pemeliharaan Bibit',
    subtitle: 'Perawatan bibit',
    description:
        'Penanaman bukan akhir pekerjaan. Bibit perlu diperiksa secara berkala untuk mengetahui gangguan, kerusakan, perubahan kondisi air, sampah, atau penyebab kematian.',
    takeaway:
        'Pantau penyebab masalah terlebih dahulu sebelum memutuskan perawatan atau penanaman ulang.',
    icon: Icons.volunteer_activism_rounded,
    duration: '7 menit',
    question: 'Saat menemukan bibit mati, apa tindakan yang tepat?',
    options: <String>[
      'Langsung menanam ulang tanpa pemeriksaan',
      'Mengabaikannya sampai semua bibit mati',
      'Mencatat kondisi dan mencari penyebab kematian',
      'Menyiramnya dengan air tawar setiap jam',
    ],
    correctAnswer: 2,
    explanation:
        'Tepat. Catat kondisi dan cari penyebabnya agar tindakan berikutnya lebih sesuai dengan kebutuhan lokasi.',
  ),
  LearningModule(
    title: 'Monitoring Mangrove',
    subtitle: 'Pengamatan dan evaluasi',
    description:
        'Monitoring sederhana mencatat jumlah bibit yang hidup, pertumbuhan, kondisi lingkungan, waktu pengamatan, dan lokasi. Data yang konsisten membantu masyarakat mengevaluasi hasil rehabilitasi.',
    takeaway:
        'Catatan lapangan yang konsisten membantu mengubah pengamatan menjadi dasar pengambilan keputusan.',
    icon: Icons.fact_check_rounded,
    duration: '6 menit',
    question: 'Bagaimana menghitung survival rate bibit?',
    options: <String>[
      'Bibit hidup dibagi bibit awal, lalu dikali 100%',
      'Bibit mati dibagi luas pantai',
      'Jumlah daun dikali tinggi pohon',
      'Jumlah bibit awal dikurangi jumlah pengamat',
    ],
    correctAnswer: 0,
    explanation:
        'Benar. Survival rate = jumlah bibit yang hidup ÷ jumlah bibit awal × 100%.',
  ),
];
