import 'package:flutter/material.dart';

import '../tokens.dart';
import 'buttons.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.goal,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(icon, color: colors.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      EmptyState(
        title: 'Não foi possível continuar',
        message: message,
        icon: Icons.error_outline,
      ),
      if (onRetry != null)
        PrimaryButton(label: 'Tentar novamente', onPressed: onRetry),
    ],
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Carregando',
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 20});
  final double? width;
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.of(context).border,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),
  );
}
