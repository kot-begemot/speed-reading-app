import 'package:flutter/material.dart';

import '../../screens/trainer/trainer_tokens.dart';

/// Static metric tile mock: label, value + unit, and an optional delta row.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? delta;
  final Color deltaColor;
  final IconData deltaIcon;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.delta,
    this.deltaColor = T.success,
    this.deltaIcon = Icons.arrow_upward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: t.card(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: t.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: t.textPrimary)),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(unit,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: t.textSecondary)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Right: badge (only when delta is present)
          if (delta != null) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(deltaIcon, size: 16, color: deltaColor),
                const SizedBox(height: 3),
                Text(delta!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: deltaColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
