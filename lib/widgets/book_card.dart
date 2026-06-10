import 'package:flutter/material.dart';

import '../models/book_meta.dart';

/// Actions available from a book card (spec §1).
enum BookCardAction { open, details, rename, reset, remove }

/// A single library book: cover placeholder, title, author, progress bar,
/// last-opened, and an overflow menu of actions. Rendered from [BookMeta] only
/// — never loads book text.
class BookCard extends StatelessWidget {
  final BookMeta book;
  final VoidCallback onOpen;
  final ValueChanged<BookCardAction> onAction;

  const BookCard({
    super.key,
    required this.book,
    required this.onOpen,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover placeholder.
            Expanded(
              child: Container(
                color: scheme.primaryContainer,
                alignment: Alignment.center,
                child: Icon(Icons.auto_stories,
                    size: 40, color: scheme.onPrimaryContainer),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: PopupMenuButton<BookCardAction>(
                          tooltip: 'Actions',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: onAction,
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: BookCardAction.open,
                                child: Text('Open')),
                            PopupMenuItem(
                                value: BookCardAction.details,
                                child: Text('Details')),
                            PopupMenuItem(
                                value: BookCardAction.rename,
                                child: Text('Rename')),
                            PopupMenuItem(
                                value: BookCardAction.reset,
                                child: Text('Reset progress')),
                            PopupMenuItem(
                                value: BookCardAction.remove,
                                child: Text('Remove')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: book.progress,
                      minHeight: 4,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(book.progress * 100).round()}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
