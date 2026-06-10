import '../models/tokenized_text.dart';

/// Turns plain text into the locked [TokenizedText] contract: a flat word list
/// plus sentence and paragraph boundaries. This is the single tokenization code
/// path — used at import (for the word count) and at reader open (full runtime
/// structure).
class WordTokenizer {
  /// Lowercased abbreviation bodies (without the trailing period) that must NOT
  /// be treated as sentence ends. Kept small and pragmatic — not exhaustive.
  static const Set<String> _abbreviations = {
    // English
    'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr', 'st', 'vs', 'etc',
    'e.g', 'i.e', 'a.m', 'p.m', 'no', 'fig', 'dept', 'inc', 'ltd', 'co',
    // Russian
    'т.д', 'т.е', 'т.п', 'др', 'им', 'г', 'гг', 'стр', 'рис',
  };

  static final RegExp _paragraphSplit = RegExp(r'\n[ \t]*\n+');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _trailingClosers = RegExp(r'''[")'”’»\]\}]+$''');
  static final RegExp _trailingDots = RegExp(r'\.+$');
  static final RegExp _singleLetter = RegExp(r'^[A-Za-zА-Яа-яЁё]$');

  static TokenizedText tokenize(String text) {
    final words = <String>[];
    final sentenceStarts = <int>{};
    final paragraphStarts = <int>[];
    final paragraphs = <ParagraphSpan>[];

    final paras = text
        .split(_paragraphSplit)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);

    for (final para in paras) {
      final start = words.length;
      paragraphStarts.add(start);
      sentenceStarts.add(start); // a new paragraph always starts a sentence

      var nextStartsSentence = false;
      for (final tok in para.split(_whitespace)) {
        if (tok.isEmpty) continue;
        final idx = words.length;
        if (nextStartsSentence) {
          sentenceStarts.add(idx);
          nextStartsSentence = false;
        }
        words.add(tok);
        if (_endsSentence(tok)) nextStartsSentence = true;
      }

      paragraphs.add(ParagraphSpan(start, words.length));
    }

    final sortedStarts = sentenceStarts.toList()..sort();
    return TokenizedText(
      words: words,
      sentenceStarts: sortedStarts,
      paragraphStarts: paragraphStarts,
      paragraphs: paragraphs,
    );
  }

  /// True if [token] terminates a sentence. Excludes decimals, single-letter
  /// initials, and known abbreviations so "Mr.", "т.д.", "3.14" don't split.
  static bool _endsSentence(String token) {
    final t = token.replaceAll(_trailingClosers, '');
    if (t.isEmpty) return false;
    final last = t[t.length - 1];
    if (last == '!' || last == '?') return true;
    if (last != '.') return false;

    final body = t.replaceAll(_trailingDots, '');
    if (body.isEmpty) return false;
    if (_singleLetter.hasMatch(body)) return false;
    if (_abbreviations.contains(body.toLowerCase())) return false;
    return true;
  }
}
