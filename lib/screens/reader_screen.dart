import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../models/reader_state.dart';
import '../providers/books_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/reader_colors.dart';
import '../widgets/focus_word_view.dart';
import '../widgets/helper_text_view.dart';
import '../widgets/quick_settings_modal.dart';
import '../widgets/reader_controls.dart';
import '../widgets/reader_progress_bar.dart';

/// The split-view speed reader (spec §3): focus area on top, full-text helper
/// below, controls at the bottom.
class ReaderScreen extends ConsumerWidget {
  final BookMeta book;
  const ReaderScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(readerSessionProvider(book.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Quick settings',
            onPressed: () => showQuickReaderSettings(context),
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ReaderError(bookId: book.id),
        data: (session) => _ReaderBody(session: session),
      ),
    );
  }
}

/// Shown when a book's text file is missing/corrupt (spec §7 edge handling):
/// explain and offer to remove the broken record.
class _ReaderError extends ConsumerWidget {
  final String bookId;
  const _ReaderError({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              "This book's text could not be loaded.",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The file may have been moved or deleted.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove from library'),
              onPressed: () async {
                await ref.read(booksProvider.notifier).removeBook(bookId);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderBody extends ConsumerStatefulWidget {
  final ReaderSession session;
  const _ReaderBody({required this.session});

  @override
  ConsumerState<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends ConsumerState<_ReaderBody> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Save position (and stop playback) when the app is backgrounded — the OS
    // may kill us before the provider's onDispose runs (spec §7).
    _lifecycle = AppLifecycleListener(onPause: _saveOnBackground);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _saveOnBackground() {
    widget.session.engine.pause();
    _savePosition();
  }

  /// Persists the current position so the library + resume reflect it. Safe to
  /// call from app-pause and from leaving the screen (ref is valid here, unlike
  /// the provider's onDispose).
  void _savePosition() {
    final engine = widget.session.engine;
    ref
        .read(booksProvider.notifier)
        .updateProgress(
          widget.session.book.id,
          engine.currentWordIndex,
          lastOpenedAt: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final colors = ReaderColors.resolve(settings, scheme);
    final fontFamily = readerFontFamily(settings.fontType);
    final engine = session.engine;

    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // --- Focus section ---
    final focusPanel = Container(
      color: colors.focusBackground,
      child: Column(
        children: [
          _TopInfoRow(
            wpm: settings.wordsPerMinute,
            wordsPerEntry: settings.wordsPerEntry,
            fontSize: settings.fontSize,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: engine.toggle,
              child: ValueListenableBuilder<ReaderState>(
                valueListenable: engine.state,
                builder: (context, _, _) => FocusWordView(
                  groupWords: engine.currentGroupWords,
                  fontSize: settings.fontSize,
                  fontFamily: fontFamily,
                  colors: colors,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<ReaderState>(
            valueListenable: engine.state,
            builder: (context, state, _) => ReaderProgressBar(
              currentWordIndex: state.currentWordIndex,
              totalWords: engine.total,
              wordsPerMinute: state.wordsPerMinute,
              elapsed: state.elapsedTime,
              colors: colors,
              onSeek: engine.seekToFraction,
            ),
          ),
        ],
      ),
    );

    // --- Helper section (toggleable, spec §5F) ---
    final helperPanel = HelperTextView(
      engine: engine,
      text: session.text,
      colors: colors,
      fontSize: settings.fontSize,
      fontFamily: fontFamily,
    );

    // Split by height in portrait, by width in landscape.
    final Widget splitArea;
    if (!settings.showHelperText) {
      splitArea = focusPanel;
    } else if (landscape) {
      splitArea = Row(
        children: [
          Expanded(child: focusPanel),
          const VerticalDivider(width: 1),
          Expanded(child: helperPanel),
        ],
      );
    } else {
      splitArea = Column(
        children: [
          Expanded(child: focusPanel),
          const Divider(height: 1),
          Expanded(child: helperPanel),
        ],
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _savePosition();
      },
      child: Container(
        color: colors.background,
        child: Column(
          children: [
            Expanded(child: splitArea),
            ReaderControls(engine: engine),
          ],
        ),
      ),
    );
  }
}

class _TopInfoRow extends StatelessWidget {
  final int wpm;
  final int wordsPerEntry;
  final double fontSize;
  const _TopInfoRow({
    required this.wpm,
    required this.wordsPerEntry,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Speed: $wpm WPM', style: style),
          Text('Words: $wordsPerEntry', style: style),
          Text('Font: ${fontSize.round()}', style: style),
        ],
      ),
    );
  }
}
