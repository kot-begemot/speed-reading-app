import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static UI mock: Baseline Assessment intro screen.
class BaselineAssessmentScreen extends StatelessWidget {
  const BaselineAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.textPrimary),
          onPressed: () {},
        ),
        title: const Text(
          'Baseline Assessment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: T.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: T.heroGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.route,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Let's find your level",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: T.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'A quick diagnostic is required before training. '
                        "We'll measure your reading speed and comprehension "
                        'to pick a starting level for your language.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: T.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _stepsCard(),
                      const SizedBox(height: 16),
                      _languageRow(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _startButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepsCard() {
    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _stepRow('1', 'Read a short text', '300–600 words at your own pace'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _stepRow(
              '2', 'Answer 5 questions', 'Multiple choice on what you read'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _stepRow('3', 'Get your level',
              'Start WPM, target & comprehension'),
        ],
      ),
    );
  }

  Widget _stepRow(String number, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: T.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: T.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: T.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: T.card(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.language, size: 22, color: T.textSecondary),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostic language',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: T.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'English',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: T.textSecondary),
        ],
      ),
    );
  }

  Widget _startButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: T.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start assessment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: T.onPrimary,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: T.onPrimary),
          ],
        ),
      ),
    );
  }
}
