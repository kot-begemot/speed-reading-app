import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../services/book_import_service.dart';
import '../services/storage_service.dart';

/// Provides the [StorageService]. Has no sensible default (Hive must be opened
/// async first), so `main` overrides it; tests that touch books override it too.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw StateError('storageServiceProvider must be overridden'),
);

/// The library: list of [BookMeta] backed by the Hive box. Mutations write
/// through [StorageService], then refresh state from the box.
class BooksNotifier extends Notifier<List<BookMeta>> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  List<BookMeta> build() => _storage.getAllBooks();

  void _refresh() => state = _storage.getAllBooks();

  Future<void> addBook(BookMeta meta, String text) async {
    await _storage.addBook(meta, text);
    _refresh();
  }

  Future<void> removeBook(String id) async {
    await _storage.removeBook(id);
    _refresh();
  }

  Future<void> rename(String id, String title) async {
    await _storage.rename(id, title);
    _refresh();
  }

  Future<void> resetProgress(String id) async {
    await _storage.resetProgress(id);
    _refresh();
  }

  Future<void> updateProgress(String id, int currentWordIndex,
      {DateTime? lastOpenedAt}) async {
    await _storage.updateProgress(id, currentWordIndex,
        lastOpenedAt: lastOpenedAt);
    _refresh();
  }

  /// Imports a file into the library. Refreshes state only on success.
  Future<ImportResult> importFromFile(File file) async {
    final result = await BookImportService(_storage).importFile(file, state);
    if (result.status == ImportStatus.success) _refresh();
    return result;
  }

  /// Imports a book from a URL. Refreshes state only on success.
  Future<ImportResult> importFromUrl(String url) async {
    final result = await BookImportService(_storage).importUrl(url, state);
    if (result.status == ImportStatus.success) _refresh();
    return result;
  }

  /// Imports raw shared text as a book. Refreshes state only on success.
  Future<ImportResult> importFromText(String text) async {
    final result = await BookImportService(_storage).importText(text, state);
    if (result.status == ImportStatus.success) _refresh();
    return result;
  }
}

final booksProvider =
    NotifierProvider<BooksNotifier, List<BookMeta>>(BooksNotifier.new);
