import 'dart:io';

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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium cover placeholder.
            Expanded(
              child: book.coverImagePath != null &&
                      File(book.coverImagePath!).existsSync()
                  ? Image.file(
                      File(book.coverImagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  scheme.primary.withOpacity(0.12),
                                  scheme.tertiary.withOpacity(0.03),
                                ]
                              : [
                                  scheme.primary.withOpacity(0.06),
                                  scheme.tertiary.withOpacity(0.02),
                                ],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Large serif watermark of the book's first letter
                          Positioned(
                            right: -8,
                            bottom: -16,
                            child: Text(
                              book.title.isNotEmpty ? book.title[0].toUpperCase() : 'B',
                              style: TextStyle(
                                fontSize: 110,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'serif',
                                color: (isDark ? Colors.white : scheme.primary)
                                    .withOpacity(isDark ? 0.04 : 0.05),
                              ),
                            ),
                          ),
                          // Center details tag & icon
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 28,
                                  color: (isDark ? Colors.white : scheme.primary)
                                      .withOpacity(isDark ? 0.45 : 0.35),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: (isDark ? Colors.white : scheme.primary)
                                        .withOpacity(isDark ? 0.08 : 0.06),
                                  ),
                                  child: Text(
                                    book.format.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: (isDark ? Colors.white : scheme.primary)
                                          .withOpacity(isDark ? 0.8 : 0.75),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
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
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: book.progress,
                      minHeight: 3,
                      backgroundColor: scheme.outlineVariant.withOpacity(
                        isDark ? 0.3 : 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(book.progress * 100).round()}% completed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
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
