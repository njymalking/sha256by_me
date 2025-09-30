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

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHA256 + PDF Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Enter text to hash'),
              minLines: 1,
              maxLines: 4,
              onChanged: (v) => _inputText = v,
            ),
}
