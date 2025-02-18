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
        'http://api-pinakad.pintarkerja.com/ulangan.php?class_id=${widget.classId}',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['status'] == 'success' &&
            responseBody.containsKey('data')) {
          final data = responseBody['data'] as List<dynamic>;

          // Sort data by exam_date
          data.sort((a, b) {
            final dateA = DateTime.tryParse(a['start'] ?? '');
            final dateB = DateTime.tryParse(b['start'] ?? '');
            return (dateA ?? DateTime.now()).compareTo(dateB ?? DateTime.now());
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
    Set<String> addedAppointments =
        {}; // Set untuk melacak janji yang telah ditambahkan

    mataPelajaranDetail.forEach((subjectId, detailData) {
      for (var data in detailData) {
        String? startTimeStr = data['start'];
        String? endTimeStr = data['end'];

        if (startTimeStr != null && endTimeStr != null) {
          try {
            DateTime examStartDate = DateTime.parse(startTimeStr);
            DateTime examEndDate = DateTime.parse(endTimeStr);
            String appointmentKey =
                '${examStartDate.toIso8601String()}-${data['title']}'; // Unik untuk setiap janji

            // Cek apakah janji sudah ditambahkan
            if (!addedAppointments.contains(appointmentKey)) {
              appointments.add(Appointment(
                startTime: examStartDate,
                endTime: examEndDate,
                subject: data['title'] ?? 'No pelajaran',
                color: Colors.blue,
                notes: jsonEncode(
                    [data]), // Pastikan ini adalah list yang di-JSON-kan
              ));
              addedAppointments
                  .add(appointmentKey); // Tandai janji telah ditambahkan
            } else {
              print(
                  'Duplicate appointment found for: ${data['title']} on ${examStartDate}');
            }
          } catch (e) {
            print('Error parsing date for data: $data, error: $e');
          }
        } else {
          print('Start or end time is null for data: $data');
        }
      }
    });

    print('Appointments: $appointments'); // Debugging

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
                    monthCellBuilder:
                        (BuildContext buildContext, MonthCellDetails details) {
                      final DateTime date = details.date;

                      final DateTime firstDayOfMonth =
                          DateTime(date.year, date.month, 1);
                      final DateTime lastDayOfMonth =
                          DateTime(date.year, date.month + 1, 0);
                      final bool isOutsideCurrentMonth =
                          date.isBefore(firstDayOfMonth) ||
                              date.isAfter(lastDayOfMonth);

                      final TextStyle dayTextStyle =
                          date.weekday == DateTime.sunday
                              ? const TextStyle(color: Colors.red)
                              : const TextStyle(color: Colors.black);

                      final BoxDecoration decoration = BoxDecoration(
                        border: Border.all(
                            color: const Color.fromARGB(77, 232, 232, 232)),
                        color: date.isSameDay(today)
                            ? const Color.fromARGB(255, 255, 75, 59)
                                .withOpacity(0.5)
                            : (isOutsideCurrentMonth
                                ? Colors.grey
                                : Colors.transparent),
                      );

                      return Container(
                        alignment: Alignment.center,
                        decoration: decoration,
                        child: Text(
                          date.day.toString(),
                          style: dayTextStyle,
                        ),
                      );
                    },
                    onTap: (CalendarTapDetails details) {
                      if (details.appointments != null &&
                          details.appointments!.isNotEmpty) {
                        List<Appointment> selectedAppointments =
                            details.appointments!.cast<Appointment>();

                        List<Map<String, dynamic>> allAppointmentData = [];

                        for (var appointment in selectedAppointments) {
                          if (appointment.notes != null) {
                            final appointmentDataJson = appointment.notes!;
                            try {
                              final List<dynamic> appointmentData =
                                  jsonDecode(appointmentDataJson)
                                      as List<dynamic>;
                              allAppointmentData.addAll(appointmentData
                                  .map((item) => item as Map<String, dynamic>)
                                  .toList());
                            } catch (e) {
                              print('Error decoding appointment notes: $e');
                            }
                          } else {
                            print(
                                'Appointment notes are null for: $appointment');
                          }
                        }

                        print(
                            'Total Appointment Data: ${allAppointmentData.length}');
                        print(
                            'All Appointment Data: $allAppointmentData'); // Debugging

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              dataList: allAppointmentData,
                            ),
                          ),
                        );
                      } else {
                        print(
                            'No appointments found for tapped date: ${details.date}'); // Debugging
                      }
                    },
                  ),
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
