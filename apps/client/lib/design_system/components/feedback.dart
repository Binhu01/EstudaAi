import 'package:flutter/material.dart';

import '../tokens.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value.clamp(0, 1) * 100).round()}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: AppColors.of(context).success,
        backgroundColor: AppColors.of(context).border,
      ),
    ),
  );
}

class CircularProgress extends StatelessWidget {
  const CircularProgress({super.key, this.value, this.label = 'Carregando'});
  final double? value;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: CircularProgressIndicator(value: value?.clamp(0, 1)),
  );
}

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    avatar: icon == null ? null : Icon(icon, size: 16),
    backgroundColor: AppColors.of(context).primarySoft,
    side: BorderSide.none,
  );
}

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.of(context).primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

abstract final class AppSnackbar {
  static void show(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

abstract final class AppModal {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget> actions = const [],
  }) => showDialog<T>(
    context: context,
    builder: (context) =>
        AlertDialog(title: Text(title), content: content, actions: actions),
  );
}

abstract final class AppBottomSheet {
  static Future<T?> show<T>(BuildContext context, Widget content) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: content,
        ),
      );
}

class AppTab extends StatelessWidget {
  const AppTab({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) =>
      Tab(text: label, icon: icon == null ? null : Icon(icon));
}
