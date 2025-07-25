import 'package:crypton_frontend/theme.dart';
import 'package:flutter/material.dart';

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      content: SizedBox(
        width: double.infinity,
        child: Text(
          message,
          style: const TextStyle(color: AppColors.white),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action,
    ),
  );
}
