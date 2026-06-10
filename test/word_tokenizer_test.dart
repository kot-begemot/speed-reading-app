import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/utils/word_tokenizer.dart';

void main() {
  test('splits words and counts them', () {
    final t = WordTokenizer.tokenize('one two three four five');
    expect(t.words, ['one', 'two', 'three', 'four', 'five']);
    expect(t.wordCount, 5);
  });

  test('paragraph spans are contiguous and cover every word', () {
    const text = 'First paragraph here.\n\nSecond one.\n\nThird and last.';
    final t = WordTokenizer.tokenize(text);

    expect(t.paragraphs.length, 3);
    // Contiguous, no gaps/overlaps, covering [0, wordCount).
    expect(t.paragraphs.first.startWordIndex, 0);
    expect(t.paragraphs.last.endWordIndex, t.wordCount);
    for (var i = 1; i < t.paragraphs.length; i++) {
      expect(t.paragraphs[i].startWordIndex, t.paragraphs[i - 1].endWordIndex);
    }
    // Every paragraph start is also a sentence start.
    for (final start in t.paragraphStarts) {
      expect(t.sentenceStarts, contains(start));
    }
  });

  test('detects sentence boundaries', () {
    final t = WordTokenizer.tokenize('Hello world. How are you? Fine!');
    // Sentences start at: 0 (Hello), "How" (idx 2), "Fine" (idx 5).
    expect(t.sentenceStarts, containsAll(<int>[0, 2, 5]));
  });

  test('abbreviations and initials do not split sentences', () {
    final t = WordTokenizer.tokenize(
        'Mr. Smith met Dr. Jones and J. Doe at 3.14 today.');
    // Only the final period ends a sentence → a single sentence start at 0.
    expect(t.sentenceStarts, [0]);
  });

  test('Russian abbreviation т.д. does not split', () {
    final t = WordTokenizer.tokenize('Яблоки, груши и т.д. лежат на столе.');
    expect(t.sentenceStarts, [0]);
  });

  test('empty text yields empty structure', () {
    final t = WordTokenizer.tokenize('   \n\n  ');
    expect(t.wordCount, 0);
    expect(t.paragraphs, isEmpty);
    expect(t.sentenceStarts, isEmpty);
  });
}
