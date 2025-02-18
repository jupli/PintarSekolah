import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'detailutspage.dart';

class Exam {
  final String id;
  final String code;
  final String title;
  final int classId;
  final int sectionId;
  final int subjectId;
  final DateTime examDate;
  final String timeStart;
  final String timeEnd;
  final int duration;
  final int minimumPercentage;
  final String instruction;

  Exam({
    required this.id,
    required this.code,
    required this.title,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.examDate,
    required this.timeStart,
    required this.timeEnd,
    required this.duration,
    required this.minimumPercentage,
    required this.instruction,
  });
}

class JutsPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const JutsPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _JutsPageState createState() => _JutsPageState();
}

class _JutsPageState extends State<JutsPage> {
  List<dynamic> penilaianData = [];
  Map<String, List<Exam>> mataPelajaranDetail = {};
  bool isLoading = true;
  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPenilaianData();
  }

  Future<void> _fetchPenilaianData() async {
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/mata_pelajaran.php?class_id=${widget.classId}',
      ));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['status'] == 'success') {
          setState(() {
            penilaianData = responseBody['data'] ?? [];
            isLoading = false;
          });

          for (var subject in penilaianData) {
            await _fetchDetailData(subject['subject_id'].toString());
          }
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching penilaian data: $e');
    }
  }

  Future<void> _fetchDetailData(String subjectId) async {
    if (mataPelajaranDetail.containsKey(subjectId)) return;

    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/uts.php?class_id=${widget.classId}&subject_id=$subjectId',
      ));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['status'] == 'success' &&
            responseBody.containsKey('data')) {
          final data = responseBody['data'] as List<dynamic>;
          List<Exam> exams = data.map((item) {
            DateTime examDate = DateTime.fromMillisecondsSinceEpoch(
                int.parse(item['exam_date'].toString()) *
                    (item['exam_date'].toString().length <= 10 ? 1000 : 1));
            return Exam(
              id: item['code'],
              code: item['code'],
              title: item['title'],
              classId: int.tryParse(item['class_id'].toString()) ?? 0,
              sectionId: int.tryParse(item['section_id'].toString()) ?? 0,
              subjectId: int.tryParse(item['subject_id'].toString()) ?? 0,
              examDate: examDate,
              timeStart: item['time_start'],
              timeEnd: item['time_end'],
              duration: int.tryParse(item['duration'].toString()) ?? 0,
              minimumPercentage:
                  int.tryParse(item['minimum_percentage'].toString()) ?? 0,
              instruction: item['instruction'] ?? '',
            );
          }).toList();

          exams.sort((a, b) => a.examDate.compareTo(b.examDate));
          setState(() {
            mataPelajaranDetail[subjectId] = exams;
          });
        }
      }
    } catch (e) {
      print(
          'Error fetching mataPelajaranDetail data for subject_id $subjectId: $e');
    }
  }

  List<Appointment> _getCalendarData() {
    List<Appointment> appointments = [];

    mataPelajaranDetail.forEach((subjectId, detailData) {
      for (var exam in detailData) {
        if (!appointments.any((appointment) =>
            appointment.startTime == exam.examDate &&
            appointment.subject == exam.title)) {
          appointments.add(Appointment(
            startTime: exam.examDate,
            endTime: exam.examDate.add(Duration(seconds: exam.duration)),
            subject: exam.title,
            color: exam.title.contains('Ujian Tengah Semester')
                ? Colors.orange
                : exam.title.contains('Ujian Akhir Semester')
                    ? const Color.fromARGB(255, 254, 1, 1)
                    : Colors.blue,
            notes: jsonEncode([
              {
                'id': exam.id,
                'code': exam.code,
                'title': exam.title,
                'time_start': exam.timeStart,
                'time_end': exam.timeEnd,
                'instruction': exam.instruction,
                'minimumPercentage': exam.minimumPercentage,
              }
            ]),
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
          'Ujian Tengah Semester',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 400,
                  width: 300,
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
                      final bool isOutsideCurrentMonth =
                          date.month != today.month || date.year != today.year;
                      final TextStyle dayTextStyle =
                          date.weekday == DateTime.sunday
                              ? const TextStyle(color: Colors.red)
                              : const TextStyle(color: Colors.black);

                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color.fromARGB(77, 232, 232, 232)),
                          color: date.isSameDay(today)
                              ? const Color.fromARGB(255, 255, 75, 59)
                                  .withOpacity(0.5)
                              : Colors.transparent,
                        ),
                        child: Text(date.day.toString(), style: dayTextStyle),
                      );
                    },
                    onTap: (CalendarTapDetails details) {
                      if (details.appointments != null &&
                          details.appointments!.isNotEmpty) {
                        List<Appointment> selectedAppointments =
                            details.appointments!.cast<Appointment>();
                        List<Map<String, dynamic>> allAppointmentData = [];

                        for (var appointment in selectedAppointments) {
                          final appointmentDataJson = appointment.notes!;
                          final List<dynamic> appointmentData =
                              jsonDecode(appointmentDataJson);
                          allAppointmentData.addAll(appointmentData
                              .map((item) => item as Map<String, dynamic>));
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailUtsPage(dataList: allAppointmentData),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi tambahan di bawah kalender:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                              width: 16, height: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('Ujian Tengah Semester (Warna Oranye)',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                              width: 16,
                              height: 16,
                              color: const Color.fromARGB(255, 254, 1, 1)),
                          const SizedBox(width: 8),
                          const Text('Ujian Akhir Semester (Warna Kuning)',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
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
    return year == other.year && month == other.month && day == other.day;
  }
}
