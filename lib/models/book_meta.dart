import 'package:hive_ce/hive.dart';

part 'book_meta.g.dart';

/// Metadata for one book in the library.
///
/// Per the storage architecture (see IMPLEMENTATION_PLAN.md), the full text is
/// NOT stored here — it lives in `books/<id>.txt`, loaded lazily on reader open.
/// Tokenized words are never persisted. This record stays small so the whole
/// box can be held in memory for instant library rendering and search.
@HiveType(typeId: 0)
class BookMeta {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final String author;

  /// Path of the originally imported file (for reference / dedupe).
  @HiveField(3)
  final String sourceFilePath;

  /// Lowercase format token, e.g. `txt`, `epub`, `pdf`, `docx`.
  @HiveField(4)
  final String format;

  /// Computed once at import; lets the library show length without loading text.
  @HiveField(5)
  final int totalWords;

  @HiveField(6)
  int currentWordIndex;

  @HiveField(7)
  final DateTime addedAt;

  @HiveField(8)
  DateTime lastOpenedAt;

  @HiveField(9)
  String? coverImagePath;

  BookMeta({
    required this.id,
    required this.title,
    required this.author,
    required this.sourceFilePath,
    required this.format,
    required this.totalWords,
    required this.addedAt,
    required this.lastOpenedAt,
    this.currentWordIndex = 0,
    this.coverImagePath,
  });

  /// Reading progress in `[0, 1]`. Derived — never stored, so it can't drift
  /// from `currentWordIndex` / `totalWords`.
  double get progress =>
      totalWords == 0 ? 0 : (currentWordIndex / totalWords).clamp(0.0, 1.0);
}
