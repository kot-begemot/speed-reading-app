import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../models/reader_state.dart';
import '../providers/books_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/reader_colors.dart';
import '../models/reader_settings.dart';
import '../widgets/floating_reader_menu.dart';
import '../widgets/focus_word_view.dart';
import '../widgets/helper_text_view.dart';
import '../widgets/quick_settings_modal.dart';
import '../widgets/reader_progress_bar.dart';

/// The split-view speed reader (spec §3): focus area on top, full-text helper
/// below, controls at the bottom.
class ReaderScreen extends ConsumerWidget {
  final BookMeta book;
  const ReaderScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(readerSessionProvider(book.id));
    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: _ReaderError(bookId: book.id)),
      data: (session) => _ReaderBody(session: session),
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
  bool _toolbarsVisible = true;
  Timer? _idleTimer;

  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    // Save position (and stop playback) when the app is backgrounded
    _lifecycle = AppLifecycleListener(onPause: _saveOnBackground);
    _wasPlaying = widget.session.engine.isPlaying;
    widget.session.engine.state.addListener(_onReaderStateChanged);
    _resetIdleTimer();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.session.engine.state.removeListener(_onReaderStateChanged);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _saveOnBackground() {
    widget.session.engine.pause();
    _savePosition();
  }

  /// Persists the current position so the library + resume reflect it.
  void _savePosition() {
    final engine = widget.session.engine;
    ref.read(booksProvider.notifier).updateProgress(
          widget.session.book.id,
          engine.currentWordIndex,
          lastOpenedAt: DateTime.now(),
        );
  }

  void _onReaderStateChanged() {
    final isPlaying = widget.session.engine.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      _resetIdleTimer();
      if (!isPlaying) {
        if (!_toolbarsVisible) {
          setState(() {
            _toolbarsVisible = true;
          });
        }
      }
    }
  }

  void _handleUserInteraction() {
    _resetIdleTimer();
    if (!_toolbarsVisible) {
      setState(() {
        _toolbarsVisible = true;
      });
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    final engine = widget.session.engine;
    if (engine.isPlaying) {
      _idleTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && engine.isPlaying) {
          setState(() {
            _toolbarsVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final colors = ReaderColors.resolve(settings, scheme);
    final fontFamily = readerFontFamily(settings.fontType);
    final engine = session.engine;

    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final menuBottomPadding = bottomPadding + (_toolbarsVisible ? 90.0 : 24.0);

    // --- Focus section ---
    final focusPanel = Container(
      color: colors.focusBackground,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _handleUserInteraction();
                engine.toggle();
              },
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
              onSeek: (v) {
                _handleUserInteraction();
                engine.seekToFraction(v);
              },
            ),
          ),
        ],
      ),
    );

    // --- Helper section (toggleable, spec §5F) ---
    final helperPanel = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleUserInteraction(),
      onPointerMove: (_) => _handleUserInteraction(),
      child: HelperTextView(
        engine: engine,
        text: session.text,
        colors: colors,
        helperFontSize: settings.helperFontSize,
        fontFamily: fontFamily,
        bottomPadding: menuBottomPadding,
        booksDirPath: ref.read(storageServiceProvider).booksDirPath,
      ),
    );

    // Split by height in portrait, by width in landscape, animating toggle smoothly.
    final Widget splitArea = LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final viewportWidth = constraints.maxWidth;

        if (landscape) {
          return Row(
            children: [
              Expanded(child: focusPanel),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: settings.showHelperText ? 1.0 : 0.0,
                  child: Container(
                    width: 1.0,
                    color: isDark ? const Color(0xFF222222) : scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: settings.showHelperText ? (viewportWidth / 2) : 0.0,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 0.0,
                      maxWidth: viewportWidth / 2,
                      alignment: Alignment.centerLeft,
                      child: helperPanel,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(child: focusPanel),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: settings.showHelperText ? 1.0 : 0.0,
                  child: Container(
                    height: 1.0,
                    color: isDark ? const Color(0xFF222222) : scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: settings.showHelperText ? (viewportHeight / 2) : 0.0,
                  child: ClipRect(
                    child: OverflowBox(
                      minHeight: 0.0,
                      maxHeight: viewportHeight / 2,
                      alignment: Alignment.topCenter,
                      child: helperPanel,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );

    // Custom Top Bar with safe area padding
    final topPadding = MediaQuery.of(context).padding.top;
    final topBarHeight = 64.0 + topPadding;
    final topBar = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      height: _toolbarsVisible ? topBarHeight : 0,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(
            color: _toolbarsVisible 
                ? (isDark ? const Color(0xFF222222) : scheme.outlineVariant.withValues(alpha: 0.6))
                : Colors.transparent,
            width: 0.8,
          ),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _toolbarsVisible ? 1.0 : 0.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            height: topBarHeight,
            padding: EdgeInsets.fromLTRB(4, topPadding, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () {
                    _savePosition();
                    Navigator.of(context).pop();
                  },
                  color: colors.currentWord,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.session.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.currentWord,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${settings.wordsPerMinute} WPM  •  ${settings.wordsPerEntry} word${settings.wordsPerEntry > 1 ? 's' : ''}  •  Size ${settings.fontSize.round()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.currentWord.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  onPressed: () {
                    _handleUserInteraction();
                    showQuickReaderSettings(context);
                  },
                  color: colors.currentWord.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _savePosition();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _handleUserInteraction(),
          onPointerMove: (_) => _handleUserInteraction(),
          child: Stack(
            children: [
              Column(
                children: [
                  topBar,
                  Expanded(child: splitArea),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: bottomPadding + 16,
                child: AnimatedSlide(
                  offset: _toolbarsVisible ? Offset.zero : const Offset(0, 0.2),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: _toolbarsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: !_toolbarsVisible,
                      child: FloatingReaderMenu(
                        engine: engine,
                        visible: _toolbarsVisible,
                        onUserInteraction: _handleUserInteraction,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
