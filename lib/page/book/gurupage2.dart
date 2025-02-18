import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import PDF viewer package
import 'package:pintar_akademik/page/book/PdfListPage.dart'; // Import PdfListPage
import 'package:pintar_akademik/page/book/absensiguru.dart';
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

class GuruPage2 extends StatefulWidget {
  final int noidguru;
  final int mengajar;
  final String namaguru;

  const GuruPage2({
    Key? key,
    required this.noidguru,
    required this.mengajar,
    required this.namaguru,
  }) : super(key: key);

  @override
  _GuruPage2State createState() => _GuruPage2State();
}

class _GuruPage2State extends State<GuruPage2> {
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

  // Function to fetch and combine data from both APIs
  void _fetchSubjectDetailsGabungan(String selectedSubject) async {
    // Show loading spinner while fetching
    setState(() {
      isLoading = true;
    });

    // Fetch data from both APIs
    List<dynamic> data1 = await _fetchSubjectDetails(selectedSubject);
    List<dynamic> data2 = await _fetchSubjectDetails3(selectedSubject);

    // Combine both lists of data
    setState(() {
      selectedSubjectDetails = [...data1, ...data2];
      isLoading = false; // Set loading to false once data is fetched
    });
  }

  // Fetch subject data from the API
  Future<void> _fetchSubjectData() async {
    final url =
        'https://api-pinakad.pintarkerja.com/ambilsubyekguru.php?noidguru=${widget.noidguru}';

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
              for (var subject in data) subject['class_name'] as String
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
  Future<List<Map<String, dynamic>>> _fetchSubjectDetails(
      String? selectedSubject) async {
    if (selectedSubject == null) {
      print('Error: Selected subject is null');
      return [];
    }

    final url =
        'https://api-pinakad.pintarkerja.com/get_subject_detail3.php?nilai=$selectedSubject&noidguru=${widget.noidguru}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data1 = json.decode(response.body);
        print(data1);

        // Return the fetched data
        return (data1['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception('Failed to load subject details');
      }
    } catch (e) {
      print('Error: $e');
      return []; // Return empty list in case of error
    }
  }

  Future<List<dynamic>> _fetchSubjectDetails3(String selectedSubject) async {
    final url =
        'https://api-pinakad.pintarkerja.com/get_subject_details3a.php?nilai=$selectedSubject';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data2 = json.decode(response.body);
        print(data2);

        // Return the fetched data
        return (data2['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception('Failed to load subject details');
      }
    } catch (e) {
      print('Error: $e');
      return []; // Return empty list in case of error
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Dropdown for selecting the subject
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF748A9C), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: DropdownButton<String>(
                                value: selectedSubject,
                                hint: Text('Pilih Kelas'),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedSubject = newValue;
                                    print(selectedSubject);
                                    print(widget.noidguru);
                                    selectedSubjectDetails =
                                        null; // Reset subject details
                                  });
                                  if (newValue != null) {
                                    _fetchSubjectDetailsGabungan(
                                        newValue); // Fetch details on subject change
                                  }
                                },
                                items:
                                    subjectNames.map<DropdownMenuItem<String>>(
                                  (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ),
                          // Gambar di pojok kanan
                          Container(
                            width: 70,
                            height: 80,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image:
                                    AssetImage("assets/images/bukuwarna.png"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),

                    // Stack Progress Bar
                    Container(
                      width: 322,
                      height: 16,
                      child: Stack(
                        children: [
                          // Circular Indicators
                          Positioned(
                            left: 0,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color(0xFF00C1FF), // PR
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            top: 0,
                            child: SizedBox(
                              width: 35,
                              height: 16,
                              child: Text(
                                'PR',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 53,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color(0xFF48CFAE), // Tugas
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 72,
                            top: 0,
                            child: SizedBox(
                              width: 35,
                              height: 16,
                              child: Text(
                                'Tugas',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 124,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color(0xFFE85F78), // Belajar Online
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 142,
                            top: 0,
                            child: SizedBox(
                              width: 68,
                              height: 16,
                              child: Text(
                                'Belajar Online',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 227,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color(0xFFD9D9D9), // Belum Tersedia
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 245,
                            top: 0,
                            child: SizedBox(
                              width: 77,
                              height: 16,
                              child: Text(
                                'Belum Tersedia',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menampilkan detail mata pelajaran dalam bentuk Card
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: selectedSubjectDetails != null &&
                              selectedSubjectDetails!.isNotEmpty
                          ? Column(
                              children:
                                  selectedSubjectDetails!.map<Widget>((detail) {
                                // Determine card color based on wall_type
                                Color cardColor;
                                switch (detail['wall_type']) {
                                  case 'homework':
                                    cardColor =
                                        Colors.lightBlueAccent; // Blue for PR
                                    break;
                                  case 'tugas':
                                    cardColor = Colors
                                        .lightGreenAccent; // Green for TUGAS
                                    break;
                                  case 'belajar online':
                                    cardColor =
                                        const Color.fromARGB(255, 248, 2, 2)
                                            .withOpacity(
                                                0.3); // Red for BELAJAR ONLINE
                                    break;
                                  default:
                                    cardColor = Colors.white; // Default color
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 4.0,
                                    color:
                                        cardColor, // Set the color property of the Card
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${detail['about']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Deskripsi: ${detail['description']}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Pengajar: ${detail['first_name']} ${detail['last_name']}', // Adjust field if necessary
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Tanggal Selesai: ${detail['date_end']}', // Adjust field if necessary
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Pilih mata pelajaran untuk melihat informasi lebih lanjut.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                    )
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
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 70,
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
                                    image:
                                        AssetImage("assets/images/keluar.png"),
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
                        height: 88,
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
                                    image:
                                        AssetImage("assets/images/absensi.png"),
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
                    child: Container(
                      width: 72,
                      height: 100,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 72,
                              height: 100,
                              decoration: ShapeDecoration(
                                color: Color.fromARGB(255, 150, 0, 250),
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
                            top: 54,
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
                            left: 14,
                            top: 10,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("assets/images/boku.png"),
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NilaiGuru(
                                noidguru: widget.noidguru,
                                mengajar: widget.mengajar,
                                namaguru: widget.namaguru),
                          ),
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 120, // Enough space for the text and image
                        child: Stack(
                          children: [
                            // Background Container
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
                            // Text for "Nilai Siswa"
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
                            // Image Icon
                            Positioned(
                              left: 21,
                              top: 18,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/images/nilai.png"),
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
            )));
  }
}
