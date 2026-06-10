import 'package:flutter/material.dart';

/// A labelled settings row: title (+ optional subtitle), an optional trailing
/// control, and an optional full-width control below (e.g. a slider).
class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (below != null) ...[
              const SizedBox(height: 8),
              below!,
            ],
          ],
        ),
      ),
    );
  }
}
