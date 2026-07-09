import '../models/tokenized_text.dart';

class BookStartHunter {
  /// Scans the tokenized text to find a suitable starting word index that bypasses
  /// typical eBook front matter (e.g. copyright info, Gutenberg headers, titles, table of contents).
  static int findContentStartIndex(TokenizedText text) {
    if (text.words.isEmpty) return 0;

    // 1. Gutenberg start marker detection
    // Look for typical Project Gutenberg markers. If found, start scanning paragraphs after the marker.
    int scanStartWordIndex = 0;
    
    // Join the first 2000 words to check for Gutenberg markers.
    final firstChunkWords = text.words.take(2000).toList();
    final firstChunkText = firstChunkWords.join(' ');
    
    final gutenbergRegExp = RegExp(
      r'\*\*\*\s*START OF (?:THIS|THE) PROJECT GUTENBERG[\s\S]*?\*\*\*',
      caseSensitive: false,
    );
    
    final match = gutenbergRegExp.firstMatch(firstChunkText);
    if (match != null) {
      final substringBeforeMatchEnd = firstChunkText.substring(0, match.end);
      final wordIndex = substringBeforeMatchEnd.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
      scanStartWordIndex = wordIndex;
    }

    // 2. Scan paragraphs starting from scanStartWordIndex
    final paragraphs = text.paragraphs;
    
    // Keep track of total words skipped so we don't skip too much (safety fallback)
    // We cap it at 15% of the total words or 5000 words, whichever is smaller, but at least 1000 words if the book is long enough.
    final maxWordsToSkip = (text.words.length * 0.15).clamp(1000.0, 5000.0).toInt();

    final metadataKeywords = [
      'copyright',
      'all rights reserved',
      'isbn',
      'published',
      'publisher',
      'translator',
      'edition',
      'library of congress',
      'cataloging-in-publication',
      'www.',
      'http',
      'license',
      'disclaimer',
      'trademark',
      'gutenberg',
      'contents',
      'table of contents',
      'illustration',
      'first published',
    ];

    for (final paragraph in paragraphs) {
      // Skip paragraphs that are before the Gutenberg start marker
      if (paragraph.endWordIndex <= scanStartWordIndex) {
        continue;
      }

      // If we've skipped too much, safety fallback to scanStartWordIndex or 0
      if (paragraph.startWordIndex > maxWordsToSkip) {
        break;
      }

      final paraWords = text.words.sublist(paragraph.startWordIndex, paragraph.endWordIndex);
      final paraText = paraWords.join(' ').toLowerCase();

      // Check if it contains metadata keywords
      bool containsMetadata = false;
      for (final keyword in metadataKeywords) {
        if (paraText.contains(keyword)) {
          containsMetadata = true;
          break;
        }
      }
      if (containsMetadata) {
        continue;
      }

      // Check if it's a short chapter title or ToC/Header pattern.
      // A chapter title/header is typically short (< 8 words) and might start with specific words
      final isHeaderPattern = paraWords.length < 8 && (
        paraText.startsWith('chapter') || 
        paraText.startsWith('book') || 
        paraText.startsWith('part') || 
        paraText.startsWith('section') || 
        paraText.startsWith('act') || 
        paraText.startsWith('scene') || 
        paraText.startsWith('prologue') || 
        paraText.startsWith('epilogue') || 
        paraText.startsWith('contents') || 
        RegExp(r'^\d+$').hasMatch(paraText) || 
        RegExp(r'^[ivxldcm]+\.?$').hasMatch(paraText) // roman numerals
      );

      if (isHeaderPattern) {
        continue;
      }

      // Skip very short paragraphs (e.g. title pages, author lines, dedications)
      // A typical starting narrative paragraph is usually longer.
      if (paraWords.length < 10) {
        continue;
      }

      // If we reach here, we've found a substantial paragraph that doesn't look like copyright or title!
      return paragraph.startWordIndex;
    }

    // Default fallback
    return scanStartWordIndex < text.words.length ? scanStartWordIndex : 0;
  }
}
