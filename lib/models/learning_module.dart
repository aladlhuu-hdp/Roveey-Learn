import 'package:flutter/material.dart';

class LearningModule {
  const LearningModule({
    required this.id,
    required this.orderIndex,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.takeaway,
    this.learningObjectives = const <String>[],
    required this.duration,
    this.iconName,
    this.status = 'published',
  });

  final int id;
  final int orderIndex;
  final String title;
  final String subtitle;
  final String description;
  final String takeaway;
  final List<String> learningObjectives;
  final String duration;
  final String? iconName;
  final String status;

  IconData get icon {
    switch (iconName) {
      case 'spa_rounded':
        return Icons.spa_rounded;
      case 'public_rounded':
        return Icons.public_rounded;
      case 'grass_rounded':
        return Icons.grass_rounded;
      case 'volunteer_activism_rounded':
        return Icons.volunteer_activism_rounded;
      case 'fact_check_rounded':
        return Icons.fact_check_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    final rawObjectives = json['learning_objectives'];
    List<String> objectives = <String>[];
    if (rawObjectives is List) {
      objectives = rawObjectives.map((e) => e.toString()).toList();
    }

    return LearningModule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      takeaway: json['takeaway']?.toString() ?? '',
      learningObjectives: objectives,
      duration: json['duration_text']?.toString() ?? json['duration']?.toString() ?? '5 menit',
      iconName: json['icon_name']?.toString(),
      status: json['status']?.toString() ?? 'published',
    );
  }
}

class LearningMaterial {
  const LearningMaterial({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.takeaway,
    this.mediaType = 'text',
    this.mediaUrl,
    required this.orderIndex,
    this.status = 'published',
  });

  final String id;
  final int moduleId;
  final String title;
  final String content;
  final String? takeaway;
  final String mediaType;
  final String? mediaUrl;
  final int orderIndex;
  final String status;

  factory LearningMaterial.fromJson(Map<String, dynamic> json) {
    return LearningMaterial(
      id: json['id']?.toString() ?? '',
      moduleId: (json['module_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      takeaway: json['takeaway']?.toString(),
      mediaType: json['media_type']?.toString() ?? 'text',
      mediaUrl: json['media_url']?.toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'published',
    );
  }
}

const List<LearningModule> defaultLearningModules = <LearningModule>[
  LearningModule(
    id: 1,
    orderIndex: 1,
    title: 'Kenali Mangrove',
    subtitle: 'Dasar ekosistem mangrove',
    description:
        'Mangrove adalah kelompok tumbuhan yang mampu hidup di wilayah pesisir yang dipengaruhi pasang surut. Setiap jenis memiliki karakteristik dan adaptasi yang berbeda.',
    takeaway:
        'Mangrove bukan hanya pohon di tepi laut. Ia adalah bagian dari ekosistem pesisir yang saling terhubung.',
    duration: '5 menit',
    iconName: 'spa_rounded',
    learningObjectives: <String>[
      'Memahami definisi dan zona habitat mangrove',
      'Mengenal adaptasi akar dan daun terhadap salinitas',
      'Mengidentifikasi jenis mangrove dominan di pesisir Indonesia',
    ],
  ),
  LearningModule(
    id: 2,
    orderIndex: 2,
    title: 'Mengapa Mangrove Penting?',
    subtitle: 'Peran mangrove bagi pesisir',
    description:
        'Akar mangrove membantu menahan sedimen, menyediakan tempat berlindung bagi biota, dan dapat mengurangi energi gelombang. Ekosistem ini juga menyimpan karbon dalam biomassa dan sedimennya.',
    takeaway:
        'Melindungi mangrove berarti ikut menjaga pesisir, habitat biota, dan sumber penghidupan masyarakat.',
    duration: '6 menit',
    iconName: 'public_rounded',
    learningObjectives: <String>[
      'Memahami fungsi fisik peredam gelombang dan pencegah abrasi',
      'Memahami fungsi ekologis sebagai nursery ground dan penyerap karbon',
      'Mengetahui manfaat sosial-ekonomi bagi nelayan dan masyarakat pesisir',
    ],
  ),
  LearningModule(
    id: 3,
    orderIndex: 3,
    title: 'Penanaman Mangrove',
    subtitle: 'Pemulihan dan penanaman',
    description:
        'Keberhasilan rehabilitasi dimulai dari memahami kondisi lokasi. Jenis, hidrologi, substrat, pasang surut, dan kondisi vegetasi yang ada perlu dipertimbangkan sebelum menentukan teknik penanaman.',
    takeaway:
        'Jangan terburu-buru menanam. Pastikan lokasi memang sesuai dan penyebab kerusakan telah dipahami.',
    duration: '8 menit',
    iconName: 'grass_rounded',
    learningObjectives: <String>[
      'Melakukan asesmen awal kesesuaian substrat dan salinitas tanah',
      'Memilih bibit berkualitas sesuai zona pasang surut',
      'Menerapkan teknik penanaman dan pemancangan ajir yang benar',
    ],
  ),
  LearningModule(
    id: 4,
    orderIndex: 4,
    title: 'Pemeliharaan Bibit',
    subtitle: 'Perawatan bibit',
    description:
        'Penanaman bukan akhir pekerjaan. Bibit perlu diperiksa secara berkala untuk mengetahui gangguan, kerusakan, perubahan kondisi air, sampah, atau penyebab kematian.',
    takeaway:
        'Pantau penyebab masalah terlebih dahulu sebelum memutuskan perawatan atau penanaman ulang.',
    duration: '7 menit',
    iconName: 'volunteer_activism_rounded',
    learningObjectives: <String>[
      'Melakukan pembersihan sampah dan gulma yang melilit bibit',
      'Mendeteksi serangan hama kepiting atau teritip',
      'Menilai kebutuhan penyulaman bibit yang mati atau hanyut',
    ],
  ),
  LearningModule(
    id: 5,
    orderIndex: 5,
    title: 'Monitoring & Evaluasi',
    subtitle: 'Keberlanjutan rehabilitasi',
    description:
        'Catatan lapangan membantu melihat apakah bibit bertahan hidup. Jika banyak bibit mati, evaluasi kembali kondisi air, pasang surut, atau jenis yang ditanam.',
    takeaway:
        'Catatan lapangan yang konsisten membantu mengubah pengamatan menjadi dasar pengambilan keputusan.',
    duration: '6 menit',
    iconName: 'fact_check_rounded',
    learningObjectives: <String>[
      'Menghitung Survival Rate (SR) bibit secara berkala',
      'Mengukur laju pertumbuhan tinggi dan pertambahan daun',
      'Mendokumentasikan dinamika ekosistem dan biota asosiasi',
    ],
  ),
];

// For backward compatibility
const List<LearningModule> learningModules = defaultLearningModules;
