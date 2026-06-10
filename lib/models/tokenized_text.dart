/// A contiguous run of words forming one paragraph. `endWordIndex` is
/// exclusive, so the paragraph's words are `words.sublist(start, end)`.
class ParagraphSpan {
  final int startWordIndex;
  final int endWordIndex;
  const ParagraphSpan(this.startWordIndex, this.endWordIndex);

  int get length => endWordIndex - startWordIndex;
}

/// The single tokenization structure consumed everywhere (locked contract — see
/// IMPLEMENTATION_PLAN.md "Tokenizer contract").
///
/// - [words]: flat word list; a word's global index is its position here.
/// - [sentenceStarts] / [paragraphStarts]: word indices where sentences /
///   paragraphs begin (sorted, ascending) — used for prev/next jumps via
///   binary search.
/// - [paragraphs]: contiguous spans covering every word with no gaps/overlaps —
///   used by the helper view to render one paragraph at a time.
///
/// Never persisted; rebuilt from the on-disk text each time a book opens.
class TokenizedText {
  final List<String> words;
  final List<int> sentenceStarts;
  final List<int> paragraphStarts;
  final List<ParagraphSpan> paragraphs;

  const TokenizedText({
    required this.words,
    required this.sentenceStarts,
    required this.paragraphStarts,
    required this.paragraphs,
  });

  int get wordCount => words.length;

  static const empty = TokenizedText(
    words: [],
    sentenceStarts: [],
    paragraphStarts: [],
    paragraphs: [],
  );
}
