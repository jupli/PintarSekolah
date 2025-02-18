import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'detailtugas.dart';
import 'dispminggu.dart';

class TugasPrPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const TugasPrPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _TugasPrPageState createState() => _TugasPrPageState();
}

class _TugasPrPageState extends State<TugasPrPage> {
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

            // Handle null dates safely, treat nulls as smaller (earlier)
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

// Helper function to parse dates with different formats
  DateTime? _parseDate(String dateString) {
    try {
      // Try parsing 'yyyy-MM-dd HH:mm:ss' first
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateString);
    } catch (e) {
      // If failed, try parsing 'dd/MM/yyyy hh:mm a'
      try {
        return DateFormat('dd/MM/yyyy hh:mma').parse(dateString);
      } catch (e) {
        // Handle parsing failure, return null or log the issue
        print('Error parsing date: $dateString');
        return null;
      }
    }
  }

  List<Appointment> _getCalendarData() {
    List<Appointment> appointments = [];

    mataPelajaranDetail.forEach((subjectId, detailData) {
      for (var data in detailData) {
        // Parse publish_date to DateTime
        final DateTime? examDate = data['publish_date'] != null
            ? DateTime.tryParse(data['publish_date'].toString())
            : null;

        if (examDate != null) {
          // Handle date_end as DateTime
          DateTime? endDate = data['date_end'] != null
              ? DateFormat('dd/MM/yyyy').parse(data['date_end'].toString())
              : null;

          // Default end time is 1 hour after examDate if endDate is null
          endDate ??= examDate.add(const Duration(hours: 1));

          // Check the title to decide the color
          Color appointmentColor;
          String title = data['title'] ?? 'No pelajaran';

          Map<String, Color> subjectColors = {
            'Matematika': const Color.fromRGBO(255, 0, 0, 1),
            'Bahasa Indonesia': const Color.fromARGB(255, 0, 179, 255),
            'Bahasa Arab': const Color.fromARGB(255, 0, 255, 26),
            'Fisika': const Color.fromARGB(255, 17, 0, 255),
            'IPS': const Color.fromARGB(255, 0, 255, 187),
          };

          appointmentColor = subjectColors.entries
              .firstWhere((entry) => title.contains(entry.key),
                  orElse: () => MapEntry(
                      'Default', const Color.fromARGB(255, 226, 243, 33)))
              .value;

          appointments.add(Appointment(
            startTime: examDate,
            endTime: endDate,
            subject: title,
            color: appointmentColor, // Set color based on title
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
          'KALENDER PR/TUGAS',
          style: TextStyle(
            color: Colors.white, // Mengubah warna teks menjadi putih
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Color.fromRGBO(255, 255, 255, 1)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Membungkus seluruh body dengan SingleChildScrollView
              child: Column(
                children: [
                  // Gunakan Expanded agar kalender mengisi ruang yang tersisa
                  SizedBox(
                    height: 400, // Sesuaikan tinggi yang diinginkan
                    width: 300,
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
                              builder: (context) => TugasPrMPage(
                                classId: widget.classId,
                                sectionId: widget.sectionId,
                                studentId: widget.studentId,
                                subjectId: widget.subjectId,
                                alamat: widget.alamat,
                                status: widget.status,
                              ),
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
                        // Informasi Matematika
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: const Color.fromRGBO(
                                  255, 0, 0, 1), // Warna Matematika
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Matematika (Warna Merah)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Informasi Bahasa Indonesia
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: const Color.fromARGB(
                                  255, 0, 179, 255), // Warna Bahasa Indonesia
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Bahasa Indonesia (Warna Biru Muda)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Informasi Bahasa Arab
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: const Color.fromARGB(
                                  255, 0, 255, 26), // Warna Bahasa Arab
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Bahasa Arab (Warna Hijau)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Informasi Fisika
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: const Color.fromARGB(
                                  255, 17, 0, 255), // Warna Fisika
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Fisika (Warna Biru Tua)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Informasi IPS
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: const Color.fromARGB(
                                  255, 0, 255, 187), // Warna IPS
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'IPS (Warna Hijau Muda)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
