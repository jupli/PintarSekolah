import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'absenanak.dart';
import 'jadwalmapel.dart';
import 'kalenderortu.dart';
import 'lihatnilai.dart';

class OrtuPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final int teacherId;
  final String matapelajaranId;
  final String alamat;
  final String status;
  final double latId;
  final double longId;
  final String namadepan;
  final String namabelakang;
  final String namalengkap;

  const OrtuPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.matapelajaranId,
    required this.alamat,
    required this.status,
    required this.latId,
    required this.longId,
    required this.namadepan,
    required this.namabelakang,
    required this.namalengkap,
  }) : super(key: key);

  @override
  _OrtuPageState createState() => _OrtuPageState();
}

class _OrtuPageState extends State<OrtuPage> {
  List<Map<String, dynamic>> TugasList = [];

  @override
  void initState() {
    super.initState();
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
          // GridView untuk menu
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
                        builder: (context) => KalenderOrtuPage(
                          classId: widget.classId,
                          sectionId: widget.sectionId,
                          studentId: widget.studentId,
                          subjectId: widget.subjectId,
                          alamat: widget.alamat,
                          status: widget.status,
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
                          Icons.circle_notifications,
                          size: 40,
                          color: Color.fromARGB(255, 252, 2, 2),
                        ),
                        Text("Pengumuman", style: TextStyle(fontSize: 13.0)),
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
                        builder: (context) => LihatNilaiPage(
                          classId: widget.classId,
                          sectionId: widget.sectionId,
                          studentId: widget.studentId,
                          subjectId: widget.subjectId,
                          alamat: widget.alamat,
                          status: widget.status,
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
                          Icons.school_rounded,
                          size: 40,
                          color: Colors.redAccent,
                        ),
                        Text("Lihat Nilai", style: TextStyle(fontSize: 13.0)),
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
                        builder: (context) => AbsenAnakPage(
                          classId: widget.classId,
                          sectionId: widget.sectionId,
                          studentId: widget.studentId,
                          subjectId: widget.subjectId,
                          alamat: widget.alamat,
                          status: widget.status,
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
                          color: Colors.greenAccent,
                        ),
                        Text("Lihat Absen", style: TextStyle(fontSize: 13.0)),
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
                        builder: (context) => JadwalMapelPage(
                          classId: widget.classId,
                          sectionId: widget.sectionId,
                          studentId: widget.studentId,
                          subjectId: widget.subjectId,
                          alamat: widget.alamat,
                          status: widget.status,
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
                          Icons.timer_rounded,
                          size: 40,
                          color: Colors.blueGrey,
                        ),
                        Text("Pelajaran", style: TextStyle(fontSize: 13.0)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Tambahkan widget teks di bagian atas
          Positioned(
            top: 280.0, // Atur jarak dari atas
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nama Orang Tua Murid: ${widget.namadepan} ${widget.namabelakang}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kelas ID Anak Murid: ${widget.classId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
