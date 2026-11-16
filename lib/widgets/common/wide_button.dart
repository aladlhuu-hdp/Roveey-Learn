import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class WideButton extends StatelessWidget {
  const WideButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.paper : AppColors.surfaceNeutralCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EFDB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.forest, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.forest, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
