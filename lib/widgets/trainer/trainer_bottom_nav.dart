import 'package:flutter/material.dart';

import '../../screens/trainer/trainer_tokens.dart';

/// Static bottom navigation bar mock: Library · Trainer · Progress · Settings.
/// UI only — [selectedIndex] just controls the highlighted item.
class TrainerBottomNav extends StatelessWidget {
  final int selectedIndex;
  const TrainerBottomNav({super.key, this.selectedIndex = 1});

  static const _items = [
    (Icons.menu_book_rounded, 'Library'),
    (Icons.bolt_rounded, 'Trainer'),
    (Icons.bar_chart_rounded, 'Progress'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: T.surfaceLowest,
        border: Border(top: BorderSide(color: T.border, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(child: _NavItem(icon: _items[i].$1, label: _items[i].$2, selected: i == selectedIndex)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavItem({required this.icon, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? T.primary : T.textSecondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? T.primaryBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
