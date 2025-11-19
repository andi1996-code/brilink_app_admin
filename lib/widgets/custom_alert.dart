import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_color.dart';

enum AlertType { error, success, info }

class CustomAlert extends StatelessWidget {
  final String message;
  final AlertType type;
  final VoidCallback? onClose;
  final bool dismissible;
  final Widget? action;

  const CustomAlert({
    Key? key,
    required this.message,
    this.type = AlertType.info,
    this.onClose,
    this.dismissible = true,
    this.action,
  }) : super(key: key);

  Color _backgroundColor(BuildContext context) {
    switch (type) {
      case AlertType.error:
        // use theme's error color if available, otherwise fallback to red
        return Theme.of(context).colorScheme.error;
      case AlertType.success:
        return Colors.green.shade600;
      case AlertType.info:
        return Theme.of(context).colorScheme.primary.withOpacity(0.12);
    }
  }

  Color _textColor(BuildContext context) {
    switch (type) {
      case AlertType.error:
      case AlertType.success:
        return Colors.white;
      case AlertType.info:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _iconData() {
    switch (type) {
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _backgroundColor(context);
    final txt = _textColor(context);

    // Floating / elevated card for a modern look
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Material(
          elevation: 10,
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: type == AlertType.info
                  ? AppColor.textSecondary.withOpacity(0.08)
                  : Colors.transparent,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(_iconData(), color: txt, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: txt),
                  ),
                ),
                if (action != null) ...[action!, const SizedBox(width: 8)],
                if (dismissible)
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(Icons.close, color: txt, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small stateful wrapper used by the dialog to support auto-dismiss timers.
class _AutoDismissAlert extends StatefulWidget {
  final String message;
  final AlertType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration? autoDismissDuration; // null disables auto-dismiss
  final bool dismissible;

  const _AutoDismissAlert({
    Key? key,
    required this.message,
    this.type = AlertType.info,
    this.actionLabel,
    this.onAction,
    this.autoDismissDuration = const Duration(seconds: 3),
    this.dismissible = true,
  }) : super(key: key);

  @override
  State<_AutoDismissAlert> createState() => _AutoDismissAlertState();
}

class _AutoDismissAlertState extends State<_AutoDismissAlert> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoDismissDuration != null) {
      _timer = Timer(widget.autoDismissDuration!, () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: CustomAlert(
          message: widget.message,
          type: widget.type,
          dismissible: widget.dismissible,
          action: widget.actionLabel != null
              ? TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onAction != null) widget.onAction!();
                  },
                  child: Text(widget.actionLabel!),
                )
              : null,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

/// Helper to show the alert as a dialog. By default the alert auto-dismisses
/// after 3 seconds. Pass `autoDismissDuration: null` to disable auto-dismiss.
Future<void> showCustomAlertDialog(
  BuildContext context, {
  required String message,
  AlertType type = AlertType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? autoDismissDuration = const Duration(seconds: 3),
  bool dismissible = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Alert',
    barrierColor: Colors.black.withOpacity(0.2),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) {
      return _AutoDismissAlert(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        autoDismissDuration: autoDismissDuration,
        dismissible: dismissible,
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOut);
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}
