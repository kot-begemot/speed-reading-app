import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_meta.dart';
import '../models/trainer_profile.dart';
import '../models/training_content.dart';
import '../models/training_session.dart';

/// Owns book persistence: a Hive box of [BookMeta] (metadata only) plus the
/// on-disk `books/` directory that holds each book's extracted text and cover.
/// Also handles the reading trainer's persistence: user profiles, sessions,
/// and content library boxes.
class StorageService {
  StorageService._(
    this._box,
    this._trainerProfileBox,
    this._sessionBox,
    this._textBox,
    this._booksDir,
  );

  static const String boxName = 'books';

  final Box<BookMeta> _box;
  final Box<TrainerProfile> _trainerProfileBox;
  final Box<TrainingSession> _sessionBox;
  final Box<TrainingText> _textBox;
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
    if (!Hive.isAdapterRegistered(TrainerProfileAdapter().typeId)) {
      Hive.registerAdapter(TrainerProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(TrainerLanguageProfileAdapter().typeId)) {
      Hive.registerAdapter(TrainerLanguageProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(TrainingSessionAdapter().typeId)) {
      Hive.registerAdapter(TrainingSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(ExerciseResultAdapter().typeId)) {
      Hive.registerAdapter(ExerciseResultAdapter());
    }
    if (!Hive.isAdapterRegistered(TrainingTextAdapter().typeId)) {
      Hive.registerAdapter(TrainingTextAdapter());
    }
    if (!Hive.isAdapterRegistered(ComprehensionQuestionAdapter().typeId)) {
      Hive.registerAdapter(ComprehensionQuestionAdapter());
    }

    final box = await Hive.openBox<BookMeta>(boxName);
    final trainerProfileBox = await Hive.openBox<TrainerProfile>('trainer_profiles');
    final sessionBox = await Hive.openBox<TrainingSession>('training_sessions');
    final textBox = await Hive.openBox<TrainingText>('training_texts');

    final Directory base;
    if (kIsWeb) {
      base = Directory('web_placeholder');
    } else {
      base = docsDir ?? await getApplicationDocumentsDirectory();
    }
    final booksDir = Directory(p.join(base.path, 'books'));
    if (!kIsWeb) {
      if (!booksDir.existsSync()) {
        booksDir.createSync(recursive: true);
      }
    }
    return StorageService._(
      box,
      trainerProfileBox,
      sessionBox,
      textBox,
      booksDir,
    );
  }

  File _textFile(String id) => File(p.join(_booksDir.path, '$id.txt'));
  File coverFile(String id) => File(p.join(_booksDir.path, '$id.cover'));
  File imageFile(String id, String filename) => File(p.join(_booksDir.path, '${id}_img_$filename'));

  String get booksDirPath => _booksDir.path;

  List<BookMeta> getAllBooks() {
    final list = _box.values.toList();
    for (final book in list) {
      _resolveCoverPath(book);
    }
    return list;
  }

  BookMeta? getBook(String id) {
    final book = _box.get(id);
    if (book != null) {
      _resolveCoverPath(book);
    }
    return book;
  }

  void _resolveCoverPath(BookMeta book) {
    if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty) {
      final filename = p.basename(book.coverImagePath!);
      book.coverImagePath = p.join(_booksDir.path, filename);
    }
  }

  /// Persists a new book: writes its text to disk, then the metadata record.
  Future<void> addBook(BookMeta meta, String text) async {
    if (!kIsWeb) {
      await _textFile(meta.id).writeAsString(text);
    }
    await _box.put(meta.id, meta);
  }

  /// Reads a book's full text from disk. Throws if the file is missing — the
  /// reader surfaces this as a graceful error (Stage 7).
  Future<String> readBookText(String id) {
    if (kIsWeb) {
      return Future.value("Placeholder text on web since local files are not supported in browser.");
    }
    return _textFile(id).readAsString();
  }

  bool hasText(String id) {
    if (kIsWeb) return true;
    return _textFile(id).existsSync();
  }

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

    try {
      if (_booksDir.existsSync()) {
        final prefix = '${id}_img_';
        final files = _booksDir.listSync();
        for (final entity in files) {
          if (entity is File && p.basename(entity.path).startsWith(prefix)) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Reading Trainer CRUD
  // ---------------------------------------------------------------------------

  /// Retrieves the trainer profile, creating a default one if none exists.
  Future<TrainerProfile> getOrCreateTrainerProfile() async {
    const profileId = 'global_profile';
    var profile = _trainerProfileBox.get(profileId);
    if (profile == null) {
      profile = TrainerProfile(
        id: profileId,
        defaultLanguageCode: 'en',
        languageProfiles: {
          'en': TrainerLanguageProfile(
            languageCode: 'en',
            currentLevel: 1,
            successfulSessionsInRow: 0,
            bestEffectiveWpm: 0,
          ),
          'ru': TrainerLanguageProfile(
            languageCode: 'ru',
            currentLevel: 1,
            successfulSessionsInRow: 0,
            bestEffectiveWpm: 0,
          ),
        },
      );
      await _trainerProfileBox.put(profileId, profile);
    }
    return profile;
  }

  /// Updates or saves the trainer profile.
  Future<void> saveTrainerProfile(TrainerProfile profile) async {
    await _trainerProfileBox.put(profile.id, profile);
  }

  /// Reset trainer progress by deleting the profiles and session logs.
  Future<void> resetTrainerProgress() async {
    await _trainerProfileBox.clear();
    await _sessionBox.clear();
  }

  /// Saves a completed training session log.
  Future<void> saveTrainingSession(TrainingSession session) async {
    await _sessionBox.put(session.id, session);
  }

  /// Retrieves all training sessions sorted by date descending.
  List<TrainingSession> getAllSessions({String? languageCode}) {
    final list = _sessionBox.values.toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (languageCode != null) {
      return list.where((s) => s.languageCode == languageCode).toList();
    }
    return list;
  }

  /// Retrieves the most recent training sessions up to the specified limit.
  List<TrainingSession> getRecentSessions(int limit, {String? languageCode}) {
    final list = getAllSessions(languageCode: languageCode);
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  /// Saves a training text.
  Future<void> saveTrainingText(TrainingText text) async {
    await _textBox.put(text.id, text);
  }

  /// Retrieves all training texts for a specific language.
  List<TrainingText> getTrainingTexts(String languageCode) {
    return _textBox.values.where((t) => t.languageCode == languageCode).toList();
  }

  /// Retrieves training texts for a specific language and difficulty level.
  List<TrainingText> getTextsForLevel(String languageCode, int level) {
    return _textBox.values
        .where((t) => t.languageCode == languageCode && t.level == level)
        .toList();
  }

  /// Clears the training texts box.
  Future<void> clearAllTrainingTexts() async {
    await _textBox.clear();
  }
}
