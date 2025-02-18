import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import PDF viewer package
import 'package:pintar_akademik/page/book/PdfListPage.dart'; // Import PdfListPage

// Other imports
import '../dashboard/dashboard.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';
import 'nilaisiswa.dart';
import 'siswapage2.dart';

class AbsenSiswa extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const AbsenSiswa({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
    required this.namalengkap,
  }) : super(key: key);

  @override
  _AbsenSiswaState createState() => _AbsenSiswaState();
}

class _AbsenSiswaState extends State<AbsenSiswa> {
  List<String> subjectNames = []; // List to store subject names
  bool isLoading = true; // To manage loading state
  String? selectedSubject; // Subject selected by the user
  //Map<String, dynamic>? selectedSubjectDetails; // Subject details
  List<Map<String, dynamic>>? selectedSubjectDetails;

  @override
  void initState() {
    super.initState();
    _fetchSubjectData(); // Fetch subjects when the page loads
  }

  // Fetch subject data from the API
  Future<void> _fetchSubjectData() async {
    final url =
        'http://api-pinakad.pintarkerja.com/ambilsubyek2.php?class_id=${widget.classId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData =
            json.decode(response.body); // Parse the response body

        print('Response Data: $responseData'); // Debugging the response

        // Ensure that 'data' is a List and 'status' is success
        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          List<dynamic> data = responseData['data']; // Get the list of subjects

          setState(() {
            // Map the subjects into a list of names only
            subjectNames = [
              for (var subject in data) subject['name'] as String
            ];
            isLoading = false; // Set loading to false once data is fetched
          });
        } else {
          throw Exception('Data is not in the expected format');
        }
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false; // Set loading to false if error occurs
      });
    }
  }

  // Function to fetch subject details based on selected subject
  Future<void> _fetchSubjectDetails(String selectedSubject) async {
    final url =
        'http://api-pinakad.pintarkerja.com/get_subject_details2.php?nilai=$selectedSubject&student_id=${widget.studentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        // Ensure we fetch the array of details from `data`
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/images/logop.png',
            fit: BoxFit.contain,
            height: 40,
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
                child: CircularProgressIndicator(),
              ) // Display loading indicator while data is being fetched
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 16.0, top: 16.0, right: 16.0, bottom: 26.0),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardPage(
                            classId: widget.classId,
                            sectionId: widget.sectionId,
                            studentId: widget.studentId,
                            subjectId: widget.subjectId,
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
              Positioned(
                left: 144,
                top: 57,
                child: Container(
                  width: 72,
                  height:
                      120, // Increased height to accommodate text and image without overlap
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 10,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NilaiSiswa(
                                  classId: widget.classId,
                                  sectionId: widget.sectionId,
                                  studentId: widget.studentId,
                                  subjectId: widget.subjectId,
                                  alamat: widget.alamat,
                                  status: widget.status,
                                  namalengkap: widget.namalengkap,
                                ),
                              ),
                            );
                          },
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
                      ),
                      Positioned(
                        left: 0,
                        top: 50,
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
                        left: 21,
                        top: 18,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/images/nilai.png"),
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
                child: Container(
                  width: 72,
                  height: 88,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 10,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AbsenSiswa(
                                  classId: widget.classId,
                                  sectionId: widget.sectionId,
                                  studentId: widget.studentId,
                                  subjectId: widget.subjectId,
                                  alamat: widget.alamat,
                                  status: widget.status,
                                  namalengkap: widget.namalengkap,
                                ),
                              ),
                            );
                          },
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
                      ),
                      Positioned(
                        left: 0,
                        top: 57,
                        child: SizedBox(
                          width: 72,
                          height: 48,
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
                      Positioned(
                        left: 21,
                        top: 20,
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
              Positioned(
                left: 72,
                top: 47,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to the BookPage when the widget is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SiswaPage2(
                            classId: widget.classId,
                            sectionId: widget.sectionId,
                            studentId: widget.studentId,
                            subjectId: widget.subjectId,
                            alamat: widget.alamat,
                            status: widget.status,
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
