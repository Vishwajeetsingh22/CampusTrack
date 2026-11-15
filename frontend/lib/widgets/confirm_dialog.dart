import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.confirmColor = AppTheme.errorRed,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = 'Delete',
    Color confirmColor = AppTheme.errorRed,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.navyPrimary,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
