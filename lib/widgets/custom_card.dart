import 'package:flutter/material.dart';
import '../core/constants/app_color.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const CustomCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? AppColor.primary : AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode
              ? AppColor.darkTextSecondary
              : AppColor.textSecondary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColor.darkTextPrimary
                          : AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColor.darkTextPrimary
                          : AppColor.primary,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 12),
              Icon(
                icon,
                size: 26,
                color: isDarkMode ? AppColor.darkTextPrimary : AppColor.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
