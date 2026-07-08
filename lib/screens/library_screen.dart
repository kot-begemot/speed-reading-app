import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../providers/books_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/rename_dialog.dart';
import 'add_book_flow.dart';
import 'book_details_screen.dart';
import 'reader_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  /// The library search bar only shows once there are at least this many books.
  static const int _searchThreshold = 10;

  final _searchController = TextEditingController();
  String _query = '';
  bool _isAddMenuExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookMeta> _filter(List<BookMeta> books) {
    if (_query.trim().isEmpty) return books;
    final q = _query.toLowerCase();
    return books.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.sourceFilePath.toLowerCase().contains(q);
    }).toList();
  }

  BookMeta? _continueReading(List<BookMeta> books) {
    if (books.isEmpty) return null;
    final sorted = [...books]
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return sorted.first;
  }

  void _openBook(BookMeta book) {
    ref
        .read(booksProvider.notifier)
        .updateProgress(
          book.id,
          book.currentWordIndex,
          lastOpenedAt: DateTime.now(),
        );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book)));
  }

  void _handleAction(BookMeta book, BookCardAction action) {
    switch (action) {
      case BookCardAction.open:
        _openBook(book);
      case BookCardAction.details:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailsScreen(bookId: book.id)),
        );
      case BookCardAction.rename:
        _renameDialog(book);
      case BookCardAction.reset:
        _confirm(
          title: 'Reset progress?',
          message: 'Reading progress for "${book.title}" will be set to 0%.',
          onConfirm: () =>
              ref.read(booksProvider.notifier).resetProgress(book.id),
        );
      case BookCardAction.remove:
        _confirm(
          title: 'Remove book?',
          message: '"${book.title}" will be removed from your library.',
          onConfirm: () => ref.read(booksProvider.notifier).removeBook(book.id),
        );
    }
  }

  Future<void> _renameDialog(BookMeta book) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => RenameDialog(initialValue: book.title),
    );
    final trimmed = newTitle?.trim();
    if (trimmed != null && trimmed.isNotEmpty && trimmed != book.title) {
      await ref.read(booksProvider.notifier).rename(book.id, trimmed);
    }
  }

  Future<void> _confirm({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final books = ref.watch(booksProvider);
    // The search bar only appears once the library is large enough to need it.
    final showSearch = books.length >= _searchThreshold;
    final filtered = showSearch ? _filter(books) : books;
    final searching = showSearch && _query.trim().isNotEmpty;
    final continueBook = searching ? null : _continueReading(books);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speed Reader',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      floatingActionButton: Material(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : scheme.outlineVariant.withValues(alpha: 0.8),
              width: 0.8,
            ),
          ),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            crossFadeState: _isAddMenuExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: InkWell(
              onTap: () => setState(() => _isAddMenuExpanded = true),
              borderRadius: BorderRadius.circular(24),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Container(
                width: 140,
                height: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Add book',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            secondChild: Container(
              width: 208,
              height: 48,
              alignment: Alignment.center,
              child: OverflowBox(
                minWidth: 208,
                maxWidth: 208,
                minHeight: 48,
                maxHeight: 48,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Row(
                    children: [
                      _FABOption(
                        icon: Icons.folder_open_rounded,
                        label: 'File',
                        onTap: () {
                          setState(() => _isAddMenuExpanded = false);
                          importFromFile(context, ref);
                        },
                        scheme: scheme,
                      ),
                      _FABDivider(scheme: scheme, isDark: isDark),
                      _FABOption(
                        icon: Icons.link_rounded,
                        label: 'Link',
                        onTap: () {
                          setState(() => _isAddMenuExpanded = false);
                          importFromLink(context, ref);
                        },
                        scheme: scheme,
                      ),
                      const Spacer(),
                      _FABDivider(scheme: scheme, isDark: isDark),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        onPressed: () => setState(() => _isAddMenuExpanded = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, file…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            Expanded(
              child: books.isEmpty
                  ? _emptyState(context)
                  : _content(context, filtered, continueBook),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(0.05),
              ),
              child: Icon(
                Icons.library_books_outlined,
                size: 44,
                color: scheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your library is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Import e-books or text files and start speed reading today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<BookMeta> filtered,
    BookMeta? continueBook,
  ) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        if (continueBook != null) ...[
          _sectionHeader(theme, 'Continue reading'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ContinueCard(
                book: continueBook,
                onOpen: () => _openBook(continueBook),
              ),
            ),
          ),
        ],
        _sectionHeader(theme, 'Library'),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No matches', style: theme.textTheme.bodyMedium),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final book = filtered[i];
                return BookCard(
                  book: book,
                  onOpen: () => _openBook(book),
                  onAction: (a) => _handleAction(book, a),
                );
              }, childCount: filtered.length),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  final BookMeta book;
  final VoidCallback onOpen;
  const _ContinueCard({required this.book, required this.onOpen});

  Widget _buildFallbackThumbnail(BuildContext context, String title, ColorScheme scheme) {
    final char = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            scheme.surfaceContainerHighest.withValues(alpha: 0.1),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF333333) : scheme.outlineVariant.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151515) : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.7),
                    width: 0.8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverImagePath != null &&
                          File(book.coverImagePath!).existsSync()
                      ? Image.file(
                          File(book.coverImagePath!),
                          fit: BoxFit.cover,
                        )
                      : _buildFallbackThumbnail(context, book.title, scheme),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: book.progress,
                              minHeight: 3.5,
                              backgroundColor: scheme.outlineVariant.withValues(
                                alpha: isDark ? 0.3 : 0.5,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(book.progress * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? scheme.primary.withValues(alpha: 0.15)
                      : scheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FABOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _FABOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FABDivider extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;

  const _FABDivider({required this.scheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8,
      height: 20,
      color: scheme.outlineVariant.withValues(alpha: isDark ? 0.6 : 0.8),
    );
  }
}
