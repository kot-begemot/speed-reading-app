import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:epubx/epubx.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Result of parsing a file into clean text plus any metadata we could extract.
class ParsedBook {
  final String text;
  final String? title;
  final String? author;
  final List<int>? coverBytes;
  const ParsedBook({
    required this.text,
    this.title,
    this.author,
    this.coverBytes,
  });
}

/// Thrown when a file can't be read/parsed at all (→ "File unreadable" state).
class ParseFailure implements Exception {
  final String message;
  const ParseFailure(this.message);
  @override
  String toString() => 'ParseFailure: $message';
}

/// Extracts clean plain text from supported book formats. Each extractor is
/// best-effort and returns plain UTF-8 text; the caller decides what to do with
/// empty output (→ "No extractable text").
class TextParserService {
  static const Set<String> supportedFormats = {
    'txt',
    'md',
    'html',
    'htm',
    'rtf',
    'epub',
    'pdf',
    'docx',
  };

  static bool isSupported(String format) =>
      supportedFormats.contains(format.toLowerCase());

  /// Dispatches by [format] (a lowercase extension without the dot).
  /// Throws [ParseFailure] on unreadable input.
  static Future<ParsedBook> parse(File file, String format) async {
    try {
      switch (format.toLowerCase()) {
        case 'txt':
        case 'md':
          final raw = await _readText(file);
          return ParsedBook(text: format == 'md' ? _stripMarkdown(raw) : raw);
        case 'html':
        case 'htm':
          return ParsedBook(text: _stripHtml(await _readText(file)));
        case 'rtf':
          return ParsedBook(text: _stripRtf(await _readText(file)));
        case 'epub':
          return await _parseEpub(file);
        case 'pdf':
          return _parsePdf(await file.readAsBytes());
        case 'docx':
          return ParsedBook(text: docxToText(await file.readAsBytes()));
        default:
          throw ParseFailure('Unsupported format: $format');
      }
    } on ParseFailure {
      rethrow;
    } catch (e) {
      throw ParseFailure('$e');
    }
  }

  /// Parses an HTML document (e.g. a fetched web page) into clean text plus its
  /// `<title>` if present. Used by URL imports.
  static ParsedBook parseHtmlDocument(String html) {
    return ParsedBook(text: _stripHtml(html), title: _extractHtmlTitle(html));
  }

  /// Extracts text from raw PDF bytes (e.g. a PDF fetched from a URL).
  static ParsedBook parsePdfBytes(List<int> bytes) => _parsePdf(bytes);

  static String? _extractHtmlTitle(String html) {
    final match = RegExp(
      r'<title[^>]*>([\s\S]*?)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    if (match == null) return null;
    final title = _unescapeEntities(match.group(1)!).trim();
    return title.isEmpty ? null : title;
  }

  // --- Plain / markup ---

  static Future<String> _readText(File file) async {
    final bytes = await file.readAsBytes();
    // Decode as UTF-8, tolerating malformed sequences (covers most txt files).
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _stripMarkdown(String md) {
    return md
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ') // code fences
        .replaceAll(RegExp(r'`([^`]*)`'), r'$1') // inline code
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ') // images
        .replaceAllMapped(
          RegExp(r'\[([^\]]*)\]\([^)]*\)'),
          (m) => m[1] ?? '',
        ) // links
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '') // headers
        .replaceAll(RegExp(r'[*_~>]+'), '') // emphasis / quotes
        .trim();
  }

  static String _stripHtml(String html) {
    final cleaned = html
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ') // comments
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          ' ',
        );
    // Turn block-ending tags into paragraph breaks so structure survives.
    final withBreaks = cleaned
        .replaceAll(
          RegExp(r'</(p|div|h[1-6]|li|br)\s*>', caseSensitive: false),
          '\n\n',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n\n');
    final noTags = withBreaks.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return sanitizeText(_unescapeEntities(noTags));
  }

  static String _stripRtf(String rtf) {
    var s = rtf;
    s = s.replaceAll(RegExp(r"\\'[0-9a-fA-F]{2}"), ''); // hex escapes
    s = s.replaceAll(RegExp(r'\\par[d]?', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), ''); // control words
    s = s.replaceAll(RegExp(r'[{}]'), ''); // groups
    return s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  static final HtmlUnescape _htmlUnescape = HtmlUnescape();

  /// Decodes all HTML entities — named (`&laquo;`→«, `&mdash;`→—, …), decimal
  /// (`&#8230;`), and hex (`&#x2019;`).
  static String _unescapeEntities(String s) => _htmlUnescape.convert(s);

  static final RegExp _multiSpace = RegExp(r'[ \t]{2,}');
  static final RegExp _trailingSpace = RegExp(r'[ \t]+\n');
  static final RegExp _blankLines = RegExp(r'\n{3,}');

  /// Sanitizes extracted text: strips control characters, converts non-breaking
  /// spaces to plain spaces, drops zero-width / BOM characters, normalizes
  /// newlines, and collapses excess whitespace. Applied to every imported book
  /// (file or URL). Works on code points so no literal control chars live here.
  static String sanitizeText(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      if (r == 0x09 || r == 0x0A) {
        buf.writeCharCode(r); // keep tab and newline
      } else if (r < 0x20 || r == 0x7F) {
        continue; // drop other C0 control chars + DEL
      } else if (r == 0x00A0) {
        buf.write(' '); // non-breaking space -> plain space
      } else if (r == 0x200B || r == 0xFEFF) {
        continue; // zero-width space / BOM
      } else {
        buf.writeCharCode(r);
      }
    }
    var t = buf.toString().replaceAll('\r', '\n');
    t = t.replaceAll(_multiSpace, ' ');
    t = t.replaceAll(_trailingSpace, '\n');
    t = t.replaceAll(_blankLines, '\n\n');
    return t.trim();
  }

  // --- EPUB ---

  static Future<ParsedBook> _parseEpub(File file) async {
    final bytes = await file.readAsBytes();
    try {
      final book = await EpubReader.readBook(bytes);
      final buffer = StringBuffer();
      for (final chapter in book.Chapters ?? const <EpubChapter>[]) {
        _collectChapter(chapter, buffer);
      }
      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        List<int>? coverBytes;
        try {
          final coverImage = book.CoverImage;
          if (coverImage != null) {
            coverBytes = img.encodePng(coverImage);
          } else {
            final images = book.Content?.Images;
            if (images != null && images.isNotEmpty) {
              final firstImage = images.values.first;
              if (firstImage.Content != null && firstImage.Content!.isNotEmpty) {
                coverBytes = firstImage.Content;
              }
            }
          }
        } catch (_) {
          // Keep importing even if cover parsing fails.
        }
        return ParsedBook(
          text: text,
          title: book.Title,
          author: book.Author,
          coverBytes: coverBytes,
        );
      }
      // Parsed but empty → try the manual fallback below.
    } catch (_) {
      // epubx choked on a non-standard manifest — fall through to fallback.
    }
    return _parseEpubFallback(bytes);
  }

  static void _collectChapter(EpubChapter chapter, StringBuffer buffer) {
    final html = chapter.HtmlContent;
    if (html != null && html.isNotEmpty) {
      final text = _stripHtml(html);
      if (text.isNotEmpty) {
        buffer.write(text);
        buffer.write('\n\n');
      }
    }
    for (final sub in chapter.SubChapters ?? const <EpubChapter>[]) {
      _collectChapter(sub, buffer);
    }
  }

  /// Last-resort EPUB reader: unzip and strip every (x)html document, ordered by
  /// archive path. Loses precise spine order but recovers text from files epubx
  /// can't parse.
  static ParsedBook _parseEpubFallback(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docs =
          archive.files
              .where(
                (f) =>
                    f.isFile &&
                    RegExp(
                      r'\.x?html?$',
                      caseSensitive: false,
                    ).hasMatch(f.name),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      final buffer = StringBuffer();
      for (final f in docs) {
        final content = utf8.decode(
          f.content as List<int>,
          allowMalformed: true,
        );
        final text = _stripHtml(content);
        if (text.isNotEmpty) {
          buffer.write(text);
          buffer.write('\n\n');
        }
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        throw const ParseFailure('EPUB contained no extractable text');
      }
      return ParsedBook(text: text);
    } on ParseFailure {
      rethrow;
    } catch (e) {
      throw ParseFailure('Could not read EPUB: $e');
    }
  }

  // --- PDF ---

  static ParsedBook _parsePdf(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final text = PdfTextExtractor(document).extractText();
      return ParsedBook(text: text.trim());
    } finally {
      document.dispose();
    }
  }
}
