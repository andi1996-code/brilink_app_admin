import 'package:flutter/material.dart';
import '../widgets/custom_alert.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showAlert(
    String message, {
    AlertType type = AlertType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showCustomAlertDialog(
      ctx,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
