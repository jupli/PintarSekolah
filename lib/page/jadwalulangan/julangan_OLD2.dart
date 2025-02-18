import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'detailulangan.dart';

class JulanganPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const JulanganPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _JulanganPageState createState() => _JulanganPageState();
}

class _JulanganPageState extends State<JulanganPage> {
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

          // Cek apakah data penilaian kosong
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
        'http://api-pinakad.pintarkerja.com/ulangan.php?class_id=${widget.classId}&subject_id=$subjectId',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        print('Detail Data Response: $responseBody'); // Debugging

        if (responseBody.containsKey('data')) {
          final data = responseBody['data'] as List<dynamic>;

          // Sort data by exam_date
          data.sort((a, b) {
            final dateA = DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(a['start'].toString())! * 1000);
            final dateB = DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(b['start'].toString())! * 1000);
            return dateA.compareTo(dateB);
          });

          setState(() {
            mataPelajaranDetail[subjectId] = data;
            print('Updated mataPelajaranDetail: $mataPelajaranDetail');
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

  List<Appointment> _getCalendarData() {
    List<Appointment> appointments = [];

    mataPelajaranDetail.forEach((subjectId, detailData) {
      for (var data in detailData) {
        final int? timestamp = data['start'] != null
            ? int.tryParse(data['start'].toString())
            : null;

        if (timestamp != null) {
          final DateTime examDate =
              DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

          // Handle potential invalid `time_end` values
          String timeEnd = data['end'] ?? 'No End Time';
          timeEnd = timeEnd == ':10' ? 'No End Time' : timeEnd;

          appointments.add(Appointment(
            startTime: examDate,
            endTime: examDate.add(const Duration(
                hours: 1)), // Set default duration if time_end is invalid
            subject: data['title'] ?? 'No pelajaran',
            color: Colors.blue,
            notes: jsonEncode([data]), // Ensure this is a JSON-encoded list
          ));
        }
      }
    });

    return appointments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalender Ulangan',
          style: TextStyle(
            color: Colors.white, // Mengubah warna teks menjadi putih
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 450, // Sesuaikan tinggi yang diinginkan
                  child: SfCalendar(
                      view: CalendarView.month,
                      dataSource: AppointmentDataSource(_getCalendarData()),
                      monthViewSettings: const MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment,
                      ),
                      monthCellBuilder: (BuildContext buildContext,
                          MonthCellDetails details) {
                        final DateTime date = details.date;

                        // Calculate the first and last day of the current month
                        final DateTime firstDayOfMonth =
                            DateTime(date.year, date.month, 1);
                        final DateTime lastDayOfMonth =
                            DateTime(date.year, date.month + 1, 0);

                        // Check if the date is outside the current month
                        final bool isOutsideCurrentMonth =
                            date.isBefore(firstDayOfMonth) ||
                                date.isAfter(lastDayOfMonth);

                        // Debug print statements
                        print('Date: $date');
                        print('First Day of Month: $firstDayOfMonth');
                        print('Last Day of Month: $lastDayOfMonth');
                        print(
                            'Is Outside Current Month: $isOutsideCurrentMonth');

                        // Text style for weekends
                        final TextStyle dayTextStyle =
                            date.weekday == DateTime.sunday
                                ? const TextStyle(color: Colors.red)
                                : const TextStyle(color: Colors.black);

                        // Decoration for the cell
                        final BoxDecoration decoration = BoxDecoration(
                          border: Border.all(
                              color: const Color.fromARGB(
                                  77, 232, 232, 232)), // Border color
                          color: date.isSameDay(today)
                              ? const Color.fromARGB(255, 255, 75, 59)
                                  .withOpacity(0.5) // Highlight today
                              : (isOutsideCurrentMonth
                                  ? Colors
                                      .grey // Use gray for dates outside the month
                                  : Colors
                                      .transparent), // Transparent for dates in the current month
                        );

                        return Container(
                          alignment: Alignment.center,
                          decoration: decoration,
                          child: Text(
                            date.day.toString(), // Display the day of the month
                            style: dayTextStyle,
                          ),
                        );
                      },
                      onTap: (CalendarTapDetails details) {
                        if (details.appointments != null &&
                            details.appointments!.isNotEmpty) {
                          List<Appointment> selectedAppointments =
                              details.appointments!.cast<Appointment>();

                          // Buat daftar untuk menyimpan semua data dari semua appointment
                          List<Map<String, dynamic>> allAppointmentData = [];

                          // Loop melalui semua appointment yang ada pada tanggal yang sama
                          for (var appointment in selectedAppointments) {
                            final appointmentDataJson = appointment.notes!;
                            final List<dynamic> appointmentData =
                                jsonDecode(appointmentDataJson)
                                    as List<dynamic>;

                            // Tambahkan semua data ke daftar
                            allAppointmentData.addAll(appointmentData
                                .map((item) => item as Map<String, dynamic>)
                                .toList());
                          }

                          // Debugging: Cek berapa banyak data yang dikirim
                          print(
                              'Total Appointment Data: ${allAppointmentData.length}');

                          // Navigasi ke halaman detail dengan semua data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                dataList: allAppointmentData,
                              ),
                            ),
                          );
                        }
                      }),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Informasi tambahan di bawah kalender.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}

extension DateTimeComparison on DateTime {
  bool isSameDay(DateTime other) {
    return this.year == other.year &&
        this.month == other.month &&
        this.day == other.day;
  }
}
