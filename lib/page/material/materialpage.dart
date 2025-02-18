import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class MateriPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final int teacherId;
  final String matapelajaranId;
  final String alamat;
  final String status;

  const MateriPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.matapelajaranId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _MateriPageState createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  List<Map<String, dynamic>> materiList = [];
  String? pdfPath;

  @override
  void initState() {
    super.initState();
    startMeeting();
  }

  Future<void> startMeeting() async {
    final String url =
        'http://api-pinakad.pintarkerja.com/material.php?class_id=${widget.classId}&subject_id=${widget.subjectId}&teacher_id=${widget.teacherId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'error') {
          print('Error: ${data['message']}');
        } else {
          setState(() {
            if (data['data'] != null) {
              materiList = List<Map<String, dynamic>>.from(data['data']);
            } else {
              materiList = [];
            }
          });
        }
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  String _extractFileId(String url) {
    final RegExp regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  Future<void> downloadAndSavePDF(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        pdfPath = file.path;
      });
    } else {
      print('Failed to download PDF');
    }
  }

  Future<void> _showPdfPreviewDialog(String fileUrl) async {
    final fileId = _extractFileId(fileUrl);
    final pdfDownloadUrl =
        'https://drive.google.com/uc?export=download&id=$fileId';

    if (pdfDownloadUrl.isEmpty) return;

    bool pdfDownloaded = false;

    await downloadAndSavePDF(pdfDownloadUrl).then((_) {
      pdfDownloaded = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Preview PDF'),
          content: pdfPath != null
              ? SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: PDFView(
                    filePath: pdfPath,
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
          actions: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () async {
                Navigator.of(context).pop();
                if (pdfDownloaded) {
                  // Handle download logic here if needed
                }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materi Page : ${widget.matapelajaranId}'),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: materiList.isNotEmpty
                ? materiList.map((materi) {
                    final pdfUrl = materi['file_name'] ?? '';
                    return Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 20,
                            top: 20,
                            child: Text(
                              materi['description'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 40,
                            child: Text(
                              materi['file_name'] ?? 'No File',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            bottom: 20,
                            child: ElevatedButton(
                              onPressed: () {
                                if (pdfUrl.isNotEmpty) {
                                  _showPdfPreviewDialog(pdfUrl);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('No PDF available to preview'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Preview'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                : [const Center(child: Text('No data available'))],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startMeeting,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
