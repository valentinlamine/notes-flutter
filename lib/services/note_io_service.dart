import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;
import '../utils/markdown_to_pdf.dart';

class NoteIOService {
  static Future<String?> importNote() async {
    final typeGroup = FileType.custom;
    final file = await FilePicker.platform.pickFiles(type: typeGroup, allowedExtensions: ['txt', 'md']);
    if (file == null || file.files.isEmpty) return null;
    final picked = file.files.first;
    final content = await File(picked.path!).readAsString();
    return content;
  }

  static Future<bool> exportNote(String title, String content) async {
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la note',
      fileName: '$title.md',
      allowedExtensions: ['md'],
      type: FileType.custom,
    );
    if (outputPath == null) return false;
    if (!outputPath.endsWith('.md')) outputPath += '.md';
    final file = File(outputPath);
    await file.writeAsString(content);
    return true;
  }

  static Future<bool> exportToPdf(String title, String content) async {
    final pdf = pw.Document();
    final nodes = md.Document().parseLines(content.split('\n'));
    final pdfWidgets = renderMarkdownToPdfWidgets(nodes);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ...pdfWidgets,
          ],
        ),
      ),
    );
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la note en PDF',
      fileName: '$title.pdf',
      allowedExtensions: ['pdf'],
      type: FileType.custom,
    );
    if (outputPath == null) return false;
    if (!outputPath.endsWith('.pdf')) outputPath += '.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return true;
  }
} 