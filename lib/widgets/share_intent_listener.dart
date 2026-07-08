import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/book_meta.dart';
import '../providers/books_provider.dart';
import '../screens/add_book_flow.dart' show importResultMessage;
import '../screens/reader_screen.dart';
import '../services/book_import_service.dart';

/// Wraps the app and listens for content shared into it from the OS share sheet.
/// Routes each shared item to the right importer (link / file / raw text), then
/// opens the reader on the freshly-imported book. Reuses the same import
/// pipeline as the manual Add-book flow.
class ShareIntentListener extends ConsumerStatefulWidget {
  final Widget child;
  const ShareIntentListener({super.key, required this.child});

  @override
  ConsumerState<ShareIntentListener> createState() =>
      _ShareIntentListenerState();
}

class _ShareIntentListenerState extends ConsumerState<ShareIntentListener> {
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _busy = false;

  static final RegExp _urlInText = RegExp(r'https?://[^\s<>"]+');
  static final RegExp _bareDomain = RegExp(r'^[\w-]+(\.[\w-]+)+');

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    // Warm start: content shared while the app is already open.
    _sub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handle, onError: (_) {});
    // Cold start: the app was launched by a share.
    ReceiveSharingIntent.instance.getInitialMedia().then((items) {
      _handle(items);
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _handle(List<SharedMediaFile> items) async {
    if (items.isEmpty || _busy || !mounted) return;
    _busy = true;
    _showParsing();
    BookMeta? opened;
    ImportResult? last;
    try {
      for (final item in items) {
        final result = await _import(item);
        last = result;
        if (result.status == ImportStatus.success) opened = result.book;
      }
    } finally {
      _dismissParsing();
      _busy = false;
    }
    if (!mounted) return;
    if (opened != null) {
      _openReader(opened);
    } else if (last != null) {
      _snack(importResultMessage(last));
    }
  }

  /// Routes one shared item by its kind: text/url → link if it contains a URL,
  /// otherwise a raw-text book; anything else → treated as a file (the existing
  /// importer dispatches on the extension: pdf, epub, txt, …).
  Future<ImportResult> _import(SharedMediaFile item) {
    final notifier = ref.read(booksProvider.notifier);
    if (item.type == SharedMediaType.text ||
        item.type == SharedMediaType.url) {
      final content = item.path;
      final url = _extractUrl(content);
      return url != null
          ? notifier.importFromUrl(url)
          : notifier.importFromText(content);
    }
    return notifier.importFromFile(File(item.path));
  }

  /// Pulls the first http(s) link out of shared text, or a lone bare domain.
  String? _extractUrl(String text) {
    final m = _urlInText.firstMatch(text);
    if (m != null) return m.group(0);
    final t = text.trim();
    if (!t.contains(RegExp(r'\s')) && _bareDomain.hasMatch(t)) return t;
    return null;
  }

  // --- UI ---

  void _showParsing() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
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
      ),
    );
  }

  void _dismissParsing() {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  void _openReader(BookMeta book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
