import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static mock: Flash Recognition runtime screen.
class FlashRecognitionRuntimeScreen extends StatelessWidget {
  const FlashRecognitionRuntimeScreen({super.key});

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
                        'Flash Recognition · 300 ms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: T.textSecondary,
                        ),
                      ),
                      Text(
                        '12 / 20',
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
            // Stage.
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _maskCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'What did you see?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: T.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: const [
                          _Option(label: 'silent river', selected: false),
                          SizedBox(height: 10),
                          _Option(label: 'distant river', selected: true),
                          SizedBox(height: 10),
                          _Option(label: 'silent forest', selected: false),
                          SizedBox(height: 10),
                          _Option(label: 'distant forest', selected: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom metrics.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  _Metric(label: 'ACCURACY', value: '83%', valueColor: T.success),
                  _Metric(label: 'STREAK', value: '5', valueColor: T.textPrimary),
                  _Metric(
                    label: 'EXPOSURE',
                    value: '300ms',
                    valueColor: T.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _maskCard() {
    return Container(
      width: 300,
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: T.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.border),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            7,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0x405C5F66),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? T.primaryBg : T.surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? T.primary : T.border,
              width: selected ? 1.4 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? T.primary : T.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: T.textSecondary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
