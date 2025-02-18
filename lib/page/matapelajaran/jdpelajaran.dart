import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../dashboard/dashboard.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';
import '../book/bookpage.dart';

class jMapelPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const jMapelPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _jMapelPageState createState() => _jMapelPageState();
}

class _jMapelPageState extends State<jMapelPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> data = [];
  bool isLoading = true;

  late TabController _tabController;

  final List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu'
  ];

  String? _selectedDay;

  final Map<String, String> dayMapping = {
    'Senin': 'Monday',
    'Selasa': 'Tuesday',
    'Rabu': 'Wednesday',
    'Kamis': 'Thursday',
    'Jumat': 'Friday',
    'Sabtu': 'Saturday',
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _getDayFromDate(DateTime.now());
    _tabController = TabController(
        length: _days.length,
        vsync: this,
        initialIndex: _days.indexOf(_selectedDay!));
    _tabController.addListener(() {
      setState(() {
        _selectedDay = _days[_tabController.index];
        isLoading = true;
        fetchData();
      });
    });
    fetchData();
  }

  List<Map<String, dynamic>> _holidays = [];

  Future<void> fetchData() async {
    final DateTime selectedDate =
        _calculateDateForDay(_selectedDay!, DateTime.now());
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final String translatedDay = dayMapping[_selectedDay!] ?? '';
    final String dayParam =
        translatedDay.isNotEmpty ? '&day=$translatedDay' : '';

    final String mapelUrl =
        'http://api-pinakad.pintarkerja.com/mapel.php?class_id=${widget.classId}&section_id=${widget.sectionId}&subject_id=${widget.subjectId}$dayParam';

    final String holidaysUrl = 'http://api-pinakad.pintarkerja.com/holiday.php';

    try {
      final responseMapel = await http.get(Uri.parse(mapelUrl));
      if (responseMapel.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(responseMapel.body);
        if (decodedData['status'] == 'success') {
          setState(() {
            data = decodedData['data'] ?? [];

            // Sort data by start time
            data.sort((a, b) {
              final startA = int.parse(a['time_start']);
              final startB = int.parse(b['time_start']);
              return startA.compareTo(startB);
            });
          });
        }
      }

      final responseHolidays = await http.get(Uri.parse(holidaysUrl));
      if (responseHolidays.statusCode == 200) {
        final Map<String, dynamic> decodedHolidays =
            jsonDecode(responseHolidays.body);
        if (decodedHolidays['status'] == 'success') {
          setState(() {
            _holidays =
                List<Map<String, dynamic>>.from(decodedHolidays['data']);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime _calculateDateForDay(String day, DateTime referenceDate) {
    final dayIndex = _days.indexOf(day);
    final referenceDayIndex = (referenceDate.weekday - 1) % 7;

    final daysDifference = (dayIndex - referenceDayIndex + 7) % 7;

    return referenceDate.add(Duration(days: daysDifference));
  }

  String _getDayFromDate(DateTime date) {
    final weekday = DateFormat('EEEE', 'id_ID').format(date);
    return _days.firstWhere((day) => dayMapping[day] == weekday,
        orElse: () => 'Senin');
  }

  @override
  Widget build(BuildContext context) {
    // Display all subjects for the selected day
    final currentClasses = data;

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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((day) {
            final index = _days.indexOf(day);
            return Tab(
              child: Text(
                day,
                style: TextStyle(
                  color: _tabController.index == index
                      ? const Color.fromARGB(255, 243, 87, 15)
                      : const Color.fromARGB(255, 248, 246, 246),
                ),
              ),
            );
          }).toList(),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 250, 68, 2),
              width: 3.0,
            ),
          ),
          onTap: (index) {
            setState(() {
              _selectedDay = _days[index];
              isLoading = true;
              fetchData();
            });
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((day) {
          final selectedDate = _calculateDateForDay(day, DateTime.now());
          final formattedDate = DateFormat('dd MMMM yyyy').format(selectedDate);

          return isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: currentClasses.length,
                  itemBuilder: (context, index) {
                    final item = currentClasses[index];
                    final mulai =
                        '${item['time_start']}:${item['time_start_min']} WIB';
                    final timeEnd =
                        '${item['time_end']}:${item['time_end_min']} WIB';

                    final String currentDateFormatted =
                        DateFormat('yyyy-MM-dd').format(selectedDate);
                    final bool isHoliday = _holidays.any(
                        (holiday) => holiday['date'] == currentDateFormatted);
                    final name = isHoliday
                        ? ''
                        : item['name']?.toString() ?? 'No Subject';

                    return Container(
                      width: double.infinity,
                      height: 82,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 83,
                            top: 0,
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width * 0.9 - 53,
                              height: 82,
                              decoration: ShapeDecoration(
                                color: const Color.fromARGB(255, 250, 249, 249),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color.fromARGB(10, 253, 115, 2),
                                    blurRadius: 20,
                                    offset: Offset(0, 0),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 111,
                            top: 23,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Hari : ${day}\n\n\n',
                                    style: TextStyle(
                                      color: isHoliday
                                          ? Colors.red
                                          : Color(0xFF4B4B4B),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w300,
                                      height: 1.2,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  if (isHoliday)
                                    TextSpan(
                                      text:
                                          ' - ${_holidays.firstWhere((holiday) => holiday['date'] == currentDateFormatted)['keterangan']}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                        height: 1.2,
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 111,
                            top: 44,
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
                          Positioned(
                            left: 0,
                            top: 1,
                            child: Container(
                              width: 79,
                              height: 80,
                              decoration: ShapeDecoration(
                                color: const Color.fromARGB(255, 119, 174, 247),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x0C000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 0),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 17,
                            top: 26,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Mulai:\n',
                                    style: TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  TextSpan(
                                    text: mulai,
                                    style: const TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 265,
                            top: 27,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Selesai:\n',
                                    style: TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  TextSpan(
                                    text: timeEnd,
                                    style: const TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
        }).toList(),
      ),
    );
  }
}
