import 'package:flutter/material.dart';

import '../theme/reader_colors.dart';
import '../utils/central_letter_calculator.dart';

/// The speed-reading focus area (spec §3A): the current word/group centered
/// between two guide lines, with the optimal-recognition letter highlighted
/// (single-word entries only).
class FocusWordView extends StatelessWidget {
  final List<String> groupWords;
  final double fontSize;
  final String? fontFamily;
  final ReaderColors colors;

  const FocusWordView({
    super.key,
    required this.groupWords,
    required this.fontSize,
    required this.fontFamily,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: colors.currentWord,
      height: 1.1,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GuideLine(color: colors.guideLine),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: _buildWord(baseStyle),
        ),
        _GuideLine(color: colors.guideLine),
      ],
    );
  }

  Widget _buildWord(TextStyle baseStyle) {
    final filteredWords = groupWords.where((w) => !(w.startsWith('[IMAGE:') && w.endsWith(']'))).toList();
    if (filteredWords.isEmpty) {
      return Text('—', style: baseStyle, textAlign: TextAlign.center);
    }
    // Central-letter highlight only makes sense for a single word (the ORP is a
    // fixed point). Groups render plain and centered.
    if (filteredWords.length == 1) {
      final word = filteredWords.first;
      final i = CentralLetterCalculator.indexFor(word).clamp(0, word.length - 1);
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: word.substring(0, i)),
            TextSpan(
              text: word.substring(i, i + 1),
              style: baseStyle.copyWith(color: colors.centralLetter),
            ),
            TextSpan(text: word.substring(i + 1)),
          ],
        ),
      );
    }
    return Text(
      filteredWords.join(' '),
      style: baseStyle,
      textAlign: TextAlign.center,
    );
  }
}

class _GuideLine extends StatelessWidget {
  final Color color;
  const _GuideLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 2,
      color: color,
    );
  }
}
