import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/books_provider.dart';
import '../services/book_import_service.dart';

/// Drives the Add-book flow (spec §2): let the user pick a source (file or
/// link), then parse + import with a loading state and surface the result.
Future<void> runAddBookFlow(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<_AddSource>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return;

  switch (source) {
    case _AddSource.file:
      await importFromFile(context, ref);
    case _AddSource.link:
      await importFromLink(context, ref);
  }
}

enum _AddSource { file, link }

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Import a file'),
            subtitle: const Text('TXT, EPUB, PDF, DOCX, and more'),
            onTap: () => Navigator.of(context).pop(_AddSource.file),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Paste a link'),
            subtitle: const Text('Read a web page or document by URL'),
            onTap: () => Navigator.of(context).pop(_AddSource.link),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// --- File import ---

Future<void> importFromFile(BuildContext context, WidgetRef ref) async {
  FilePickerResult? picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'txt', 'md', 'html', 'htm', 'rtf', 'epub', 'pdf', 'docx',
      ],
    );
  } catch (_) {
    if (context.mounted) _snack(context, 'Could not open the file picker');
    return;
  }

  if (picked == null) return; // user cancelled
  final path = picked.files.single.path;
  if (path == null) {
    if (context.mounted) _snack(context, 'File unreadable');
    return;
  }

  if (context.mounted) _showParsing(context);
  final result =
      await ref.read(booksProvider.notifier).importFromFile(File(path));
  _finish(context, result);
}

// --- URL import ---

Future<void> importFromLink(BuildContext context, WidgetRef ref) async {
  final url = await _promptUrl(context);
  if (url == null || url.trim().isEmpty || !context.mounted) return;

  _showParsing(context);
  final result = await ref.read(booksProvider.notifier).importFromUrl(url);
  _finish(context, result);
}

Future<String?> _promptUrl(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => const _UrlInputDialog(),
  );
}

class _UrlInputDialog extends StatefulWidget {
  const _UrlInputDialog();

  @override
  State<_UrlInputDialog> createState() => _UrlInputDialogState();
}

class _UrlInputDialogState extends State<_UrlInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Read from link'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          hintText: 'https://example.com/article',
          labelText: 'URL',
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Read'),
        ),
      ],
    );
  }
}

// --- Shared ---

void _showParsing(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ParsingDialog(),
  );
}

void _finish(BuildContext context, ImportResult result) {
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (context.mounted) _snack(context, _messageFor(result));
}

String _messageFor(ImportResult r) {
  switch (r.status) {
    case ImportStatus.success:
      return 'Added “${r.book!.title}”';
    case ImportStatus.duplicate:
      return '“${r.detail}” is already in your library';
    case ImportStatus.unsupported:
      return 'Unsupported source: ${r.detail}';
    case ImportStatus.noText:
      return 'No readable text found';
    case ImportStatus.unreadable:
      return 'Could not read that source';
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ParsingDialog extends StatelessWidget {
  const _ParsingDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 20),
          Text('Loading…'),
        ],
      ),
    );
  }
}
