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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: T.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: T.textSecondary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: T.textPrimary)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: T.textSecondary)),
                ),
              ],
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(deltaIcon, size: 14, color: deltaColor),
                const SizedBox(width: 2),
                Text(delta!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: deltaColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
