import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:speed_reading_app/models/training_session.dart';
import 'package:speed_reading_app/providers/books_provider.dart';
import 'package:speed_reading_app/screens/trainer/progress_dashboard_screen.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  late StorageService storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('progress_dashboard_test_');
    Hive.init(tempDir.path);
    storage = await StorageService.open(docsDir: tempDir);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('chart bar with max effective WPM does not overflow', (tester) async {
    // A today session whose effective WPM equals the period max drives the
    // chart bar to its full height fraction (1.0) — this used to overflow
    // the fixed-height chart column by a couple of pixels.
    await storage.saveTrainingSession(TrainingSession(
      id: const Uuid().v4(),
      languageCode: 'en',
      startedAt: DateTime.now(),
      level: 1,
      finalWpm: 300,
      comprehensionPercent: 90,
      effectiveWpm: 270,
      qualified: true,
      exerciseResults: const [],
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: ProgressDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
