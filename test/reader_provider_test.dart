import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/models/book_meta.dart';
import 'package:speed_reading_app/providers/books_provider.dart';
import 'package:speed_reading_app/providers/reader_provider.dart';
import 'package:speed_reading_app/providers/settings_provider.dart';
import 'package:speed_reading_app/services/settings_service.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  late Directory tmp;
  late StorageService storage;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('readerprov');
    Hive.init(p.join(tmp.path, 'hive'));
    storage = await StorageService.open(docsDir: tmp);
    final now = DateTime(2026, 1, 1);
    await storage.addBook(
      BookMeta(
        id: 'b1',
        title: 'Resume Test',
        author: 'A',
        sourceFilePath: '/x.txt',
        format: 'txt',
        totalWords: 30,
        addedAt: now,
        lastOpenedAt: now,
        currentWordIndex: 10,
      ),
      List.generate(30, (i) => 'word$i').join(' '),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        storageServiceProvider.overrideWithValue(storage),
        settingsServiceProvider.overrideWithValue(SettingsService.inMemory()),
      ]);

  test('resumes at the saved word index', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final sub = container.listen(readerSessionProvider('b1'), (_, _) {});
    addTearDown(sub.close);

    final session = await container.read(readerSessionProvider('b1').future);
    expect(session.engine.currentWordIndex, 10);
    expect(session.text.wordCount, 30);
  });

  test('persists position to storage when the session is torn down', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final sub = container.listen(readerSessionProvider('b1'), (_, _) {});

    final session = await container.read(readerSessionProvider('b1').future);
    session.engine.jumpToWord(15);

    sub.close(); // no listeners → auto-dispose → onDispose persists
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(storage.getBook('b1')!.currentWordIndex, 15);
  });

  test('live settings changes propagate to the running engine', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final sub = container.listen(readerSessionProvider('b1'), (_, _) {});
    addTearDown(sub.close);

    final session = await container.read(readerSessionProvider('b1').future);
    expect(session.engine.wordsPerMinute, 300);

    container.read(settingsProvider.notifier).setWordsPerMinute(500);
    await Future<void>.delayed(Duration.zero);

    expect(session.engine.wordsPerMinute, 500);
  });

  test('missing text file surfaces an error', () async {
    await storage.addBook(
      BookMeta(
        id: 'b2',
        title: 'Ghost',
        author: 'A',
        sourceFilePath: '/y.txt',
        format: 'txt',
        totalWords: 5,
        addedAt: DateTime(2026, 1, 1),
        lastOpenedAt: DateTime(2026, 1, 1),
      ),
      'one two three four five',
    );
    // Delete the text file behind its back.
    File(p.join(tmp.path, 'books', 'b2.txt')).deleteSync();

    final container = makeContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(readerSessionProvider('b2').future),
      throwsA(isA<Object>()),
    );
  });
}
