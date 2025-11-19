import 'package:flutter/material.dart';

class CustomKonfirmasiDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool confirmIsDestructive;
  final Color? confirmColor;
  final IconData? icon;

  const CustomKonfirmasiDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.onCancel,
    this.confirmIsDestructive = false,
    this.confirmColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        confirmColor ??
        (confirmIsDestructive ? Colors.red : theme.colorScheme.primary);

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, size: 28, color: color),
                ),
              if (icon != null) const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onCancel, child: Text(cancelText)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: onConfirm,
                    child: Text(
                      confirmText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper that shows [CustomKonfirmasiDialog] and returns `true` when user confirms.
Future<bool?> showCustomKonfirmasiDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Hapus',
  String cancelText = 'Batal',
  bool confirmIsDestructive = true,
  Color? confirmColor,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => CustomKonfirmasiDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmIsDestructive: confirmIsDestructive,
      confirmColor: confirmColor,
      icon: icon,
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
    ),
  );
}
