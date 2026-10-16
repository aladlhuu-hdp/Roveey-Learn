import 'package:flutter/material.dart';

class ExplorerTopic {
  const ExplorerTopic({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.fact,
    required this.icon,
    required this.x,
    required this.y,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;
  final String fact;
  final IconData icon;
  final double x;
  final double y;
}

const List<ExplorerTopic> explorerTopics = <ExplorerTopic>[
  ExplorerTopic(
    id: 'leaves',
    title: 'Daun Mangrove',
    tagline: 'Adaptasi di lingkungan pesisir',
    description:
        'Daun pada berbagai jenis mangrove memiliki adaptasi yang membantu tumbuhan menghadapi kondisi pesisir, termasuk paparan garam dan panas.',
    fact: 'Bentuk dan karakter daun dapat membantu proses identifikasi jenis.',
    icon: Icons.eco_rounded,
    x: 0.39,
    y: 0.28,
  ),
  ExplorerTopic(
    id: 'roots',
    title: 'Akar Mangrove',
    tagline: 'Struktur penopang kehidupan',
    description:
        'Bentuk akar berbeda menurut jenis mangrove. Akar membantu menopang tumbuhan pada substrat lunak dan menjadi ruang hidup bagi organisme kecil.',
    fact: 'Akar juga membantu memerangkap sedimen di kawasan pesisir.',
    icon: Icons.account_tree_rounded,
    x: 0.57,
    y: 0.57,
  ),
  ExplorerTopic(
    id: 'wildlife',
    title: 'Biota Pesisir',
    tagline: 'Rumah bagi kehidupan',
    description:
        'Area mangrove menjadi tempat mencari makan, berlindung, atau berkembang bagi berbagai ikan, kepiting, moluska, dan satwa lain.',
    fact: 'Jaga habitat dan hindari mengganggu satwa yang ditemukan.',
    icon: Icons.set_meal_rounded,
    x: 0.76,
    y: 0.71,
  ),
  ExplorerTopic(
    id: 'water',
    title: 'Air dan Sedimen',
    tagline: 'Fondasi ekosistem',
    description:
        'Pasang surut, aliran air, dan kondisi substrat memengaruhi jenis mangrove yang dapat tumbuh. Perubahan hidrologi bisa berdampak besar pada keberhasilan rehabilitasi.',
    fact: 'Amati pola genangan dan aliran air sebelum menentukan lokasi tanam.',
    icon: Icons.water_drop_rounded,
    x: 0.17,
    y: 0.73,
  ),
  ExplorerTopic(
    id: 'seedling',
    title: 'Bibit Mangrove',
    tagline: 'Awal dari pemulihan',
    description:
        'Bibit perlu disesuaikan dengan jenis dan kondisi lokasi. Setelah ditanam, kondisinya perlu dipantau secara berkala, bukan ditinggalkan begitu saja.',
    fact: 'Bibit yang bertahan hidup lebih penting daripada sekadar jumlah yang ditanam.',
    icon: Icons.spa_rounded,
    x: 0.88,
    y: 0.87,
  ),
];
