import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

enum _TokenState { distractor, done, next }

class _Token {
  const _Token(this.left, this.top, this.label, this.state);
  final double left;
  final double top;
  final int label;
  final _TokenState state;
}

/// Static UI mock for the Number Tracking runtime screen.
class NumberTrackingRuntimeScreen extends StatelessWidget {
  const NumberTrackingRuntimeScreen({super.key});

  static const List<_Token> _tokens = [
    _Token(40, 40, 7, _TokenState.distractor),
    _Token(150, 70, 4, _TokenState.next),
    _Token(280, 50, 15, _TokenState.distractor),
    _Token(70, 150, 1, _TokenState.done),
    _Token(220, 160, 12, _TokenState.distractor),
    _Token(320, 190, 9, _TokenState.distractor),
    _Token(110, 240, 2, _TokenState.done),
    _Token(250, 260, 18, _TokenState.distractor),
    _Token(40, 320, 3, _TokenState.done),
    _Token(180, 340, 11, _TokenState.distractor),
    _Token(300, 360, 6, _TokenState.distractor),
    _Token(90, 430, 14, _TokenState.distractor),
    _Token(210, 450, 5, _TokenState.distractor),
    _Token(330, 470, 20, _TokenState.distractor),
    _Token(50, 540, 8, _TokenState.distractor),
    _Token(160, 560, 13, _TokenState.distractor),
    _Token(270, 580, 4, _TokenState.distractor),
    _Token(120, 650, 16, _TokenState.distractor),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _subRow(),
            Expanded(child: _field()),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
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
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Number Tracking · Find next',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '00:09',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  Widget _subRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tap 1→9 in order · Next',
            style: TextStyle(fontSize: 13, color: T.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: T.accentTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '4',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field() {
    return ClipRect(
      child: Stack(
        children: [
          for (final t in _tokens)
            Positioned(left: t.left, top: t.top, child: _tokenWidget(t)),
        ],
      ),
    );
  }

  Widget _tokenWidget(_Token t) {
    Color fill;
    Color numberColor;
    Border? border;

    switch (t.state) {
      case _TokenState.next:
        fill = T.accentTeal;
        numberColor = Colors.white;
        border = Border.all(color: T.accentTeal, width: 1.4);
        break;
      case _TokenState.done:
        fill = T.surfaceLow;
        numberColor = T.textSecondary.withValues(alpha: 0.4);
        break;
      case _TokenState.distractor:
        fill = T.surfaceLowest;
        numberColor = T.textPrimary;
        border = Border.all(color: T.border, width: 0.8);
        break;
    }

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Text(
        '${t.label}',
        style: TextStyle(
          fontSize: 20,
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
              _MiniMetric(
                label: 'FOUND',
                value: '3 / 9',
                valueColor: T.textPrimary,
              ),
              _MiniMetric(
                label: 'ACCURACY',
                value: '100%',
                valueColor: T.success,
              ),
              _MiniMetric(
                label: 'ERRORS',
                value: '0',
                valueColor: T.textPrimary,
              ),
            ],
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

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
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
        const SizedBox(height: 2),
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
