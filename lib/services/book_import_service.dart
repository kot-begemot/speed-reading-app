import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/book_meta.dart';
import '../utils/word_tokenizer.dart';
import 'storage_service.dart';
import 'text_parser_service.dart';

/// Outcome of an import attempt (spec §2 "Import states").
enum ImportStatus { success, unsupported, unreadable, noText, duplicate }

class ImportResult {
  final ImportStatus status;
  final BookMeta? book;
  final String? detail;
  const ImportResult(this.status, {this.book, this.detail});
}

/// Turns a picked file into a stored book: detect format → parse → tokenize for
/// the word count → dedupe → write text + metadata. Pure orchestration; the
/// caller (BooksNotifier) refreshes library state on success.
class BookImportService {
  static const Uuid _uuid = Uuid();

  final StorageService storage;
  final http.Client _http;

  BookImportService(this.storage, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static String formatOf(String path) =>
      p.extension(path).replaceFirst('.', '').toLowerCase();

  Future<ImportResult> importFile(File file, List<BookMeta> existing) async {
    final format = formatOf(file.path);
    if (!TextParserService.isSupported(format)) {
      return ImportResult(ImportStatus.unsupported, detail: format);
    }

    final ParsedBook parsed;
    try {
      parsed = await TextParserService.parse(file, format);
    } catch (e) {
      return ImportResult(ImportStatus.unreadable, detail: '$e');
    }

    final text = TextParserService.sanitizeText(parsed.text);
    if (text.isEmpty) {
      return const ImportResult(ImportStatus.noText);
    }

    final totalWords = WordTokenizer.tokenize(text).wordCount;
    if (totalWords == 0) {
      return const ImportResult(ImportStatus.noText);
    }

    final title = _nonEmpty(parsed.title) ?? _titleFromFile(file.path);
    final author = _nonEmpty(parsed.author) ?? 'Unknown';

    final isDuplicate = existing.any((b) =>
        b.sourceFilePath == file.path ||
        (b.title.toLowerCase() == title.toLowerCase() &&
            b.totalWords == totalWords));
    if (isDuplicate) {
      return ImportResult(ImportStatus.duplicate, detail: title);
    }

    final now = DateTime.now();
    final meta = BookMeta(
      id: _uuid.v4(),
      title: title,
      author: author,
      sourceFilePath: file.path,
      format: format,
      totalWords: totalWords,
      addedAt: now,
      lastOpenedAt: now,
    );
    await storage.addBook(meta, text);
    return ImportResult(ImportStatus.success, book: meta);
  }

  /// Imports a book from a URL: fetches the page, extracts text (HTML, plain
  /// text, or PDF), then runs the same tokenize → dedupe → store pipeline.
  Future<ImportResult> importUrl(String rawUrl, List<BookMeta> existing) async {
    final url = _normalizeUrl(rawUrl);
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return const ImportResult(ImportStatus.unsupported, detail: 'URL');
    }

    final http.Response response;
    try {
      response = await _http
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (SpeedReader)'})
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      return ImportResult(ImportStatus.unreadable, detail: '$e');
    }
    if (response.statusCode != 200) {
      return ImportResult(ImportStatus.unreadable,
          detail: 'HTTP ${response.statusCode}');
    }

    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    String text;
    String? title;
    try {
      if (contentType.contains('application/pdf') ||
          uri.path.toLowerCase().endsWith('.pdf')) {
        text = TextParserService.parsePdfBytes(response.bodyBytes).text;
      } else if (contentType.contains('html') ||
          response.body.trimLeft().startsWith('<')) {
        final parsed = TextParserService.parseHtmlDocument(response.body);
        text = parsed.text;
        title = parsed.title;
      } else {
        text = response.body; // treat as plain text
      }
    } catch (e) {
      return ImportResult(ImportStatus.unreadable, detail: '$e');
    }

    text = TextParserService.sanitizeText(text);
    if (text.isEmpty) return const ImportResult(ImportStatus.noText);

    final totalWords = WordTokenizer.tokenize(text).wordCount;
    if (totalWords == 0) return const ImportResult(ImportStatus.noText);

    final finalTitle = _nonEmpty(title) ?? _titleFromUrl(uri);
    final isDuplicate = existing.any((b) =>
        b.sourceFilePath == url ||
        (b.title.toLowerCase() == finalTitle.toLowerCase() &&
            b.totalWords == totalWords));
    if (isDuplicate) {
      return ImportResult(ImportStatus.duplicate, detail: finalTitle);
    }

    final now = DateTime.now();
    final meta = BookMeta(
      id: _uuid.v4(),
      title: finalTitle,
      author: uri.host,
      sourceFilePath: url,
      format: 'url',
      totalWords: totalWords,
      addedAt: now,
      lastOpenedAt: now,
    );
    await storage.addBook(meta, text);
    return ImportResult(ImportStatus.success, book: meta);
  }

  static String _normalizeUrl(String raw) {
    var u = raw.trim();
    // Strip wrapping angle brackets / quotes and any internal whitespace.
    u = u.replaceAll(RegExp(r'''^[<"']+|[>"']+$'''), '');
    u = u.replaceAll(RegExp(r'\s+'), '');
    if (u.isEmpty) return u;
    return u.contains('://') ? u : 'https://$u';
  }

  static String _titleFromUrl(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final last = segments.isNotEmpty ? segments.last : uri.host;
    return _titleFromFile(last);
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    return (t != null && t.isNotEmpty) ? t : null;
  }

  static String _titleFromFile(String path) {
    final name = p.basenameWithoutExtension(path);
    final cleaned = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    return cleaned.isEmpty ? 'Untitled' : cleaned;
  }
}
