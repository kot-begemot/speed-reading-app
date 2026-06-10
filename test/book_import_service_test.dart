import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/services/book_import_service.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  late Directory tmp;
  late StorageService storage;
  late BookImportService importer;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('importtest');
    Hive.init(p.join(tmp.path, 'hive'));
    storage = await StorageService.open(docsDir: tmp);
    importer = BookImportService(storage);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File write(String name, String content) {
    final f = File(p.join(tmp.path, name));
    f.writeAsStringSync(content);
    return f;
  }

  test('imports a TXT file with correct word count and title from filename',
      () async {
    final f = write('my_great_book.txt', 'one two three four five six.');
    final r = await importer.importFile(f, storage.getAllBooks());

    expect(r.status, ImportStatus.success);
    expect(r.book!.totalWords, 6);
    expect(r.book!.title, 'my great book');
    expect(r.book!.format, 'txt');
    expect(await storage.readBookText(r.book!.id), contains('one two three'));
  });

  test('unsupported extension is rejected', () async {
    final f = write('thing.xyz', 'whatever');
    final r = await importer.importFile(f, storage.getAllBooks());
    expect(r.status, ImportStatus.unsupported);
    expect(r.detail, 'xyz');
  });

  test('empty file → no extractable text', () async {
    final f = write('blank.txt', '   \n\n   ');
    final r = await importer.importFile(f, storage.getAllBooks());
    expect(r.status, ImportStatus.noText);
  });

  test('re-importing the same file is detected as a duplicate', () async {
    final f = write('dup.txt', 'alpha beta gamma');
    final first = await importer.importFile(f, storage.getAllBooks());
    expect(first.status, ImportStatus.success);

    final second = await importer.importFile(f, storage.getAllBooks());
    expect(second.status, ImportStatus.duplicate);
    // Library still has exactly one book.
    expect(storage.getAllBooks().length, 1);
  });

  test('markdown is stripped to plain text', () async {
    final f = write('notes.md',
        '# Title\n\nSome **bold** and a [link](http://x). Done.');
    final r = await importer.importFile(f, storage.getAllBooks());
    expect(r.status, ImportStatus.success);
    final text = await storage.readBookText(r.book!.id);
    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('http')));
    expect(text, contains('bold'));
    expect(text, contains('link'));
  });
}
