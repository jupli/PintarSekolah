import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

// Other imports
import '../dashboard/dashboard.dart';
import '../mapel/mapel.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';

class BookPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const BookPage({
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
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> mathData = [];
  List<dynamic> ipsData = [];
  List<dynamic> bahasaIndonesiaData = [];
  List<dynamic> bahasaArabData = [];
  List<dynamic> informatikaData = [];
  List<dynamic> sejarahData = [];
  List<dynamic> kesenianData = [];
  bool isLoading = true;
  TabController? _tabController;
  int _selectedIndex = 1;
  String? pdfPath;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 7, vsync: this); // Adjust length to match tabs
    fetchData();
  }

  Future<void> fetchData() async {
    final urls = {
      'Matematika':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'IPS':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'Bahasa Indonesia':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'Bahasa Arab':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'Informatika':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'Sejarah':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'Kesenian':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
    };

    try {
      final responses = await Future.wait(
          urls.entries.map((entry) => http.get(Uri.parse(entry.value))));
      setState(() {
        mathData = json.decode(responses[0].body)['data'];
        ipsData = json.decode(responses[1].body)['data'];
        bahasaIndonesiaData = json.decode(responses[2].body)['data'];
        bahasaArabData = json.decode(responses[3].body)['data'];
        informatikaData = json.decode(responses[4].body)['data'];
        sejarahData = json.decode(responses[5].body)['data'];
        kesenianData = json.decode(responses[6].body)['data'];
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
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
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logop.png',
          fit: BoxFit.contain,
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Enable scrolling
          tabs: const [
            Tab(text: 'Matematika'),
            Tab(text: 'IPS'),
            Tab(text: 'Bahasa Indonesia'),
            Tab(text: 'Bahasa Arab'),
            Tab(text: 'Informatika'),
            Tab(text: 'Sejarah'),
            Tab(text: 'Kesenian'),
          ],
          labelColor: const Color.fromARGB(255, 255, 234, 0),
          unselectedLabelColor: Colors.white54,
        ),
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
          : TabBarView(
              controller: _tabController,
              children: [
                buildTabContent(mathData, 'Matematika', screenWidth),
                buildTabContent(ipsData, 'IPS', screenWidth),
                buildTabContent(
                    bahasaIndonesiaData, 'Bahasa Indonesia', screenWidth),
                buildTabContent(bahasaArabData, 'Bahasa Arab', screenWidth),
                buildTabContent(informatikaData, 'Informatika', screenWidth),
                buildTabContent(sejarahData, 'Sejarah', screenWidth),
                buildTabContent(kesenianData, 'Kesenian', screenWidth),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 31, 40, 174),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/bxs_home-alt-2.png'),
            ),
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //   icon: ImageIcon(
          //     AssetImage('assets/images/mapel3.png'),
          //   ),
          //   label: 'Mapel',
          // ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/bxs_book-alt.png'),
            ),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/entypo_video.png'),
            ),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/bell.png'),
            ),
            label: 'Notify',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/person.png'),
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: const Color.fromARGB(255, 31, 40, 174),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildTabContent(
      List<dynamic> data, String subject, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Daftar E-Book yang tersedia untuk Kamu :',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: screenWidth,
            height: 166,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/buku.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Buku Program Kelas:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final idn = item['book_id']?.toString() ?? 'No Id';
                final name = item['name'] ?? 'No Subject';
                final pdfUrl = item['file_name'] ?? '';

                return GestureDetector(
                  onTap: () {
                    if (pdfUrl.isNotEmpty) {
                      _showPdfPreviewDialog(pdfUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No PDF available to preview'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: screenWidth * 0.9,
                    height: 82,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 83,
                          top: 0,
                          child: Container(
                            width: screenWidth * 0.9 - 83,
                            height: 82,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 0),
                                  spreadRadius: 0,
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 131,
                          top: 40,
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF4B4B4B),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              height: 0.21,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 131,
                          top: 60,
                          child: Text(
                            'Preview',
                            style: TextStyle(
                              color: Color(0xFF4B4B4B),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              height: 0.21,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 1,
                          child: Container(
                            width: 79,
                            height: 80,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 0),
                                  spreadRadius: 0,
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 27,
                          top: 26,
                          child: Text(
                            idn,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4B4B4B),
                              fontSize: 10,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 0.30,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
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
          break;
        // case 1:
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => MapelPage(
        //         classId: widget.classId,
        //         sectionId: widget.sectionId,
        //         studentId: widget.studentId,
        //         subjectId: widget.subjectId,
        //         alamat: widget.alamat,
        //         status: widget.status,
        //       ),
        //     ),
        //   );
        //   break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookPage(
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
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => VideoPage(
                      classId: widget.classId,
                      sectionId: widget.sectionId,
                      studentId: widget.studentId,
                      subjectId: widget.subjectId,
                      alamat: widget.alamat,
                      status: widget.status,
                      namalengkap: widget.namalengkap,
                    )),
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => NotifyPage(
                      classId: widget.classId,
                      sectionId: widget.sectionId,
                      studentId: widget.studentId,
                      subjectId: widget.subjectId,
                      alamat: widget.alamat,
                      status: widget.status,
                      namalengkap: widget.namalengkap,
                    )),
          );
          break;
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage(
                      classId: widget.classId,
                      sectionId: widget.sectionId,
                      studentId: widget.studentId,
                      subjectId: widget.subjectId,
                      alamat: widget.alamat,
                      status: widget.status,
                      namalengkap: widget.namalengkap,
                    )),
          );
          break;
        default:
          break;
      }
    });
  }
}
