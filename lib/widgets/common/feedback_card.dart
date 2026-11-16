import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.correct,
    required this.message,
  });

  final bool correct;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFE5F1DE) : AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: correct ? const Color(0xFFC5DDB8) : const Color(0xFFF0CFBE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            correct ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded,
            size: 20,
            color: correct ? AppColors.forest : AppColors.warningBrown,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  correct ? 'Tepat!' : 'Ayo pikirkan lagi',
                  style: TextStyle(
                    color: correct ? AppColors.forest : AppColors.warningBrown,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
