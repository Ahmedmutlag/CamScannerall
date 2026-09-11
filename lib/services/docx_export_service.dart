import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Builds a minimal, valid .docx (OOXML) file directly — no external
/// converter, no network call. Since there is no reliable fully-offline
/// way to preserve the exact visual layout of a scanned page, the
/// conversion is text-based: each page's OCR-extracted text becomes an
/// editable, right-to-left-aware paragraph in the Word document, which is
/// what "convert to an editable Word file" means in practice for a
/// scanned document.
class DocxExportService {
  Uint8List buildDocx({required String title, required List<String> pagesText}) {
    final archive = Archive();

    void addText(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addText('[Content_Types].xml', _contentTypesXml);
    addText('_rels/.rels', _relsXml);
    addText('docProps/core.xml', _coreXml(title));
    addText('word/document.xml', _documentXml(pagesText));

    final bytes = ZipEncoder().encode(archive)!;
    return Uint8List.fromList(bytes);
  }

  static const _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
</Types>''';

  static const _relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
</Relationships>''';

  String _coreXml(String title) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:title>${_escape(title)}</dc:title>
</cp:coreProperties>''';

  String _documentXml(List<String> pagesText) {
    final buffer = StringBuffer();
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>''');

    for (var i = 0; i < pagesText.length; i++) {
      final lines = pagesText[i].split('\n');
      for (final line in lines) {
        buffer.write('''
<w:p>
  <w:pPr><w:bidi/></w:pPr>
  <w:r><w:t xml:space="preserve">${_escape(line)}</w:t></w:r>
</w:p>''');
      }
      if (i != pagesText.length - 1) {
        buffer.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }
    }

    buffer.write('''
<w:sectPr>
  <w:pgSz w:w="11906" w:h="16838"/>
  <w:pgMar w:top="1417" w:right="1417" w:bottom="1417" w:left="1417"/>
</w:sectPr>
</w:body>
</w:document>''');
    return buffer.toString();
  }

  String _escape(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
