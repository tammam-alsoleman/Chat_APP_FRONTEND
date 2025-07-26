// lib/shared/utils.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A utility class for common helper functions.
class AppUtils {
  // To prevent instantiation of this class
  AppUtils._();

  /// Shows a standard SnackBar with a message.
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Logs a message only in debug mode
  static void log(String message) {
    if (kDebugMode) {
      print('[App] $message');
    }
  }

}