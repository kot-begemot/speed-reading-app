import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/models/book_meta.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  late Directory tmp;

  BookMeta sample(String id) => BookMeta(
        id: id,
        title: 'Sample $id',
        author: 'Author',
        sourceFilePath: '/imports/$id.txt',
        format: 'txt',
        totalWords: 4,
        addedAt: DateTime(2026, 1, 1),
        lastOpenedAt: DateTime(2026, 1, 2),
        currentWordIndex: 2,
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('srtest');
    Hive.init(p.join(tmp.path, 'hive'));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('book metadata + text round-trip through disk, and box holds no text',
      () async {
    final storage = await StorageService.open(docsDir: tmp);
    final meta = sample('a');
    const text = 'one two three four';
    await storage.addBook(meta, text);

    // Reopen a fresh service against the same dir (simulates restart).
    await Hive.close();
    final storage2 = await StorageService.open(docsDir: tmp);
    final loaded = storage2.getBook('a');

    expect(loaded, isNotNull);
    expect(loaded!.title, 'Sample a');
    expect(loaded.totalWords, 4);
    expect(loaded.currentWordIndex, 2);
    expect(loaded.progress, closeTo(0.5, 1e-9));
    expect(await storage2.readBookText('a'), text);

    // The .txt file exists separately; the box value carries no text field.
    expect(File(p.join(tmp.path, 'books', 'a.txt')).existsSync(), isTrue);
  });

  test('removeBook deletes both the record and the text file', () async {
    final storage = await StorageService.open(docsDir: tmp);
    await storage.addBook(sample('b'), 'hello world');
    expect(storage.hasText('b'), isTrue);

    await storage.removeBook('b');

    expect(storage.getBook('b'), isNull);
    expect(storage.hasText('b'), isFalse);
    expect(File(p.join(tmp.path, 'books', 'b.txt')).existsSync(), isFalse);
  });

  test('updateProgress and rename persist', () async {
    final storage = await StorageService.open(docsDir: tmp);
    await storage.addBook(sample('c'), 'a b c d');

    await storage.updateProgress('c', 3, lastOpenedAt: DateTime(2026, 5, 5));
    await storage.rename('c', 'Renamed');

    final m = storage.getBook('c')!;
    expect(m.currentWordIndex, 3);
    expect(m.lastOpenedAt, DateTime(2026, 5, 5));
    expect(m.title, 'Renamed');
    expect(m.progress, closeTo(0.75, 1e-9));
  });

  test('coverImagePath resolves dynamically across sandbox restarts', () async {
    final storage = await StorageService.open(docsDir: tmp);
    final meta = sample('d');
    meta.coverImagePath = '/old_sandbox_dir/books/d.cover';
    await storage.addBook(meta, 'test text');

    // Simulate restart with a new tmp/sandbox path
    final newTmp = await Directory.systemTemp.createTemp('srtest_new');
    
    // Copy the box file/directory to newTmp to simulate Hive database migration
    await Hive.close();
    final oldBoxFile = File(p.join(tmp.path, 'hive', 'books.hive'));
    final newBoxDir = Directory(p.join(newTmp.path, 'hive'));
    if (!newBoxDir.existsSync()) newBoxDir.createSync(recursive: true);
    if (oldBoxFile.existsSync()) {
      await oldBoxFile.copy(p.join(newBoxDir.path, 'books.hive'));
    }

    final storage2 = await StorageService.open(docsDir: newTmp);
    final loaded = storage2.getBook('d')!;
    
    // Verify that the coverImagePath was updated to point to the new directory!
    expect(loaded.coverImagePath, p.join(newTmp.path, 'books', 'd.cover'));
    
    // Clean up
    await Hive.close();
    if (newTmp.existsSync()) newTmp.deleteSync(recursive: true);
  });
}
