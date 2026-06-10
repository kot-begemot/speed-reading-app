import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_reading_app/services/seed_service.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('seedtest');
    Hive.init(p.join(tmp.path, 'hive'));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('seeding is idempotent across repeated runs', () async {
    final storage = await StorageService.open(docsDir: tmp);

    await SeedService.ensureSeeded(storage);
    final afterFirst = storage.getAllBooks().length;

    await SeedService.ensureSeeded(storage);
    await SeedService.ensureSeeded(storage);
    final afterRepeat = storage.getAllBooks().length;

    expect(afterFirst, 2);
    expect(afterRepeat, 2);

    // Seeded books carry real word counts and on-disk text.
    final intro = storage.getBook('seed-intro');
    expect(intro, isNotNull);
    expect(intro!.totalWords, greaterThan(100));
    expect(await storage.readBookText('seed-intro'), contains('Speed reading'));
  });
}
