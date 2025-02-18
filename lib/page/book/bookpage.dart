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

class _BookPageState extends State<BookPage> {
  Map<String, List<dynamic>> subjectData = {};
  bool isLoading = true;
  int _selectedIndex = 1;
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final url =
        'http://api-pinakad.pintarkerja.com/sumber.php?class_id=${widget.classId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];

        // Mengelompokkan data berdasarkan nama mata pelajaran
        Map<String, List<dynamic>> tempData = {};
        for (var item in data) {
          final subjectName = item['name'];
          if (!tempData.containsKey(subjectName)) {
            tempData[subjectName] = [];
          }
          tempData[subjectName]!.add(item);
        }

        setState(() {
          subjectData = tempData;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showPdfList(String subject) {
    setState(() {
      selectedSubject = subject;
    });
    // Navigate to a new page that will show PDFs for the selected subject
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PdfListPage(subject: subject, pdfData: subjectData[subject]!),
      ),
    );
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                children: subjectData.keys.map((subject) {
                  return buildCard(subjectData[subject]!, subject);
                }).toList(),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 31, 40, 174),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/bxs_home-alt-2.png')),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/bxs_book-alt.png')),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/entypo_video.png')),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/bell.png')),
            label: 'Notify',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/person.png')),
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

  Widget buildCard(List<dynamic> data, String subject) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          _showPdfList(subject); // Navigate to the PDF list page
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${data.length} PDF(s) available'), // Show number of PDFs
            ],
          ),
        ),
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
                  namalengkap: widget.namalengkap),
            ),
          );
          break;
        case 1:
          // Current BookPage; no action needed
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
              ),
            ),
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
              ),
            ),
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
              ),
            ),
          );
          break;
      }
    });
  }
}
