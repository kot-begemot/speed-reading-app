import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/services/book_import_service.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  late Directory tmp;
  late StorageService storage;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('urlimport');
    Hive.init(p.join(tmp.path, 'hive'));
    storage = await StorageService.open(docsDir: tmp);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  BookImportService withResponse(http.Response Function(http.Request) handler) {
    return BookImportService(storage,
        httpClient: MockClient((req) async => handler(req)));
  }

  test('imports an HTML page, using <title> and stripping tags', () async {
    final importer = withResponse((_) => http.Response(
          '<html><head><title>My Article</title></head>'
          '<body><h1>Heading</h1><p>Hello from the web. Read fast.</p></body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        ));

    final r = await importer.importUrl(
        'https://example.com/article', storage.getAllBooks());

    expect(r.status, ImportStatus.success);
    expect(r.book!.title, 'My Article');
    expect(r.book!.author, 'example.com');
    expect(r.book!.format, 'url');
    final text = await storage.readBookText(r.book!.id);
    expect(text, contains('Hello from the web'));
    expect(text, isNot(contains('<')));
  });

  test('adds https:// when the scheme is omitted', () async {
    final importer = withResponse((req) {
      expect(req.url.scheme, 'https');
      return http.Response('plain text body with several words here', 200,
          headers: {'content-type': 'text/plain'});
    });

    final r = await importer.importUrl('example.com/x', storage.getAllBooks());
    expect(r.status, ImportStatus.success);
  });

  test('non-200 responses are surfaced as unreadable', () async {
    final importer =
        withResponse((_) => http.Response('nope', 404));
    final r = await importer.importUrl(
        'https://example.com/missing', storage.getAllBooks());
    expect(r.status, ImportStatus.unreadable);
  });

  test('re-importing the same URL is a duplicate', () async {
    handler(http.Request _) => http.Response(
          '<title>Doc</title><p>one two three four five</p>',
          200,
          headers: {'content-type': 'text/html'},
        );
    final importer = withResponse(handler);

    final first =
        await importer.importUrl('https://x.dev/a', storage.getAllBooks());
    expect(first.status, ImportStatus.success);

    final second =
        await importer.importUrl('https://x.dev/a', storage.getAllBooks());
    expect(second.status, ImportStatus.duplicate);
  });
}
