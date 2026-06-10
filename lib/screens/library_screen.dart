import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../providers/books_provider.dart';
import '../widgets/book_card.dart';
import 'add_book_flow.dart';
import 'book_details_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

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
    final controller = TextEditingController(text: book.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
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
    final books = ref.watch(booksProvider);
    // The search bar only appears once the library is large enough to need it.
    final showSearch = books.length >= _searchThreshold;
    final filtered = showSearch ? _filter(books) : books;
    final searching = showSearch && _query.trim().isNotEmpty;
    final continueBook = searching ? null : _continueReading(books);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => runAddBookFlow(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add book'),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text('No books yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tap “Add book” to import one',
            style: theme.textTheme.bodySmall,
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  final BookMeta book;
  final VoidCallback onOpen;
  const _ContinueCard({required this.book, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_fill,
                size: 44,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: book.progress,
                        minHeight: 5,
                        backgroundColor: scheme.onPrimaryContainer.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
