import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_meta.dart';
import '../providers/books_provider.dart';
import 'reader_screen.dart';

/// Book metadata + actions (spec §1, §7): open, rename, reset progress, remove.
class BookDetailsScreen extends ConsumerWidget {
  final String bookId;
  const BookDetailsScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book =
        ref.watch(booksProvider).where((b) => b.id == bookId).firstOrNull;
    if (book == null) {
      return const Scaffold(body: Center(child: Text('Book not found')));
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (book.coverImagePath != null &&
              File(book.coverImagePath!).existsSync()) ...[
            Center(
              child: Container(
                height: 180,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.4 : 0.1,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(
                      theme.brightness == Brightness.dark ? 0.3 : 0.6,
                    ),
                    width: 0.8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(book.coverImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(book.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(book.author, style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          _row(theme, 'Format', book.format.toUpperCase()),
          _row(theme, 'Words', '${book.totalWords}'),
          _row(theme, 'Progress', '${(book.progress * 100).round()}%'),
          _row(theme, 'Position',
              '${book.currentWordIndex} / ${book.totalWords}'),
          _row(theme, 'Added', _fmtDate(book.addedAt)),
          _row(theme, 'Last opened', _fmtDate(book.lastOpenedAt)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Open reader'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _rename(context, ref, book),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Rename'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(booksProvider.notifier).resetProgress(book.id),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset progress'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error),
            onPressed: () => _remove(context, ref, book),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove from library'),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
      BuildContext context, WidgetRef ref, BookMeta book) async {
    final controller = TextEditingController(text: book.title);
    final result = await showDialog<String>(
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
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    final trimmed = result?.trim();
    if (trimmed != null && trimmed.isNotEmpty && trimmed != book.title) {
      await ref.read(booksProvider.notifier).rename(book.id, trimmed);
    }
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, BookMeta book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove book?'),
        content: Text('"${book.title}" will be removed from your library.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(booksProvider.notifier).removeBook(book.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}
