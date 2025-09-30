import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHA256 + PDF Report',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _inputText = '';
  String _sha256 = '';
  String? _pickedFileName;
  List<int>? _pickedFileBytes;

  void _computeFromText() {
    final bytes = utf8.encode(_inputText);
    final digest = sha256.convert(bytes);
    setState(() {
      _sha256 = digest.toString();
      _pickedFileName = null;
      _pickedFileBytes = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        final digest = sha256.convert(bytes);
        setState(() {
          _sha256 = digest.toString();
          _pickedFileName = file.name;
          _pickedFileBytes = bytes;
          _inputText = '';
        });
      }
    }
  }

  Future<void> _createPdfReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SHA256 Report', style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Text('Generated: ${now.toIso8601String()}'),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Input type: ${_pickedFileName != null ? 'File' : 'Text'}'),
              pw.SizedBox(height: 8),
              if (_pickedFileName != null)
                pw.Text('File name: $_pickedFileName'),
              if (_inputText.isNotEmpty)
                pw.Text(
                    'Text (first 200 chars): ${_inputText.length > 200 ? "${_inputText.substring(0, 200)}..." : _inputText}'),
              pw.SizedBox(height: 12),
              pw.Text('SHA256:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_sha256),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file =
        File('${output.path}/sha256_report_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: file.path.split('/').last);
  }

  void _shareResult() {
    Share.share("SHA256:\n$_sha256");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SHA256 Hasher")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "أدخل النص هنا",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _computeFromText,
                  icon: const Icon(Icons.text_fields),
                  label: const Text("Compute Text"),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Pick File"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sha256.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(" تم الحساب من: $_inputType",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_fileName != null) Text(" الملف: $_fileName"),
                    const SizedBox(height: 8),
                    const Text(" SHA256:"),
                    SelectableText(
                      _sha256,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.blue),
                          onPressed: _copyToClipboard,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: _shareResult,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _sha256.isEmpty ? null : _createPdfReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Create PDF Report"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
