import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'providers/books_provider.dart';
import 'providers/settings_provider.dart';
import 'services/seed_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final storage = await StorageService.open();
  final settings = await SettingsService.open();
  await SeedService.ensureSeeded(storage);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        settingsServiceProvider.overrideWithValue(settings),
      ],
      child: const SpeedReadingApp(),
    ),
  );
}
