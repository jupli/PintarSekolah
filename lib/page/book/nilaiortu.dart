import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import PDF viewer package
import 'package:pintar_akademik/page/book/PdfListPage.dart'; // Import PdfListPage
import 'package:pintar_akademik/page/book/absenortu.dart';
import 'package:pintar_akademik/page/book/ortupage2.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Other imports
import '../../main.dart';
import '../dashboard/dashboard.dart';
import '../dashboard/dashboardortu.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';
import 'absensiswa.dart';
import 'siswapage2.dart';

class NilaiOrtu extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int parentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const NilaiOrtu({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.parentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
    required this.namalengkap,
  }) : super(key: key);

  @override
  _NilaiOrtuState createState() => _NilaiOrtuState();
}

class _NilaiOrtuState extends State<NilaiOrtu> {
  String? selectedSemester;
  List<String> subjectNames = []; // List to store subject names
  bool isLoading = false; // To manage loading state
  String? selectedSubject; // Subject selected by the user
  //Map<String, dynamic>? selectedSubjectDetails; // Subject details
  List<Map<String, dynamic>>? selectedSubjectDetails;

  @override
  void initState() {
    super.initState();
    selectedSemester = null; // Fetch subjects when the page loads
  }

  // Fungsi untuk mengambil detail mata pelajaran berdasarkan semester yang dipilih
  Future<void> _fetchSubjectDetails(String selectedSemester) async {
    final url =
        'https://api-pinakad.pintarkerja.com/get_subject_details2.php?nilai=$selectedSemester&student_id=${widget.studentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        setState(() {
          selectedSubjectDetails = (data['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      } else {
        throw Exception('Failed to load subject details');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        selectedSubjectDetails = null; // Reset details in case of error
      });
    }
  }

  // Mengelompokkan nilai berdasarkan nama mata pelajaran
  List<Map<String, dynamic>> _groupedSubjectDetails() {
    Map<String, List<dynamic>> subjectMarks = {};

    // Mengelompokkan data berdasarkan mata pelajaran
    for (var detail in selectedSubjectDetails!) {
      String subjectName = detail['subject_name'];
      String mark =
          detail['total_mark'].toString(); // Mendapatkan nilai dari exam

      if (subjectMarks.containsKey(subjectName)) {
        subjectMarks[subjectName]!.add(mark);
      } else {
        subjectMarks[subjectName] = [mark];
      }
    }

    // Membuat list final yang dikelompokkan berdasarkan mata pelajaran
    List<Map<String, dynamic>> groupedDetails = [];
    subjectMarks.forEach((subject, marks) {
      groupedDetails.add({
        'subject_name': subject,
        'marks': marks,
      });
    });

    return groupedDetails;
  }

  // Mengambil nama ujian yang unik untuk digunakan sebagai header kolom
  List<String> _getUniqueExamNames() {
    Set<String> examNames = {};
    for (var detail in selectedSubjectDetails!) {
      examNames.add(detail['exam_name']);
    }

    return examNames.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logop.png',
                fit: BoxFit.contain,
                height: 40,
              ),
              SizedBox(width: 65),
              Text(
                '${widget.namalengkap} - ${widget.classId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 69, 206, 236),
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        body: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(), // Menampilkan loading indicator
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 16.0, top: 16.0, right: 16.0, bottom: 26.0),
                child: Column(
                  children: [
                    // Dropdown untuk memilih semester
                    Column(
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              height: 48.0,
                              width: 320,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0xFF748A9C),
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedSemester,
                                hint: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Pilih Semester',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedSemester = newValue;
                                    selectedSubjectDetails = null;
                                  });
                                  if (newValue != null) {
                                    _fetchSubjectDetails(newValue);
                                  }
                                },
                                items: <String>[
                                  'Semester Ganjil',
                                  'Semester Genap'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 70,
                                height: 63,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/images/skor1.png"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 5),

                    // Menampilkan detail atau pesan berdasarkan state
                    selectedSemester == null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'PILIH SEMESTER UNTUK MELIHAT PENCAPAIAN NILAI',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : selectedSubjectDetails != null &&
                                selectedSubjectDetails!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 12,
                                    columns: const <DataColumn>[
                                      DataColumn(
                                        label: Text(
                                          'Mata Pelajaran',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Nilai',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        _groupedSubjectDetails().map((subject) {
                                      return DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text(
                                            subject['subject_name'],
                                            style: TextStyle(fontSize: 14),
                                          )),
                                          DataCell(
                                            Row(
                                              children: subject['marks']
                                                  .map<Widget>((mark) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Text(
                                                    mark.toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Tidak ada data untuk semester ini.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          height: 145, // Increased height to make space for the stacked items
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 65,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to the BookPage when the widget is tapped
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardOrtuPage(
                            classId: widget.classId,
                            sectionId: widget.sectionId,
                            studentId: widget.studentId,
                            subjectId: widget.subjectId,
                            parentId: widget.parentId,
                            alamat: widget.alamat,
                            status: widget.status,
                            namalengkap: widget.namalengkap),
                      ),
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 90,
                    decoration: ShapeDecoration(
                      color: Color(0xFF00C1FF),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Color(0xFF2EA0FC)),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 110,
                child: SizedBox(
                  width: 72,
                  height: 80,
                  child: Text(
                    'Jadwal\nKelas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 21,
                top: 75,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/jam1.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 288,
                top: 57,
                child: GestureDetector(
                  onTap: () async {
                    // Logout logic here
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(
                        'class_routine_cache'); // Remove the cached data
                    await prefs
                        .remove('cache_time'); // Remove the cache timestamp
                    await prefs.remove(
                        'user_token'); // Optional: remove user authentication token
                    // Add any other data you need to clear

                    // Navigate to login screen or home page after logging out
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyHomePage(), // Your login page widget
                      ),
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 90,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 10,
                          child: Container(
                            width: 72,
                            height: 92,
                            decoration: ShapeDecoration(
                              color: Color(0xFF00C1FF),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFF2EA0FC)),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 57,
                          child: SizedBox(
                            width: 72,
                            height: 15,
                            child: Text(
                              'Keluar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 21,
                          top: 20,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/keluar.png"),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 144,
                top: 42,
                child: Container(
                  width: 72,
                  height: 110,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 72,
                          height: 110,
                          decoration: ShapeDecoration(
                            color: Color.fromARGB(255, 249, 1, 208),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1, color: Color(0xFF748A9C)),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(50),
                                topRight: Radius.circular(50),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 57,
                        child: SizedBox(
                          width: 72,
                          height: 35,
                          child: Text(
                            'Nilai\nSiswa',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 10,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/images/bintang.png"),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 216,
                top: 57,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AbsenOrtu(
                          classId: widget.classId,
                          sectionId: widget.sectionId,
                          studentId: widget.studentId,
                          subjectId: widget.subjectId,
                          alamat: widget.alamat,
                          status: widget.status,
                          namalengkap: widget.namalengkap,
                          parentId: widget.parentId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 72,
                    height:
                        120, // Adjusted to prevent overlap and fit all elements
                    child: Stack(
                      children: [
                        // Background container
                        Positioned(
                          left: 0,
                          top: 10,
                          child: Container(
                            width: 72,
                            height: 92,
                            decoration: ShapeDecoration(
                              color: Color(0xFF00C1FF),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFF2EA0FC)),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Text: Absensi
                        Positioned(
                          left: 0,
                          top: 50, // Adjusted position for proper alignment
                          child: SizedBox(
                            width: 72,
                            height: 35,
                            child: Text(
                              'Absensi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Icon/Image
                        Positioned(
                          left: 21,
                          top: 18, // Adjusted for better alignment
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/absensi.png"),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 72,
                top: 47,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to the BookPage when the widget is tapped
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrtuPage2(
                            classId: widget.classId,
                            sectionId: widget.sectionId,
                            studentId: widget.studentId,
                            subjectId: widget.subjectId,
                            alamat: widget.alamat,
                            status: widget.status,
                            parentId: widget.parentId,
                            namalengkap: widget.namalengkap),
                      ),
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 100,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 19,
                          child: Container(
                            width: 72,
                            height: 100,
                            decoration: ShapeDecoration(
                              color: Color(0xFF00C1FF),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFF2EA0FC)),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 62,
                          child: SizedBox(
                            width: 72,
                            height: 35,
                            child: Text(
                              'Tugas\nPR',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          top: 25,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/tugaspr.png"),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
