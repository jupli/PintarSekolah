import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class TugasPrMPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const TugasPrMPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _TugasPrMPageState createState() => _TugasPrMPageState();
}

class _TugasPrMPageState extends State<TugasPrMPage> {
  List<dynamic> penilaianData = [];
  Map<String, List<dynamic>> mataPelajaranDetail = {};
  bool isLoading = true;
  DateTime today = DateTime.now(); // Tanggal hari ini

  @override
  void initState() {
    super.initState();
    _fetchPenilaianData();
  }

  Future<void> _fetchPenilaianData() async {
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/mata_pelajaran.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        print('Penilaian Data Response: $responseBody'); // Debugging

        if (responseBody['status'] == 'success') {
          setState(() {
            penilaianData = responseBody['data'] ?? [];
            isLoading = false;
          });

          if (penilaianData.isEmpty) {
            print('No data available'); // Ganti dialog dengan log
          }

          for (var subject in penilaianData) {
            await _fetchDetailData(subject['subject_id'].toString());
          }
        } else {
          print(
              'API Error: ${responseBody['status']}'); // Ganti dialog dengan log
        }
      } else {
        print('Failed to load penilaian data'); // Ganti dialog dengan log
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching penilaian data: $e'); // Ganti dialog dengan log
    }
  }

  Future<void> _fetchDetailData(String subjectId) async {
    if (mataPelajaranDetail.containsKey(subjectId)) {
      return;
    }
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/tugas2.php?class_id=${widget.classId}&subject_id=$subjectId',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        print('Detail Data Response: $responseBody'); // Debugging

        if (responseBody.containsKey('data')) {
          final data = responseBody['data'] as List<dynamic>;

          // Sort data by publish_date
          data.sort((a, b) {
            DateTime? dateA = _parseDate(a['publish_date']);
            DateTime? dateB = _parseDate(b['publish_date']);

            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return -1;
            if (dateB == null) return 1;

            return dateA.compareTo(dateB);
          });

          setState(() {
            mataPelajaranDetail[subjectId] = data;
          });
        } else {
          print('No data available for detail'); // Ganti dialog dengan log
        }
      } else {
        print(
            'Failed to load mataPelajaranDetail data'); // Ganti dialog dengan log
      }
    } catch (e) {
      print(
          'Error fetching mataPelajaranDetail data: $e'); // Ganti dialog dengan log
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateString);
    } catch (e) {
      try {
        return DateFormat('dd/MM/yyyy hh:mm a').parse(dateString);
      } catch (e) {
        print('Error parsing date: $dateString');
        return null;
      }
    }
  }

  Map<String, List<dynamic>> _groupTasksByWeek() {
    final Map<String, List<dynamic>> weeklyTasks = {};

    mataPelajaranDetail.forEach((subjectId, details) {
      for (var task in details) {
        DateTime? publishDate = _parseDate(task['publish_date'] ?? '');

        if (publishDate != null) {
          final startOfWeek =
              publishDate.subtract(Duration(days: publishDate.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));
          final weekKey =
              '${DateFormat('yyyy-MM-dd').format(startOfWeek)} to ${DateFormat('yyyy-MM-dd').format(endOfWeek)}';

          if (!weeklyTasks.containsKey(weekKey)) {
            weeklyTasks[weekKey] = [];
          }
          weeklyTasks[weekKey]!.add(task);
        }
      }
    });

    // Urutkan minggu berdasarkan tanggal awal minggu
    final List<MapEntry<String, List<dynamic>>> sortedEntries =
        weeklyTasks.entries.toList();
    sortedEntries.sort((a, b) {
      final startDateA = DateFormat('yyyy-MM-dd').parse(a.key.split(' to ')[0]);
      final startDateB = DateFormat('yyyy-MM-dd').parse(b.key.split(' to ')[0]);
      return startDateA.compareTo(startDateB);
    });

    return Map.fromEntries(sortedEntries);
  }

  Color _getCardColor(String subjectName) {
    if (subjectName.toLowerCase() == 'bahasa indonesia') {
      return Colors.lightBlue.shade100; // Biru muda
    } else if (subjectName.toLowerCase() == 'matematika') {
      return Colors.red.shade100; // Merah
    } else {
      return Colors.white; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyTasks = _groupTasksByWeek();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DETAIL PR/TUGAS',
          style: TextStyle(
            color: Colors.white, // Mengubah warna teks menjadi putih
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Color.fromRGBO(255, 255, 255, 1)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: weeklyTasks.entries.map((entry) {
                final weekRange = entry.key;
                final tasks = entry.value;

                return ExpansionTile(
                  title: Text('Minggu: $weekRange'),
                  children: tasks.map((task) {
                    final title = task['title'] ?? 'No Title';
                    final description = task['description'] ?? 'No Description';
                    final selesai = task['date_end'] ?? 'No Description';
                    final publishDate = _parseDate(task['publish_date'] ?? '');
                    final formattedDate = publishDate != null
                        ? DateFormat('dd MMMM yyyy').format(publishDate)
                        : 'No Date';
                    final subjectName = task['subject_name'] ??
                        ''; // Assuming `subject_name` exists

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      elevation: 5,
                      color: _getCardColor(subjectName),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey
                              .withOpacity(0.5), // Warna border abu-abu
                          width: 0.5, // Lebar border
                          style: BorderStyle.solid, // Gaya border solid
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Tanggal Diberikan: $formattedDate\nDeskripsi: $description\Tanggal Selesai: $selesai',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
    );
  }
}
