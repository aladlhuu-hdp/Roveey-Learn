import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: AppColors.forest, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.forestDeep,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
