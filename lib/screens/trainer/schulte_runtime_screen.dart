import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static UI mock for the Schulte Table runtime screen.
class SchulteRuntimeScreen extends StatelessWidget {
  const SchulteRuntimeScreen({super.key});

  static const List<List<int>> _grid = [
    [13, 2, 21, 9, 17],
    [6, 24, 4, 19, 11],
    [1, 15, 7, 22, 3],
    [18, 10, 25, 5, 14],
    [8, 20, 12, 23, 16],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surfaceLow,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _targetRow(),
            Expanded(child: _gridArea()),
            _bottomBlock(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(
            fill: T.surfaceLowest,
            border: T.border,
            icon: Icons.close_rounded,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'Schulte Table · 5×5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '00:12',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          _circleButton(
            fill: T.surfaceLowest,
            border: T.border,
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required Color fill,
    Color? border,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Icon(icon, size: 20, color: T.textSecondary),
      ),
    );
  }

  Widget _targetRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tap in order · Next',
            style: TextStyle(fontSize: 13, color: T.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: T.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '7',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: T.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int r = 0; r < _grid.length; r++) ...[
              if (r > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (int c = 0; c < _grid[r].length; c++) ...[
                    if (c > 0) const SizedBox(width: 8),
                    Expanded(child: _cell(_grid[r][c])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cell(int number) {
    final bool isDone = number <= 6;
    final bool isNext = number == 7;

    Color fill;
    Color numberColor;
    Border? border;

    if (isDone) {
      fill = T.surfaceLow;
      numberColor = T.textSecondary.withValues(alpha: 0.35);
    } else if (isNext) {
      fill = T.primaryBg;
      numberColor = T.primary;
      border = Border.all(color: T.primary, width: 1.4);
    } else {
      fill = T.surfaceLowest;
      numberColor = T.textPrimary;
      border = Border.all(color: T.border, width: 0.8);
    }

    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: numberColor,
        ),
      ),
    );
  }

  Widget _bottomBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '6 / 25',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: T.borderStrong,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.24,
                child: Container(color: T.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: T.surfaceLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: T.borderStrong),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.pause_rounded, size: 20, color: T.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Pause',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: T.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
