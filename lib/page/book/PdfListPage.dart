import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Untuk menampilkan PDF
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfListPage extends StatelessWidget {
  final String subject;
  final List<dynamic> pdfData;

  const PdfListPage({Key? key, required this.subject, required this.pdfData})
      : super(key: key);

  // Fungsi untuk mengunduh dan menyimpan PDF ke penyimpanan lokal
  Future<String?> _downloadAndSavePdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      } else {
        throw Exception("Failed to load PDF");
      }
    } catch (e) {
      print("Error downloading PDF: $e");
      return null;
    }
  }

  // Fungsi untuk mendownload dan menyimpan file PDF ke folder penyimpanan eksternal
  Future<void> _downloadToExternalStorage(
      String filePath, BuildContext context) async {
    try {
      final directory =
          await getExternalStorageDirectory(); // Untuk lokasi eksternal
      final newFilePath =
          '${directory?.path}/downloaded_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      // Menyalin file ke lokasi penyimpanan eksternal
      await file.copy(newFilePath);
      print("File downloaded to: $newFilePath");

      // Menampilkan notifikasi bahwa file telah berhasil diunduh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded to $newFilePath')),
      );
    } catch (e) {
      print('Error downloading file to external storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download file')),
      );
    }
  }

  // Metode untuk mendapatkan link langsung Google Drive
  String _getGoogleDriveDirectDownloadUrl(String url) {
    final regex = RegExp(r"drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view");
    final match = regex.firstMatch(url);

    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return '';
  }

  // Metode untuk menampilkan PDF dalam dialog
  Future<void> _showPdfPreviewDialog(
      BuildContext context, String fileUrl) async {
    final directDownloadUrl = _getGoogleDriveDirectDownloadUrl(fileUrl);
    if (directDownloadUrl.isNotEmpty) {
      final filePath = await _downloadAndSavePdf(directDownloadUrl);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Preview PDF'),
            content: filePath != null && filePath.isNotEmpty
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
                  if (filePath != null) {
                    _downloadToExternalStorage(filePath,
                        context); // Menyimpan file ke penyimpanan eksternal
                  }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDFs for $subject'),
      ),
      body: pdfData.isEmpty
          ? const Center(child: Text('No PDFs available'))
          : ListView.builder(
              itemCount: pdfData.length,
              itemBuilder: (context, index) {
                final item = pdfData[index];
                final name = item['name'] ?? 'No Name';
                final pdfUrl =
                    item['file_name'] ?? ''; // URL PDF yang sebenarnya

                return ListTile(
                  title: Text(name),
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  subtitle: const Text('Click to view the full PDF'),
                  onTap: () async {
                    if (pdfUrl.isNotEmpty) {
                      // Panggil dialog untuk preview PDF
                      await _showPdfPreviewDialog(context, pdfUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No PDF available to preview')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
