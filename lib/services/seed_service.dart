import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_meta.dart';
import '../utils/word_tokenizer.dart';
import 'storage_service.dart';
import 'trainer_seed_data.dart';

/// Seeds a couple of bundled sample books on first run so the library isn't
/// empty before the import flow (Stage 3) exists.
/// Also seeds the trainer's baseline diagnostic texts.
///
/// Idempotent: guarded by a `shared_preferences` flag AND a per-book existence
/// check, so cold-restarting never duplicates seed books.
class SeedService {
  static const String _seededFlag = 'seeded_v1';

  static const List<_SeedBook> _books = [
    _SeedBook(
      id: 'seed-tortoise',
      title: 'The Tortoise and the Hare',
      author: 'Aesop',
      asset: 'assets/sample/the_tortoise_and_the_hare.txt',
    ),
    _SeedBook(
      id: 'seed-intro',
      title: 'Welcome to Speed Reading',
      author: 'Speed Reader',
      asset: 'assets/sample/speed_reading_intro.txt',
    ),
  ];

  static Future<void> ensureSeeded(StorageService storage) async {
    // Seed diagnostic texts if they are empty
    if (storage.getTrainingTexts('en').isEmpty && storage.getTrainingTexts('ru').isEmpty) {
      final diagTexts = TrainerSeedData.getDiagnosticTexts();
      for (final text in diagTexts) {
        await storage.saveTrainingText(text);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededFlag) == true) return;

    for (final book in _books) {
      if (storage.getBook(book.id) != null) continue;
      final text = await rootBundle.loadString(book.asset);
      final wordCount = WordTokenizer.tokenize(text).wordCount;
      final now = DateTime.now();
      await storage.addBook(
        BookMeta(
          id: book.id,
          title: book.title,
          author: book.author,
          sourceFilePath: book.asset,
          format: 'txt',
          totalWords: wordCount,
          addedAt: now,
          lastOpenedAt: now,
        ),
        text,
      );
    }

    await prefs.setBool(_seededFlag, true);
  }
}

class _SeedBook {
  final String id;
  final String title;
  final String author;
  final String asset;
  const _SeedBook({
    required this.id,
    required this.title,
    required this.author,
    required this.asset,
  });
}
