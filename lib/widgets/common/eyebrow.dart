import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.forest,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
