import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class AbsenAnakPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const AbsenAnakPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _AbsenAnakPageState createState() => _AbsenAnakPageState();
}

class _AbsenAnakPageState extends State<AbsenAnakPage> {
  Map<DateTime, int> absensiData = {};
  bool isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _fetchAbsenAnak();
  }

  Future<void> _fetchAbsenAnak() async {
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/kehadiran.php?student_id=${widget.studentId}',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        print('API Response: $responseBody'); // Debug output

        if (responseBody['status'] == 'success') {
          List<dynamic> data = responseBody['data'];
          setState(() {
            absensiData = _mapAbsensiData(data);
            isLoading = false;
          });
        } else {
          throw Exception(
              'Failed to load attendance data: ${responseBody['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<DateTime, int> _mapAbsensiData(List<dynamic> data) {
    final Map<DateTime, int> mappedData = {};
    for (var item in data) {
      final int timestamp = item['timestamp'] is int
          ? item['timestamp']
          : int.tryParse(item['timestamp']) ?? 0;

      final DateTime date = DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
        isUtc: true,
      );
      final DateTime dateKey = DateTime.utc(date.year, date.month, date.day);

      final int status = item['status'] is int
          ? item['status']
          : int.tryParse(item['status'].toString()) ?? 0;

      mappedData[dateKey] = status;
    }
    return mappedData;
  }

  Color _getDayColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue; // Blue for present
      case 2:
        return Colors.red; // Red for absent
      default:
        return Colors.transparent;
    }
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
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Absensi Kehadiran',
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 01, 01),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: DateTime.now(),
                  calendarFormat: _calendarFormat, // Set to month view
                  availableGestures:
                      AvailableGestures.none, // Disable swipe gestures
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    defaultDecoration: const BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.transparent,
                    ),
                    weekendDecoration: const BoxDecoration(
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, focusedDay) {
                      final int? status = absensiData[date];
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: status != null
                              ? _getDayColor(status)
                              : Colors.transparent,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color:
                                  status != null ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, date, focusedDay) {
                      final int? status = absensiData[date];
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: status != null
                              ? _getDayColor(status)
                              : Colors.transparent,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color:
                                  status != null ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, date, focusedDay) {
                      final int? status = absensiData[date];
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: status != null
                              ? _getDayColor(status)
                              : Colors.transparent,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color:
                                  status != null ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    const Text('Hadir', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 20),
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text('Absen', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
    );
  }
}
