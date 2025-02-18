import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart'; // Import for date formatting

// Import other necessary pages
import '../book/bookpage.dart';
import '../dashboard/dashboard.dart';
import '../mapel/mapel.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';

class LihatNilaiPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const LihatNilaiPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _LihatNilaiPageState createState() => _LihatNilaiPageState();
}

class _LihatNilaiPageState extends State<LihatNilaiPage>
    with TickerProviderStateMixin {
  List<dynamic> penilaianData = [];
  Map<String, List<dynamic>> mataPelajaranDetail = {};
  bool isLoading = true;
  TabController? _tabController;
  late CalendarController _calendarController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 0, vsync: this); // Initialize with length 0
    _calendarController = CalendarController();
    _selectedDate = DateTime.now(); // Set the initial date
    _fetchPenilaianData(); // Fetch data on initialization
  }

  Future<void> _fetchPenilaianData() async {
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/mata_pelajaran.php?class_id=${widget.classId}',
      ));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        setState(() {
          penilaianData = responseBody['data']
              as List<dynamic>; // Example key, adjust as needed
          _tabController = TabController(
              length: penilaianData.length,
              vsync: this); // Update TabController length
          isLoading = false; // Data is loaded
        });
      } else {
        throw Exception('Failed to load penilaian data');
      }
    } catch (e) {
      // Handle the error properly in your UI
      print('Error fetching penilaian data: $e');
    }
  }

  Future<List<dynamic>> _fetchDetailData(String subjectId) async {
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/mata_pelajaran_detail.php?student_id=${widget.studentId}&subject_id=$subjectId',
      ));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        // Print response body to understand its structure
        print('Response body: $responseBody');

        // Adjust according to the actual structure of the response
        if (responseBody.containsKey('data')) {
          return responseBody['data'] as List<dynamic>;
        } else {
          throw Exception('Data key not found in response');
        }
      } else {
        throw Exception('Failed to load mataPelajaranDetail data');
      }
    } catch (e) {
      // Handle the error properly in your UI
      print('Error fetching mataPelajaranDetail data: $e');
      return []; // Return an empty list in case of error
    }
  }

  Widget _buildMataPelajaranContent(String subjectId) {
    List<dynamic> detailData = mataPelajaranDetail[subjectId] ?? [];

    if (detailData.isEmpty) {
      return Center(
          child: Text('No data available for subject ID: $subjectId.'));
    }

    return ListView.builder(
      itemCount: detailData.length,
      itemBuilder: (context, index) {
        final data = detailData[index];
        final int? timestamp = data['exam_date'] != null
            ? int.tryParse(data['exam_date'].toString())
            : null;
        final DateTime? date = timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
            : null;
        final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
        final String formattedDate =
            date != null ? dateFormat.format(date) : 'No date available';

        // Determine card color based on whether title contains specific keywords
        Color cardColor;
        final String title = data['title']?.toLowerCase() ?? '';
        if (title.contains('ujian harian')) {
          cardColor = Colors.yellow.shade100; // Light yellow for daily exams
        } else if (title.contains('ujian tengah semester')) {
          cardColor = Colors.blue.shade100; // Light blue for midterm exams
        } else {
          cardColor = Colors.white; // Default color
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Hasil Penilaian Murid',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              color: cardColor,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(data['title'] ?? 'No pelajaran',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nilai: ${data['obtained_mark'] ?? 'No pelajaran'}'),
                    const SizedBox(height: 4),
                    Text('Tanggal : $formattedDate'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logop.png',
              fit: BoxFit.contain,
              height: 40,
            ),
            const SizedBox(width: 10), // Add spacing between logo and title
            const Expanded(
              child: Text(
                'Hasil Penilaian Murid',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        bottom: isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true, // Allows tabs to scroll if needed
                labelStyle: const TextStyle(
                  fontSize: 16, // Adjust font size as needed
                  fontWeight: FontWeight.bold, // Make text bold
                ),
                unselectedLabelColor:
                    Colors.white70, // Color for unselected tabs
                labelColor: Colors.white, // Color for selected tab
                indicatorColor: const Color.fromARGB(
                    255, 254, 115, 1), // Color of the indicator line
                tabs: penilaianData.map((subject) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16), // Horizontal padding
                    child: Tab(
                      text: subject['name'].toString(),
                    ),
                  );
                }).toList(),
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: penilaianData.length,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: penilaianData.map((subject) {
                        return FutureBuilder<List<dynamic>>(
                          future: _fetchDetailData(
                              subject['subject_id'].toString()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else {
                              mataPelajaranDetail[subject['subject_id']
                                  .toString()] = snapshot.data ?? [];
                              return _buildMataPelajaranContent(
                                  subject['subject_id'].toString());
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
