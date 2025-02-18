import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'absenkelas.dart';
import 'jadwalguru.dart';
import 'nilaisiswa.dart';
import 'prsiswa.dart';

class GuruPage extends StatefulWidget {
  final int noidguru;
  final int mengajar;
  final String namaguru;

  const GuruPage({
    Key? key,
    required this.noidguru,
    required this.mengajar,
    required this.namaguru,
  }) : super(key: key);
  @override
  _GuruPageState createState() => _GuruPageState();
}

class _GuruPageState extends State<GuruPage> {
  List<Map<String, dynamic>> TugasList = [];

  @override
  void initState() {
    super.initState();
    // Load initial data or perform other setup tasks
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logop.png',
          fit: BoxFit.contain,
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // GridView for menu
          GridView.count(
            padding: const EdgeInsets.all(25),
            crossAxisCount: 3,
            children: <Widget>[
              Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JadwalGuruPage(
                          teacher_id:
                              widget.noidguru, // Pass noidguru as teacher_id
                          subject_id:
                              widget.mengajar, // Pass mengajar as subject_id
                          namaguru: widget.namaguru,
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.blue,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.schedule_rounded,
                          size: 40,
                          color: Color.fromARGB(255, 252, 2, 2),
                        ),
                        Text("Jadwal Kelas", style: TextStyle(fontSize: 13.0)),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NilaiPage(
                          teacher_id:
                              widget.noidguru, // Pass noidguru as teacher_id
                          subject_id:
                              widget.mengajar, // Pass mengajar as subject_id
                          namaguru: widget.namaguru,
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.blue,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 40,
                          color: Colors.redAccent,
                        ),
                        Text("Nilai Siswa", style: TextStyle(fontSize: 13.0)),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendancePage(
                          teacher_id:
                              widget.noidguru, // Pass noidguru as teacher_id
                          subject_id:
                              widget.mengajar, // Pass mengajar as subject_id
                          namaguru: widget.namaguru,
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.blue,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 40,
                          color: Colors.greenAccent,
                        ),
                        Text("Absen Kelas", style: TextStyle(fontSize: 13.0)),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrPage(
                          teacher_id:
                              widget.noidguru, // Pass noidguru as teacher_id
                          subject_id:
                              widget.mengajar, // Pass mengajar as subject_id
                          namaguru: widget.namaguru, classId: '',
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.blue,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.task_rounded,
                          size: 40,
                          color: Colors.blueGrey,
                        ),
                        Text("Tugas/PR", style: TextStyle(fontSize: 13.0)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Add text widget at the top
          Positioned(
            top: 280.0, // Adjust distance from the top
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selamat Datang: ${widget.namaguru} ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // You can add more static information or functionality here
                  // Text(
                  //   'Kelas ID: ',
                  //   style: const TextStyle(
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
