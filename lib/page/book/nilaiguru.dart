import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import PDF viewer package
import 'package:pintar_akademik/page/book/PdfListPage.dart'; // Import PdfListPage
import 'package:pintar_akademik/page/book/absensiguru.dart';
import 'package:pintar_akademik/page/book/gurupage2.dart';
import 'package:pintar_akademik/page/book/nilaiortu.dart';
import 'package:pintar_akademik/page/book/nilaisiswa.dart';
import 'package:pintar_akademik/page/dashboard/dashboardortu.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Other imports
import '../../main.dart';
import '../dashboard/dashboard.dart';
import '../dashboard/dashboardguru.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';
import 'nilaiguru.dart';

class NilaiGuru extends StatefulWidget {
  final int noidguru;
  final int mengajar;
  final String namaguru;

  const NilaiGuru({
    Key? key,
    required this.noidguru,
    required this.mengajar,
    required this.namaguru,
  }) : super(key: key);

  @override
  _NilaiGuruState createState() => _NilaiGuruState();
}

class _NilaiGuruState extends State<NilaiGuru> {
  List<String> subjectNames = []; // List to store subject names
  bool isLoading = true; // To manage loading state
  String? selectedSubject; // Subject selected by the user
  List<Map<String, dynamic>>? selectedSubjectDetails;

  @override
  void initState() {
    super.initState();
    _fetchSubjectData(); // Fetch subjects when the page loads
  }

  // Fetch subject data from the API
  Future<void> _fetchSubjectData() async {
    final url =
        'http://api-pinakad.pintarkerja.com/ambilsubyekguru.php?noidguru=${widget.noidguru.toString()}';
    // final url =
    //     'https://api-pinakad.pintarkerja.com/ambilsubyekguru.php?noidguru=${widget.noidguru}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Debugging the raw response body
        print('Response Body: ${response.body}');

        final responseData =
            json.decode(response.body); // Parse the response body

        // Debugging the parsed response data
        print('Response Data: $responseData');

        // Validate the status and format of data
        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          List<dynamic> data = responseData['data']; // Get the list of subjects
          print('Fetched data: $data'); // Debugging the fetched data

          // Ensure 'namek' exists in each item of 'data'
          for (var subject in data) {
            print(
                'Subject name: ${subject['class_name']}'); // Debug each 'namek'
          }

          setState(() {
            subjectNames = [
              for (var subject in data) subject['class_name'] as String
            ];
            // Debugging subject names after setState
            print('Subject names after setState: $subjectNames');
            isLoading = false; // Set loading to false once data is fetched
          });
        } else {
          throw Exception('Data is not in the expected format');
        }
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      // Debugging any errors that might occur
      print('Error: $e');
      setState(() {
        isLoading = false; // Set loading to false if error occurs
      });
    }
  }

  // Function to fetch subject details based on selected subject
  Future<void> _fetchSubjectDetails(String? selectedSubject) async {
    if (selectedSubject == null || selectedSubject.isEmpty) {
      print('Selected subject is null or empty');
      return;
    }

    // Check if widget.noidguru is null
    if (widget.noidguru == null) {
      print('Teacher ID is null');
      return;
    }

    // final url =
    //     'http://api-pinakad.pintarkerja.com/ambilnilaiguru.php?nilai=$selectedSubject&teacher_id=${widget.noidguru}';

    final url =
        'https://api-pinakad.pintarkerja.com/ambilnilaiguru.php?nilai=$selectedSubject&teacher_id=${widget.noidguru}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        setState(() {
          selectedSubjectDetails = (data['data'] as List).map((item) {
            // Safely handle each field with a default value if null
            return {
              'class_routine_id': item['class_routine_id']?.toString() ?? '',
              'class_id': item['class_id']?.toString() ?? '',
              'section_id': item['section_id']?.toString() ?? '',
              'subject_id': item['subject_id']?.toString() ?? '',
              'time_start': item['time_start']?.toString() ?? '',
              'time_end': item['time_end']?.toString() ?? '',
              'day': item['day'] ?? '', // Provide default empty string if null
              'teacher_id': item['teacher_id']?.toString() ?? '',
              'amend': item['amend'] ?? '',
              'amstart': item['amstart'] ?? '',
              'classroom_id': item['classroom_id']?.toString() ?? '',
              'name': item['name'] ?? '', // Default empty string if null
              'first_name': item['first_name'] ?? '',
              'student_class_id': item['student_class_id']?.toString() ?? '',
              'mark_id': item['mark_id']?.toString() ?? '',
              'student_id': item['student_id']?.toString() ?? '',
              'exam_id': item['exam_id']?.toString() ?? '',
              'mark_total': item['mark_total']?.toString() ?? '',
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load subject details');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        selectedSubjectDetails = null;
      });
    }

    print('Subject Details: $selectedSubject'); // Debugging the fetched data
  }

  List<Map<String, dynamic>> _groupedSubjectDetails() {
    Map<String, List<dynamic>> subjectMarks = {};

    // Mengelompokkan data berdasarkan mata pelajaran
    for (var detail in selectedSubjectDetails!) {
      String subjectName = detail['first_name'];
      String mark =
          detail['mark_total'].toString(); // Mendapatkan nilai dari exam

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
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 16.0, top: 16.0, right: 16.0, bottom: 26.0),
                child: Column(
                  children: [
                    // Dropdown for selecting subjects
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
                                value: (selectedSubject?.isNotEmpty ?? false) &&
                                        subjectNames.contains(selectedSubject)
                                    ? selectedSubject // Jika selectedSubject valid, gunakan nilai ini
                                    : null, // Jika invalid atau kosong, gunakan null
                                hint: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Pilih Kelas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                onChanged: (String? newValue) {
                                  print(
                                      'Dropdown selected value: $newValue'); // Debugging the newValue
                                  setState(() {
                                    selectedSubject = newValue ?? '';
                                    print(
                                        'Selected subject: $selectedSubject'); // Debugging the updated value
                                  });
                                  if (newValue != null) {
                                    _fetchSubjectDetails(
                                        newValue); // Fetch details on semester change
                                  }
                                },
                                items: subjectNames
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(value),
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

                    // Display subject details in a table
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: selectedSubjectDetails != null &&
                              selectedSubjectDetails!.isNotEmpty
                          ? Column(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 12,
                                    columns: const <DataColumn>[
                                      DataColumn(
                                        label: Text(
                                          'Nama Siswa',
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
                              ],
                            )
                          : Center(child: Text('No details available')),
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
                        builder: (context) => DashboardGuruPage(
                            noidguru: widget.noidguru,
                            mengajar: widget.mengajar,
                            namaguru: widget.namaguru),
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
                        builder: (context) => AbsensiGuru(
                            noidguru: widget.noidguru,
                            mengajar: widget.mengajar,
                            namaguru: widget.namaguru),
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
                        builder: (context) => GuruPage2(
                            noidguru: widget.noidguru,
                            mengajar: widget.mengajar,
                            namaguru: widget.namaguru),
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
