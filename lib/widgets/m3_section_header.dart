import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Expressive Material 3 Section Header with tonal icon chip,
/// clear visual hierarchy, and optional trailing action.
class M3SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const M3SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.space6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Icon(
                icon,
                size: AppTokens.iconSizeSmall,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppTokens.space12),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
