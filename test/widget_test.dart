import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/app.dart';
import 'package:speed_reading_app/providers/books_provider.dart';
import 'package:speed_reading_app/services/storage_service.dart';
import 'package:speed_reading_app/providers/baseline_provider.dart';
import 'package:speed_reading_app/models/trainer_profile.dart';

void main() {
  late Directory tmp;
  late StorageService storage;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('libtest');
    Hive.init(p.join(tmp.path, 'hive'));
    storage = await StorageService.open(docsDir: tmp);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  testWidgets('library boots with header and empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          trainerProfileProvider.overrideWithValue(
            AsyncValue.data(
              TrainerProfile(
                id: 'global_profile',
                defaultLanguageCode: 'en',
                languageProfiles: {
                  'en': TrainerLanguageProfile(
                    languageCode: 'en',
                    currentLevel: 1,
                    successfulSessionsInRow: 0,
                    bestEffectiveWpm: 0,
                  ),
                },
              ),
            ),
          ),
          activeTrainerLanguageProvider.overrideWith(() => MockActiveLanguageNotifier()),
        ],
        child: const SpeedReadingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Speed Reader'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class MockActiveLanguageNotifier extends ActiveLanguageNotifier {
  @override
  String build() => 'en';
}
