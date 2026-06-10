import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/services/text_parser_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('parsertest');
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File writeBytes(String name, List<int> bytes) {
    final f = File(p.join(tmp.path, name));
    f.writeAsBytesSync(bytes);
    return f;
  }

  test('PDF text extraction (syncfusion round-trip)', () async {
    final doc = PdfDocument();
    doc.pages.add().graphics.drawString(
      'Hello PDF speed reader world',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
    );
    final bytes = await doc.save();
    doc.dispose();

    final f = writeBytes('doc.pdf', bytes);
    final parsed = await TextParserService.parse(f, 'pdf');
    expect(parsed.text, contains('Hello PDF'));
  });

  test('DOCX text extraction (built minimal docx)', () async {
    const documentXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>Hello docx paragraph one.</w:t></w:r></w:p>
    <w:p><w:r><w:t>Second paragraph here.</w:t></w:r></w:p>
  </w:body>
</w:document>''';
    const contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="xml" ContentType="application/xml"/>
</Types>''';

    final archive = Archive()
      ..addFile(_file('[Content_Types].xml', contentTypes))
      ..addFile(_file('word/document.xml', documentXml));
    final bytes = ZipEncoder().encode(archive)!;

    final f = writeBytes('doc.docx', bytes);
    final parsed = await TextParserService.parse(f, 'docx');
    expect(parsed.text, contains('Hello docx paragraph'));
    expect(parsed.text, contains('Second paragraph'));
  });

  test(
    'EPUB text extraction recovers chapter text (epubx or fallback)',
    () async {
      final archive = Archive()
        ..addFile(_file('mimetype', 'application/epub+zip'))
        ..addFile(
          _file('META-INF/container.xml', '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''),
        )
        ..addFile(
          _file('OEBPS/content.opf', '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test Book</dc:title>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
    <item id="c1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
  </spine>
</package>'''),
        )
        ..addFile(
          _file('OEBPS/chapter1.xhtml', '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body>
  <p>The quick brown fox reads at great speed.</p>
</body></html>'''),
        );
      final bytes = ZipEncoder().encode(archive)!;

      final f = writeBytes('book.epub', bytes);
      final parsed = await TextParserService.parse(f, 'epub');
      expect(parsed.text, contains('quick brown fox'));
    },
  );

  test('HTML is stripped to plain text', () async {
    final f = File(p.join(tmp.path, 'page.html'));
    f.writeAsStringSync(
      '<html><body><h1>Title</h1><p>Hello &amp; welcome.</p>'
      '<script>var x=1;</script></body></html>',
    );
    final parsed = await TextParserService.parse(f, 'html');
    expect(parsed.text, contains('Hello & welcome.'));
    expect(parsed.text, isNot(contains('<')));
    expect(parsed.text, isNot(contains('var x')));
  });

  test('HTML entities decode, including named ones like &laquo;', () {
    final parsed = TextParserService.parseHtmlDocument(
      '<p>He said &laquo;hello&raquo; &mdash; then left&hellip; '
      'caf&eacute; &amp; tea &#8364;5 &#x2019;okay&#x2019;</p>',
    );
    expect(parsed.text, contains('«hello»'));
    expect(parsed.text, contains('—'));
    expect(parsed.text, contains('…'));
    expect(parsed.text, contains('café & tea')); // &amp; -> &
    expect(parsed.text, contains('€5'));
    expect(parsed.text, isNot(contains('&laquo;'))); // no raw entities remain
    expect(parsed.text, isNot(contains('&eacute;')));
  });

  test('sanitizeText strips control chars and normalizes whitespace', () {
    const messy = 'a\u0007b\u00A0c\u200Bd   e\n\n\n\nf';
    final clean = TextParserService.sanitizeText(messy);
    expect(clean.contains('\u0007'), isFalse); // control char dropped
    expect(clean.contains('\u200B'), isFalse); // zero-width dropped
    expect(clean.contains('\u00A0'), isFalse); // nbsp converted
    expect(clean, contains('ab cd e')); // nbsp->space, runs collapsed
    expect(clean, isNot(contains('\n\n\n'))); // blank lines collapsed
  });

  test('RTF control words are stripped', () async {
    final f = File(p.join(tmp.path, 'doc.rtf'));
    f.writeAsStringSync(
      r'{\rtf1\ansi\deff0 {\fonttbl{\f0 Arial;}}\f0\fs24 Hello rtf world.\par}',
    );
    final parsed = await TextParserService.parse(f, 'rtf');
    expect(parsed.text, contains('Hello rtf world.'));
  });
}

ArchiveFile _file(String name, String content) {
  final bytes = Uint8List.fromList(utf8.encode(content));
  return ArchiveFile(name, bytes.length, bytes);
}
