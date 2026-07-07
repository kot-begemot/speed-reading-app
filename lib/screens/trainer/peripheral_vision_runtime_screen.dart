import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static mock: Peripheral Vision runtime screen.
class PeripheralVisionRuntimeScreen extends StatelessWidget {
  const PeripheralVisionRuntimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: T.surfaceLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: T.textSecondary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Peripheral Vision · 8 positions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: T.textSecondary,
                        ),
                      ),
                      Text(
                        '00:22',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: T.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40, height: 40),
                ],
              ),
            ),
            const SizedBox(
              width: double.infinity,
              child: Text(
                'Keep your eyes on the center dot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: T.textSecondary,
                ),
              ),
            ),
            // Field.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Faint cross behind center dot.
                      Positioned(
                        left: w / 2 - 13,
                        top: h / 2 - 22,
                        child: const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 26,
                            color: Color(0x4D4C6EF5),
                          ),
                        ),
                      ),
                      // Center dot.
                      Positioned(
                        left: w / 2 - 8,
                        top: h / 2 - 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: T.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Faint surrounding dots.
                      Positioned(left: w / 2 - 4, top: 24, child: const _FaintDot()),
                      Positioned(right: 40, top: h * 0.18, child: const _FaintDot()),
                      Positioned(left: 40, top: h * 0.18, child: const _FaintDot()),
                      Positioned(left: 10, top: h * 0.5, child: const _FaintDot()),
                      Positioned(right: 40, bottom: h * 0.18, child: const _FaintDot()),
                      Positioned(left: 40, bottom: h * 0.18, child: const _FaintDot()),
                      Positioned(left: w / 2 - 4, bottom: 24, child: const _FaintDot()),
                      // Active stimulus at the periphery (right edge).
                      Positioned(
                        right: 24,
                        top: h * 0.4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: T.surfaceLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: T.warning, width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: T.warning.withValues(alpha: 0.2),
                                offset: const Offset(0, 2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Text(
                            'cloud',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: T.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Bottom answer area.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Which word appeared?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: T.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(child: _WordOption(label: 'cloud', selected: true)),
                      SizedBox(width: 10),
                      Expanded(child: _WordOption(label: 'clock', selected: false)),
                      SizedBox(width: 10),
                      Expanded(child: _WordOption(label: 'crowd', selected: false)),
                      SizedBox(width: 10),
                      Expanded(child: _WordOption(label: 'could', selected: false)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaintDot extends StatelessWidget {
  const _FaintDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: T.textSecondary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WordOption extends StatelessWidget {
  const _WordOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? T.primaryBg : T.surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? T.primary : T.border,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? T.primary : T.textPrimary,
          ),
        ),
      ),
    );
  }
}
