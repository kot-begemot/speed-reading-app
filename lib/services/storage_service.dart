import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_meta.dart';

/// Owns book persistence: a Hive box of [BookMeta] (metadata only) plus the
/// on-disk `books/` directory that holds each book's extracted text and cover.
///
/// The library reads only the box (cheap). Text is read lazily via
/// [readBookText] when the reader opens. Removing a book deletes both the Hive
/// record and its files.
class StorageService {
  StorageService._(this._box, this._booksDir);

  static const String boxName = 'books';

  final Box<BookMeta> _box;
  final Directory _booksDir;

  /// Opens the box and ensures the books directory exists.
  ///
  /// [docsDir] overrides the documents directory (used by tests to avoid the
  /// `path_provider` plugin). Hive must already be initialized by the caller
  /// (`Hive.initFlutter()` in `main`, or `Hive.init(tmp)` in tests).
  static Future<StorageService> open({Directory? docsDir}) async {
    if (!Hive.isAdapterRegistered(BookMetaAdapter().typeId)) {
      Hive.registerAdapter(BookMetaAdapter());
    }
    final box = await Hive.openBox<BookMeta>(boxName);
    final base = docsDir ?? await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(base.path, 'books'));
    if (!booksDir.existsSync()) {
      booksDir.createSync(recursive: true);
    }
    return StorageService._(box, booksDir);
  }

  File _textFile(String id) => File(p.join(_booksDir.path, '$id.txt'));
  File coverFile(String id) => File(p.join(_booksDir.path, '$id.cover'));

  List<BookMeta> getAllBooks() => _box.values.toList();

  BookMeta? getBook(String id) => _box.get(id);

  /// Persists a new book: writes its text to disk, then the metadata record.
  Future<void> addBook(BookMeta meta, String text) async {
    await _textFile(meta.id).writeAsString(text);
    await _box.put(meta.id, meta);
  }

  /// Reads a book's full text from disk. Throws if the file is missing — the
  /// reader surfaces this as a graceful error (Stage 7).
  Future<String> readBookText(String id) => _textFile(id).readAsString();

  bool hasText(String id) => _textFile(id).existsSync();

  Future<void> updateBook(BookMeta meta) => _box.put(meta.id, meta);

  /// Updates reading position + last-opened timestamp.
  Future<void> updateProgress(String id, int currentWordIndex,
      {DateTime? lastOpenedAt}) async {
    final meta = _box.get(id);
    if (meta == null) return;
    meta.currentWordIndex = currentWordIndex;
    meta.lastOpenedAt = lastOpenedAt ?? meta.lastOpenedAt;
    await _box.put(id, meta);
  }

  Future<void> rename(String id, String title) async {
    final meta = _box.get(id);
    if (meta == null) return;
    meta.title = title;
    await _box.put(id, meta);
  }

  Future<void> resetProgress(String id) => updateProgress(id, 0);

  /// Removes the metadata record AND its text/cover files.
  Future<void> removeBook(String id) async {
    await _box.delete(id);
    final tf = _textFile(id);
    if (tf.existsSync()) await tf.delete();
    final cf = coverFile(id);
    if (cf.existsSync()) await cf.delete();
  }
}
