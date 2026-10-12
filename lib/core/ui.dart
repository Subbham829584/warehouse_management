import 'package:flutter/material.dart';

/// Replaces the `fluttertoast` dependency: native SnackBars work on every
/// platform (including web/desktop) and respect the Scaffold.
void showMessage(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xffe75757) : null,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  String message = '',
  String confirmLabel = 'Yes',
  bool destructive = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message.isEmpty ? null : Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: const Color(0xffe75757))
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return res ?? false;
}
