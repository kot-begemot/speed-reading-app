import 'package:flutter/material.dart';

/// Interactive bottom navigation bar: Library · Trainer · Progress · Settings.
/// Adapts dynamically to light and dark themes.
class TrainerBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const TrainerBottomNav({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  static const _items = [
    (Icons.menu_book_rounded, 'Library'),
    (Icons.bolt_rounded, 'Trainer'),
    (Icons.bar_chart_rounded, 'Progress'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Resolve theme-adaptive colors
    final backgroundColor = scheme.surfaceContainerLowest;
    final borderColor = isDark ? const Color(0xFF202020) : const Color(0xFFDEE2E6);
    final activeColor = scheme.primary;
    final inactiveColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF5C5F66);
    final activePillBg = isDark ? scheme.primary.withValues(alpha: 0.15) : const Color(0xFFEDF0FE);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
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
                  Expanded(
                    child: InkWell(
                      onTap: onTap != null ? () => onTap!(i) : null,
                      borderRadius: BorderRadius.circular(16),
                      splashColor: activeColor.withValues(alpha: 0.08),
                      highlightColor: Colors.transparent,
                      child: _NavItem(
                        icon: _items[i].$1,
                        label: _items[i].$2,
                        selected: i == selectedIndex,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        activePillBg: activePillBg,
                      ),
                    ),
                  ),
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
  final Color activeColor;
  final Color inactiveColor;
  final Color activePillBg;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.activePillBg,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activePillBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Inter',
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
