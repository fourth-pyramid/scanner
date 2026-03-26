import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qrscanner/core/router/router.dart';

void showSnackBar(
  String message, {
  bool upperSnackBar = false,
  bool popPage = false,
  int duration = 2,
  Color color = const Color.fromRGBO(31, 43, 70, 1),
}) {
  final context = MagicRouter.currentContext;
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: upperSnackBar
          ? const EdgeInsets.only(bottom: 600)
          : const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      duration: Duration(seconds: duration),
      // Removed SnackBarAction - it was preventing auto-dismiss
    ),
  );
  if (popPage) Timer(Duration(seconds: duration), MagicRouter.pop);
}
