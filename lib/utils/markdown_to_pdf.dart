import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;

List<pw.Widget> renderMarkdownToPdfWidgets(List<md.Node> nodes) {
  List<pw.Widget> widgets = [];
  for (final node in nodes) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
          widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)));
          break;
        case 'h2':
          widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
          break;
        case 'h3':
          widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
          break;
        case 'ul':
          widgets.add(
            pw.Bullet(
              text: node.children!.map((li) => li.textContent).join('\n'),
              style: pw.TextStyle(fontSize: 14),
            ),
          );
          break;
        case 'ol':
          for (int i = 0; i < node.children!.length; i++) {
            widgets.add(pw.Row(children: [
              pw.Text('${i + 1}. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(node.children![i].textContent, style: pw.TextStyle(fontSize: 14)),
            ]));
          }
          break;
        case 'blockquote':
          widgets.add(
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 2))),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text(node.textContent, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 14)),
            ),
          );
          break;
        case 'pre':
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(node.textContent, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
            ),
          );
          break;
        case 'p':
          widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 14)));
          break;
        default:
          widgets.addAll(renderMarkdownToPdfWidgets(node.children ?? []));
      }
    } else if (node is md.Text) {
      widgets.add(pw.Text(node.text, style: pw.TextStyle(fontSize: 14)));
    }
  }
  return widgets;
} 