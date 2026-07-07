import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static mock: Comprehension Test (quiz) screen.
class ComprehensionTestScreen extends StatelessWidget {
  const ComprehensionTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top area: close + progress segments + counter.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: T.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: const [
                        _Segment(active: true),
                        SizedBox(width: 6),
                        _Segment(active: true),
                        SizedBox(width: 6),
                        _Segment(active: false),
                        SizedBox(width: 6),
                        _Segment(active: false),
                        SizedBox(width: 6),
                        _Segment(active: false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '2/5',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: T.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Body.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lock chip.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: T.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock_rounded, size: 14, color: T.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Passage hidden during the quiz',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: T.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'QUESTION 2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: T.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Why did the travellers decide to cross the valley before nightfall?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: T.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: const [
                        _AnswerOption(
                          letter: 'A',
                          text: 'To avoid the coming storm',
                          selected: true,
                        ),
                        SizedBox(height: 10),
                        _AnswerOption(
                          letter: 'B',
                          text: 'To reach the river by morning',
                          selected: false,
                        ),
                        SizedBox(height: 10),
                        _AnswerOption(
                          letter: 'C',
                          text: 'Because the guide was waiting',
                          selected: false,
                        ),
                        SizedBox(height: 10),
                        _AnswerOption(
                          letter: 'D',
                          text: 'To save the remaining supplies',
                          selected: false,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Nav buttons.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 120,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: T.borderStrong,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: T.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: T.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: T.onPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: T.onPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: active ? T.primary : T.borderStrong,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.letter,
    required this.text,
    required this.selected,
  });

  final String letter;
  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? T.primaryBg : T.surfaceLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? T.primary : T.border,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? T.primary : T.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? T.primary : T.border,
                  width: 0.8,
                ),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? T.onPrimary : T.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: T.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
