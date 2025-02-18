import 'package:pintar_akademik/page/material/materialpage.dart';
import 'package:flutter/material.dart';
import '../quiz/quiz.dart';
import '../tugas/tugas.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const DetailPage({
    Key? key,
    required this.item,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<List<String>> _presentStudents;
  late Future<List<String>> _absentStudents;

  @override
  void initState() {
    super.initState();
    _presentStudents = fetchPresentStudents();
    _absentStudents = fetchAbsentStudents();
  }

  Future<List<String>> fetchPresentStudents() async {
    final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/hadir.php?class_id=${widget.classId}&section_id=${widget.sectionId}&student_id=${widget.studentId}&subject_id=${widget.subjectId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final List<dynamic> students = data['data'];
        return students
            .map((item) => '${item['first_name']} ${item['last_name']}')
            .toList();
      } else {
        throw Exception('Failed to load present students');
      }
    } else {
      throw Exception('Failed to load present students');
    }
  }

  Future<List<String>> fetchAbsentStudents() async {
    final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/absen.php?class_id=${widget.classId}&section_id=${widget.sectionId}&student_id=${widget.studentId}&subject_id=${widget.subjectId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final List<dynamic> students = data['data'];
        return students
            .map((item) => '${item['first_name']} ${item['last_name']}')
            .toList();
      } else {
        throw Exception('Failed to load absent students');
      }
    } else {
      throw Exception('Failed to load absent students');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String day = widget.item['day'] ?? 'Tidak Ada Data';
    final String timeStart =
        '${widget.item['time_start'] ?? '00'}:${widget.item['time_start_min'] ?? '00'}';
    final String timeEnd =
        '${widget.item['time_end'] ?? '00'}:${widget.item['time_end_min'] ?? '00'}';
    final int teacherId = widget.item['teacher_id'] ?? 0;
    final String matapelajaranId = widget.item['name'] ?? 'Tidak Ada Data';
    final String kelas = widget.item['class'] ?? 'Tidak Ada Data';

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logop.png',
          fit: BoxFit.contain,
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 320,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 156,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/backmath.png'),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    top: 98,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style:
                          _textStyle(fontSize: 10, fontWeight: FontWeight.w300),
                    ),
                  ),
                  Positioned(
                    left: 79,
                    top: 98,
                    child: Text(
                      '$timeStart - $timeEnd',
                      textAlign: TextAlign.center,
                      style:
                          _textStyle(fontSize: 10, fontWeight: FontWeight.w300),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    top: 78,
                    child: Text(
                      'Guru Pengajar : $teacherId',
                      style:
                          _textStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Positioned(
                    left: 35,
                    top: 32,
                    child: Text(
                      'Pelajaran $matapelajaranId',
                      style:
                          _textStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    top: 53,
                    child: Text(
                      'Kelas $kelas',
                      style:
                          _textStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 181,
                    child: Text(
                      'Guru anda telah menyiapkan ',
                      style:
                          _textStyle(fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _menuIcon(
                            context,
                            'assets/images/itugas.png',
                            'Materi',
                            () {
                              // Print the values to the console
                              print('Student ID: ${widget.studentId}');
                              print('Class ID: ${widget.classId}');
                              print('Subject ID: ${widget.subjectId}');

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MateriPage(
                                    classId: widget.classId,
                                    sectionId: widget.sectionId,
                                    studentId: widget.studentId,
                                    subjectId: widget.subjectId,
                                    teacherId: teacherId,
                                    matapelajaranId: matapelajaranId,
                                    alamat: widget.alamat,
                                    status: widget.status,
                                  ),
                                ),
                              );
                            },
                          ),
                          _menuIcon(
                            context,
                            'assets/images/tasks.png',
                            'Tugas',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TugasPage(
                                    classId: widget.classId,
                                    sectionId: widget.sectionId,
                                    studentId: widget.studentId,
                                    subjectId: widget.subjectId,
                                    teacherId: teacherId,
                                    matapelajaranId: matapelajaranId,
                                    alamat: widget.alamat,
                                    status: widget.status,
                                  ),
                                ),
                              );
                            },
                          ),
                          // _menuIcon(
                          //   context,
                          //   'assets/images/quiz.png',
                          //   'Quiz',
                          //   () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => QuizPage(
                          //           classId: widget.classId,
                          //           sectionId: widget.sectionId,
                          //           studentId: widget.studentId,
                          //           subjectId: widget.subjectId,
                          //           teacherId: teacherId,
                          //           matapelajaranId: matapelajaranId,
                          //           alamat: widget.alamat,
                          //           status: widget.status,
                          //         ),
                          //       ),
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color.fromARGB(255, 8, 10, 109),
                      tabs: [
                        Tab(text: 'Murid Hadir'),
                        Tab(text: 'Murid Absen'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Murid yang hadir
                        FutureBuilder<List<String>>(
                          future: _presentStudents,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text('Tidak ada murid hadir'));
                            } else {
                              return ListView(
                                children: snapshot.data!
                                    .map((name) => ListTile(title: Text(name)))
                                    .toList(),
                              );
                            }
                          },
                        ),
                        // Tab 2: Murid yang absen
                        FutureBuilder<List<String>>(
                          future: _absentStudents,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text('Tidak ada murid absen'));
                            } else {
                              return ListView(
                                children: snapshot.data!
                                    .map((name) => ListTile(title: Text(name)))
                                    .toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _textStyle(
      {required double fontSize, required FontWeight fontWeight}) {
    return TextStyle(
      color: const Color(0xFF4B4B4B),
      fontSize: fontSize,
      fontFamily: 'Poppins',
      fontWeight: fontWeight,
      height: 0.12,
      letterSpacing: -0.32,
    );
  }

  Widget _menuIcon(BuildContext context, String assetPath, String label,
      VoidCallback onPressed) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white, // text color
            padding: const EdgeInsets.all(8.0),
            shape: const CircleBorder(),
          ),
          onPressed: onPressed,
          child: Image.asset(
            assetPath,
            width: 40,
            height: 40,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E8E),
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            height: 0.30,
            letterSpacing: -0.20,
          ),
        ),
      ],
    );
  }
}
