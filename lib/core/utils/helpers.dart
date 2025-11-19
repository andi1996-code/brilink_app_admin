import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static Future<T?> showConfirmDialog<T>(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Yes',
    String cancelText = 'Cancel',
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true as T),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static Widget loadingIndicator({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  static InputDecoration inputDecoration({
    String? label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
