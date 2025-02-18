import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfViewPage extends StatefulWidget {
  final String pdfUrl;
  final String filePath;

  const PdfViewPage({
    Key? key,
    required this.pdfUrl,
    required this.filePath,
  }) : super(key: key);

  @override
  _PdfViewPageState createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  late String _pdfFilePath;

  @override
  void initState() {
    super.initState();
    _pdfFilePath = widget.filePath;

    // Jika file belum ada, coba unduh
    if (!File(_pdfFilePath).existsSync()) {
      _downloadPDF(widget.pdfUrl).then((filePath) {
        setState(() {
          _pdfFilePath = filePath; // Perbarui filePath setelah diunduh
        });
      });
    }
  }

  // Metode untuk mengonversi URL Google Drive ke URL unduh langsung
  String _getGoogleDriveDirectDownloadUrl(String url) {
    final regex = RegExp(r"drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view");
    final match = regex.firstMatch(url);

    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return '';
  }

  // Fungsi untuk mengunduh PDF
  Future<String> _downloadPDF(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/temp_pdf.pdf';
      final response = await http.get(Uri.parse(url));

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      print('Error downloading PDF: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer"),
      ),
      body: Center(
        child:
            CircularProgressIndicator(), // Menampilkan indikator loading jika belum ada PDF yang diunduh
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPdfPreviewDialog(context, widget.pdfUrl),
        child: const Icon(Icons.preview),
        tooltip: 'Preview PDF',
      ),
    );
  }

  Future<void> _showPdfPreviewDialog(
      BuildContext context, String fileUrl) async {
    final directDownloadUrl = _getGoogleDriveDirectDownloadUrl(fileUrl);
    if (directDownloadUrl.isNotEmpty) {
      final filePath = await _downloadPDF(directDownloadUrl);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Preview PDF'),
            content: filePath.isNotEmpty
                ? SizedBox(
                    width: double.infinity,
                    height: 400,
                    child: PDFView(
                      filePath: filePath,
                      onPageError: (page, error) {
                        print('Error on page $page: $error');
                      },
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
            actions: <Widget>[
              TextButton(
                child: const Text('Download'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Google Drive URL')),
      );
    }
  }
}
