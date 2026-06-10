import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../models/reader_settings.dart';
import '../models/tokenized_text.dart';
import '../services/reader_engine.dart';
import '../utils/word_tokenizer.dart';
import 'books_provider.dart';
import 'settings_provider.dart';

/// Everything the reader screen needs for one book: metadata, the tokenized
/// text (loaded lazily here), and the live [ReaderEngine].
class ReaderSession {
  final BookMeta book;
  final TokenizedText text;
  final ReaderEngine engine;
  const ReaderSession({
    required this.book,
    required this.text,
    required this.engine,
  });
}

/// Loads + tokenizes a book's text and wires up its engine.
///
/// All `ref` usage happens before the first `await` (Riverpod forbids touching
/// `ref` after an await or inside lifecycles). The engine is filled in after the
/// text loads; the pre-registered `listen`/`onDispose` reference it lazily.
/// Position persistence lives in the reader UI (where `ref` is safe to use on
/// exit / app-pause) — here we only tear the engine down.
final readerSessionProvider =
    FutureProvider.autoDispose.family<ReaderSession, String>((ref, bookId) async {
  final storage = ref.watch(storageServiceProvider);
  final settings = ref.read(settingsProvider);

  final book = storage.getBook(bookId);
  if (book == null) {
    throw StateError('Book not found: $bookId');
  }

  ReaderEngine? engine;

  ref.listen<ReaderSettings>(settingsProvider, (_, next) {
    engine?.updateSettings(
      wordsPerMinute: next.wordsPerMinute,
      wordsPerEntry: next.wordsPerEntry,
    );
  });
  // Persist position on teardown via the captured `storage` (a plain object —
  // Riverpod forbids using `ref` inside onDispose). This is the reliable resume
  // path; the UI also refreshes the library list on exit.
  ref.onDispose(() {
    final e = engine;
    if (e != null) {
      storage.updateProgress(bookId, e.currentWordIndex,
          lastOpenedAt: DateTime.now());
      e.dispose();
    }
  });

  final raw = await storage.readBookText(bookId);
  final text = WordTokenizer.tokenize(raw);

  engine = ReaderEngine(
    bookId: bookId,
    text: text,
    wordsPerMinute: settings.wordsPerMinute,
    wordsPerEntry: settings.wordsPerEntry,
    initialWordIndex: book.currentWordIndex,
  );

  return ReaderSession(book: book, text: text, engine: engine);
});
