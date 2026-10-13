import 'package:flutter/material.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle,});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 52,
                color: ColorPalette.timberGreen.withValues(alpha: 0.35),),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.timberGreen,),),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),),
            ],
          ],),
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState(this.error, {super.key});
  final Object? error;
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.warning_amber_rounded,
        title: 'Something went wrong',
        subtitle:
            '$error\n\nIf this is a permissions error, deploy firestore.rules.',
      );
}
