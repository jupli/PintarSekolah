import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TugasPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final int teacherId;
  final String matapelajaranId;
  final String alamat;
  final String status;

  const TugasPage({
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
  _TugasPageState createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  List<Map<String, dynamic>> TugasList = [];

  @override
  void initState() {
    super.initState();
    startMeeting();
  }

  Future<void> startMeeting() async {
    final String url =
        'http://api-pinakad.pintarkerja.com/tugas.php?class_id=${widget.classId}&section_id=${widget.sectionId}&subject_id=${widget.subjectId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'error') {
          print('Error: ${data['message']}');
        } else {
          setState(() {
            if (data['data'] != null) {
              TugasList = List<Map<String, dynamic>>.from(data['data']);
            } else {
              TugasList = [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tugas Page : ${widget.matapelajaranId}'),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: TugasList.isNotEmpty
                ? TugasList.map((Tugas) {
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
                              Tugas['title'] ?? 'No Title',
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
                              Tugas['description'] ?? 'No File',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Positioned(
                          //   right: 20,
                          //   bottom: 20,
                          //   child: ElevatedButton(
                          //     onPressed: () {

                          //     },
                          //     // child: Text('Preview'),
                          //   ),
                          // ),
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
