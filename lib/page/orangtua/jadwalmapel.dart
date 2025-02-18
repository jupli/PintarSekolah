import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class JadwalMapelPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const JadwalMapelPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _JadwalMapelPageState createState() => _JadwalMapelPageState();
}

class _JadwalMapelPageState extends State<JadwalMapelPage> {
  List<dynamic> data = [];
  bool isLoading = true;
  final int _selectedIndex = 1;

  DateTime selectedDate = DateTime.now();
  String? selectedDay;

  List<DateTime> holidays = [];

  @override
  void initState() {
    super.initState();
    selectedDay = DateFormat('EEEE').format(selectedDate);
    fetchHolidays();
    fetchData();
  }

  Future<void> fetchHolidays() async {
    final String apiUrl =
        'http://api-pinakad.pintarkerja.com/libur.php?year=${selectedDate.year}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> holidaysJson = jsonDecode(response.body)['data'];
        setState(() {
          holidays = holidaysJson.map((holiday) {
            return DateTime.parse(holiday['date']);
          }).toList();
        });
      } else {
        throw Exception('Failed to load holidays');
      }
    } catch (e) {
      print('Failed to load holidays: $e');
    }
  }

  Future<void> fetchData() async {
    final String dayParam = selectedDay != null ? '&day=${selectedDay!}' : '';

    final String url =
        'http://api-pinakad.pintarkerja.com/mapel.php?class_id=${widget.classId}&section_id=${widget.sectionId}&subject_id=${widget.subjectId}$dayParam';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        if (decodedData['status'] == 'success') {
          setState(() {
            data = decodedData['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 5, 1);
    final DateTime lastDate = DateTime(now.year + 5, 12);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      bool isHoliday = holidays.any((holiday) =>
          holiday.year == pickedDate.year &&
          holiday.month == pickedDate.month &&
          holiday.day == pickedDate.day);

      if (isHoliday) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Hari Libur"),
              content: const Text(
                  "Tanggal yang Anda pilih adalah hari libur. Silakan pilih tanggal lain."),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          selectedDate = pickedDate;
          selectedDay = DateFormat('EEEE').format(selectedDate);
        });
        fetchData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(selectedDate);
    String dayName = selectedDay ?? DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logop.png',
              fit: BoxFit.contain,
              height: 40,
            ),
            const SizedBox(width: 10), // Spasi antara logo dan teks
            const Text(
              "JADWAL PELAJARAN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(9.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text('Pilih Tanggal: $formattedDate ($dayName)'),
                  ),
                ),
                const SizedBox(width: 9),
                // ElevatedButton(
                //   onPressed: () {
                //     setState(() {
                //       isLoading = true;
                //     });
                //     fetchData(); // Refresh data with the selected date
                //   },
                //   //child: const Text('Filter'),
                // ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final mulai =
                          '${item['time_start']?.toString() ?? 'No Time'} WIB';
                      final name = item['name']?.toString() ?? 'No Subject';
                      final name2 =
                          item['description']?.toString() ?? 'No Subject';
                      final timeStart =
                          item['time_start']?.toString() ?? 'No Start Time';
                      final timeEnd =
                          '${item['time_end']?.toString() ?? 'No Time'} WIB';

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
                                width: MediaQuery.of(context).size.width * 0.9 -
                                    53,
                                height: 82,
                                decoration: ShapeDecoration(
                                  color:
                                      const Color.fromARGB(255, 249, 250, 250),
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
                              left: 111,
                              top: 23,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$dayName, $formattedDate\n',
                                      style: const TextStyle(
                                        color: Color(0xFF4B4B4B),
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w300,
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
                                  color:
                                      const Color.fromARGB(255, 119, 174, 247),
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
                  ),
          ),
        ],
      ),
    );
  }
}
