import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/share_intent_listener.dart';

class SpeedReadingApp extends ConsumerWidget {
  const SpeedReadingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Speed Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const ShareIntentListener(child: LibraryScreen()),
    );
  }
}
