import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/json')) {
          final Map<String, dynamic> responseBody = json.decode(response.body);

          if (responseBody['status'] == 'success') {
            setState(() {
              penilaianData = responseBody['data'] ?? [];
              isLoading = false;
            });

            for (var subject in penilaianData) {
              await _fetchDetailData(subject['subject_id'].toString());
            }
          } else {
            throw Exception('API returned an error: ${responseBody['status']}');
          }
        } else {
          throw Exception('Expected JSON but received: $contentType');
        }
      } else {
        throw Exception('Failed to load penilaian data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching penilaian data: $e');
    }
  }

  Future<void> _fetchDetailData(String subjectId) async {
    if (mataPelajaranDetail.containsKey(subjectId)) {
      return;
    }
    try {
      final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/ulangan2.php?class_id=${widget.classId}&subject_id=$subjectId',
      ));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final Map<String, dynamic> responseBody = json.decode(response.body);

          if (responseBody.containsKey('data')) {
            final data = responseBody['data'] as List<dynamic>;

            data.sort((a, b) {
              final dateA = DateTime.fromMillisecondsSinceEpoch(
                  int.tryParse(a['exam_date'].toString())! * 1000);
              final dateB = DateTime.fromMillisecondsSinceEpoch(
                  int.tryParse(b['exam_date'].toString())! * 1000);
              return dateA.compareTo(dateB);
            });

            setState(() {
              mataPelajaranDetail[subjectId] = data;
            });
          } else {
            throw Exception('Data key not found in response');
          }
        } else {
          throw Exception('Expected JSON but received: $contentType');
        }
      } else {
        throw Exception('Failed to load mataPelajaranDetail data');
      }
    } catch (e) {
      print('Error fetching mataPelajaranDetail data: $e');
    }
  }

  List<Appointment> _getCalendarData() {
    List<Appointment> appointments = [];

    mataPelajaranDetail.forEach((subjectId, detailData) {
      for (var data in detailData) {
        final int? timestamp = data['exam_date'] != null
            ? int.tryParse(data['exam_date'].toString())
            : null;

        if (timestamp != null) {
          final DateTime examDate =
              DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          appointments.add(Appointment(
            startTime: examDate,
            endTime: examDate.add(const Duration(hours: 1)),
            subject: data['title'] ?? 'No pelajaran',
            color: Colors.blue,
            notes: jsonEncode(data),
          ));
        }
      }
    });

    return appointments;
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
    final DateTime examDate = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(data['exam_date'].toString())! * 1000,
    );
    final String formattedDate = DateFormat('yyyy-MM-dd').format(examDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['title'] ?? 'No title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tanggal: $formattedDate'),
              const SizedBox(height: 8),
              Text('Waktu Mulai: ${data['time_start'] ?? 'Tidak tersedia'}'),
              const SizedBox(height: 8),
              Text(
                  'Deskripsi: ${data['description'] ?? 'Tidak ada deskripsi'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup modal
              },
              child: const Text('Close'),
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
        title: const Text('Kalender Ulangan'),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 400, // Sesuaikan tinggi yang diinginkan
                  child: SfCalendar(
                    view: CalendarView.month,
                    dataSource: AppointmentDataSource(_getCalendarData()),
                    monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.appointment,
                    ),
                    onTap: (CalendarTapDetails details) {
                      if (details.appointments != null &&
                          details.appointments!.isNotEmpty) {
                        List selectedAppointments = details.appointments!;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Daftar Ulangan'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var appointment
                                        in selectedAppointments) ...[
                                      Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        elevation: 4,
                                        color: Colors.amber[
                                            100], // Ganti warna latar belakang di sini
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(16),
                                          title: Text(
                                              jsonDecode(appointment.notes!)[
                                                      'title'] ??
                                                  'No title'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Tanggal: ${DateFormat('yyyy-MM-dd').format(
                                                DateTime.fromMillisecondsSinceEpoch(
                                                    int.tryParse(jsonDecode(
                                                                    appointment
                                                                        .notes!)[
                                                                'exam_date']
                                                            .toString())! *
                                                        1000),
                                              )}'),
                                              const SizedBox(
                                                  height:
                                                      4), // Jarak antara teks
                                              Text(
                                                'KLIK UNTUK MELIHAT DETAIL',
                                                style: TextStyle(
                                                    color: Colors.blue,
                                                    fontStyle: FontStyle
                                                        .italic), // Gaya teks
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            _showDetailDialog(context,
                                                jsonDecode(appointment.notes!));
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
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
