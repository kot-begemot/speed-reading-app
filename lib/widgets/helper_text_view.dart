import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/tokenized_text.dart';
import '../services/reader_engine.dart';
import '../theme/reader_colors.dart';

/// Full-text helper (spec §3B): the original text as paragraphs, with the
/// active word/group highlighted, auto-scrolled into view, and tap-to-jump.
///
/// Rendered one paragraph per list item so a 100k-word book never builds a
/// single giant span tree. Only the paragraph that contains the active group
/// rebuilds on each tick; the rest ignore ticks (see [_HelperParagraph]).
class HelperTextView extends StatefulWidget {
  final ReaderEngine engine;
  final TokenizedText text;
  final ReaderColors colors;
  final double helperFontSize;
  final String? fontFamily;
  final double bottomPadding;

  const HelperTextView({
    super.key,
    required this.engine,
    required this.text,
    required this.colors,
    required this.helperFontSize,
    required this.fontFamily,
    required this.bottomPadding,
  });

  @override
  State<HelperTextView> createState() => _HelperTextViewState();
}

class _HelperTextViewState extends State<HelperTextView> {
  final ItemScrollController _scrollController = ItemScrollController();
  int _activeParagraph = 0;

  // Last scroll target, so we only re-scroll when the active line actually
  // moves (avoids re-issuing the same scroll every tick).
  int _lastParagraph = -1;
  double _lastAlignment = 2.0;

  // Viewport size, captured each build from the LayoutBuilder — used to keep the
  // active word pinned near the top third even inside a tall paragraph.
  double _viewportWidth = 0;
  double _viewportHeight = 0;

  static const double _anchor = 0.3; // active word's target viewport fraction

  @override
  void initState() {
    super.initState();
    _activeParagraph = _paragraphOf(widget.engine.currentWordIndex);
    widget.engine.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.engine.state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    final active = widget.engine.currentWordIndex;
    final p = _paragraphOf(active);
    _activeParagraph = p;
    final alignment = _targetAlignment(widget.text.paragraphs[p], active);

    // Re-scroll only when the paragraph or the active line changed.
    if (p == _lastParagraph && (alignment - _lastAlignment).abs() < 0.01) {
      return;
    }
    _lastParagraph = p;
    _lastAlignment = alignment;

    if (_scrollController.isAttached) {
      _scrollController.scrollTo(
        index: p,
        alignment: alignment,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Alignment (paragraph-top viewport fraction) that places the active word's
  /// line at [_anchor]. For paragraphs taller than the viewport this goes
  /// negative, scrolling later lines into view so the highlight stays visible.
  double _targetAlignment(ParagraphSpan span, int activeWord) {
    if (_viewportWidth <= 0 || _viewportHeight <= 0) return _anchor;
    final fontSize = widget.helperFontSize; // matches helper text size
    final lineHeight = fontSize * 1.5; // matches the TextStyle height
    final avgCharWidth = fontSize * 0.52; // rough proportional-font estimate
    final textWidth = (_viewportWidth - 32).clamp(1.0, _viewportWidth);
    final charsPerLine = (textWidth / avgCharWidth).clamp(1.0, 100000.0);

    var charsBefore = 0;
    for (var i = span.startWordIndex; i < activeWord; i++) {
      charsBefore += widget.text.words[i].length + 1; // +1 for the space
    }
    final activeLine = (charsBefore / charsPerLine).floor();
    return _anchor - (activeLine * lineHeight) / _viewportHeight;
  }

  int _paragraphOf(int wordIndex) {
    final paras = widget.text.paragraphs;
    // Binary search for the span containing wordIndex.
    var lo = 0, hi = paras.length - 1, result = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (paras[mid].startWordIndex <= wordIndex) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = widget.text.paragraphs;
    if (paragraphs.isEmpty) {
      return const Center(child: Text('No text'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth;
        _viewportHeight = constraints.maxHeight;
        return ScrollablePositionedList.builder(
          itemScrollController: _scrollController,
          initialScrollIndex: _activeParagraph,
          initialAlignment: _anchor,
          itemCount: paragraphs.length,
          padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomPadding),
          itemBuilder: (context, i) => _HelperParagraph(
            engine: widget.engine,
            text: widget.text,
            span: paragraphs[i],
            colors: widget.colors,
            helperFontSize: widget.helperFontSize,
            fontFamily: widget.fontFamily,
          ),
        );
      },
    );
  }
}

class _HelperParagraph extends StatefulWidget {
  final ReaderEngine engine;
  final TokenizedText text;
  final ParagraphSpan span;
  final ReaderColors colors;
  final double helperFontSize;
  final String? fontFamily;

  const _HelperParagraph({
    required this.engine,
    required this.text,
    required this.span,
    required this.colors,
    required this.helperFontSize,
    required this.fontFamily,
  });

  @override
  State<_HelperParagraph> createState() => _HelperParagraphState();
}

class _HelperParagraphState extends State<_HelperParagraph> {
  late final List<TapGestureRecognizer> _recognizers;
  // Highlighted range within this paragraph, in global word indices, or null.
  int _hlStart = -1;
  int _hlEnd = -1;

  @override
  void initState() {
    super.initState();
    _recognizers = List.generate(widget.span.length, (i) {
      final globalIndex = widget.span.startWordIndex + i;
      return TapGestureRecognizer()
        ..onTap = () => widget.engine.jumpToWord(globalIndex);
    });
    _updateHighlight(notify: false);
    widget.engine.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.engine.state.removeListener(_onState);
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _onState() => _updateHighlight(notify: true);

  void _updateHighlight({required bool notify}) {
    final (gStart, gEnd) = widget.engine.currentGroupRange;
    final start = gStart.clamp(widget.span.startWordIndex, widget.span.endWordIndex);
    final end = gEnd.clamp(widget.span.startWordIndex, widget.span.endWordIndex);
    final newStart = start < end ? start : -1;
    final newEnd = start < end ? end : -1;
    if (newStart == _hlStart && newEnd == _hlEnd) return;
    _hlStart = newStart;
    _hlEnd = newEnd;
    if (notify && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = TextStyle(
      fontSize: widget.helperFontSize,
      fontFamily: widget.fontFamily,
      height: 1.5,
      color: theme.colorScheme.onSurface,
    );
    final highlightStyle = base.copyWith(
      backgroundColor: widget.colors.helperHighlight,
      color: _onHighlight(widget.colors.helperHighlight),
    );

    final spans = <TextSpan>[];
    for (var i = 0; i < widget.span.length; i++) {
      final globalIndex = widget.span.startWordIndex + i;
      final highlighted = globalIndex >= _hlStart && globalIndex < _hlEnd;
      spans.add(TextSpan(
        text: i == widget.span.length - 1
            ? widget.text.words[globalIndex]
            : '${widget.text.words[globalIndex]} ',
        style: highlighted ? highlightStyle : base,
        recognizer: _recognizers[i],
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(text: TextSpan(children: spans)),
    );
  }

  /// Pick readable text color on the highlight background.
  Color _onHighlight(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
