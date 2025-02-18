import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class JadwalGuruPage extends StatefulWidget {
  final int teacher_id;
  final int subject_id;
  final String namaguru;

  const JadwalGuruPage({
    Key? key,
    required this.teacher_id,
    required this.subject_id,
    required this.namaguru,
  }) : super(key: key);

  @override
  _JadwalGuruPageState createState() => _JadwalGuruPageState();
}

class _JadwalGuruPageState extends State<JadwalGuruPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> data = [];
  List<Map<String, dynamic>> _holidays = [];
  bool isLoading = true;
  String errorMessage = '';

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

  // Day mapping to convert Indonesian days to English
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
    _selectedDay =
        _getDayFromDate(DateTime.now()); // Set the selected day to today
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _days.indexOf(_selectedDay!),
    );
    _tabController.addListener(() {
      setState(() {
        _selectedDay = _days[_tabController.index];
        isLoading = true; // Show loading while fetching new data
        fetchData(); // Fetch data for the newly selected day
      });
    });
    fetchData();
  }

  Future<void> fetchData() async {
    final DateTime selectedDate =
        _calculateDateForDay(_selectedDay!, DateTime.now());
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final String translatedDay = dayMapping[_selectedDay!] ?? '';
    final String dayParam =
        translatedDay.isNotEmpty ? '&day=$translatedDay' : '';

    final String mapelUrl =
        'http://api-pinakad.pintarkerja.com/get_jadwal.php?teacher_id=${widget.teacher_id}&subject_id=${widget.subject_id}$dayParam';
    final String holidaysUrl = 'http://api-pinakad.pintarkerja.com/holiday.php';

    try {
      // Fetch schedule data
      final responseMapel = await http.get(Uri.parse(mapelUrl));
      print('Schedule Response: ${responseMapel.body}');
      if (responseMapel.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(responseMapel.body);
        if (decodedData['status'] == 'success') {
          setState(() {
            data = (decodedData['data'] as List<dynamic>)
                .map((item) => item as Map<String, dynamic>)
                .toList();
            data.sort((a, b) {
              final startA = int.tryParse(a['time_start'].toString()) ?? 0;
              final startB = int.tryParse(b['time_start'].toString()) ?? 0;
              final endA = int.tryParse(a['time_end'].toString()) ?? 0;
              final endB = int.tryParse(b['time_end'].toString()) ?? 0;

              if (startA != startB) {
                return startA.compareTo(startB);
              } else {
                return endA.compareTo(endB);
              }
            });
          });
        } else {
          setState(() {
            data = [];
          });
        }
      }

      // Fetch holiday data
      final responseHolidays = await http.get(Uri.parse(holidaysUrl));
      //print('Holiday Response: ${responseHolidays.body}');
      if (responseHolidays.statusCode == 200) {
        final Map<String, dynamic> decodedHolidays =
            jsonDecode(responseHolidays.body);
        if (decodedHolidays['status'] == 'success') {
          setState(() {
            _holidays =
                List<Map<String, dynamic>>.from(decodedHolidays['data']);
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    } finally {
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
              : data.isEmpty
                  ? Center(
                      child: Text(errorMessage.isEmpty
                          ? 'No schedule available for this day.'
                          : errorMessage))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final mulai =
                            '${item['time_start']?.toString() ?? 'No Time'} WIB';
                        final timeEnd =
                            '${item['time_end']?.toString() ?? 'No Time'} WIB';

                        final String currentDateFormatted =
                            DateFormat('yyyy-MM-dd').format(selectedDate);
                        final bool isHoliday = _holidays.any((holiday) =>
                            holiday['date'] == currentDateFormatted);
                        final name =
                            isHoliday ? '' : item['name'] ?? 'No Subject';

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
                                      MediaQuery.of(context).size.width * 0.47 -
                                          9,
                                  height: 82,
                                  decoration: ShapeDecoration(
                                    color: const Color.fromARGB(
                                        255, 207, 200, 200),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    shadows: const [
                                      BoxShadow(
                                        color: Color.fromARGB(10, 253, 115, 2),
                                        blurRadius: 20,
                                        offset: Offset(0, 0),
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 247,
                                top: 0,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25 -
                                          9,
                                  height: 92,
                                  decoration: ShapeDecoration(
                                    color: const Color.fromARGB(
                                        255, 244, 197, 197),
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
                                        text: '${day}, ${formattedDate}\n',
                                        style: TextStyle(
                                          color: isHoliday
                                              ? Colors.red
                                              : const Color(0xFF4B4B4B),
                                          fontSize: 10,
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
                                left: 131,
                                top: 40,
                                child: Text(
                                  'Kelas : $name',
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
                                    color: const Color.fromARGB(
                                        255, 119, 174, 247),
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
                                left: 270,
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
