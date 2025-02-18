import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:intl/intl.dart';
import 'package:pintar_akademik/main.dart';
import 'package:pintar_akademik/page/absen/absen_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dashboard/dashboard.dart';
import 'nilaisiswa.dart';
import 'siswapage2.dart'; // Untuk formatting tanggal

class AbsenSiswa extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const AbsenSiswa({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
    required this.namalengkap,
  }) : super(key: key);

  @override
  _AbsenSiswaState createState() => _AbsenSiswaState();
}

class _AbsenSiswaState extends State<AbsenSiswa> {
  bool isLoading = true; // Untuk loading state
  EventList<Event> _markedDateMap =
      EventList<Event>(events: {}); // Map untuk event
  DateTime _currentDate = DateTime.now(); // Tanggal saat ini
  DateTime _selectedDate = DateTime.now(); // Tanggal yang dipilih

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Mengambil data event dari API
    _addWeekendEvents(); // Menambahkan event untuk Sabtu dan Minggu
  }

  // Fungsi untuk mengambil data event dari API
  Future<void> _fetchEvents() async {
    final url =
        'https://api-pinakad.pintarkerja.com/get-absen.php?class_id=${widget.classId}&student_id=${widget.studentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _markedDateMap.clear(); // Hapus event lama

          // Menambahkan event berdasarkan status
          for (var event in data['data']) {
            // Ambil timestamp yang berupa string dari server (longtext)
            String timestampString = event['timestamp'];

            // Cek apakah timestamp bisa diubah menjadi angka (Unix timestamp dalam detik)
            try {
              int timestamp =
                  int.parse(timestampString); // Mengonversi string ke integer

              // Konversi timestamp ke DateTime dalam UTC
              DateTime eventDate = DateTime.fromMillisecondsSinceEpoch(
                  timestamp * 1000,
                  isUtc: true);

              // Konversi ke zona waktu lokal
              DateTime eventDateLocal = eventDate.toLocal();

              // Ambil hanya tanggal (tanpa waktu) dalam waktu lokal
              DateTime eventDateOnly = DateTime(eventDateLocal.year,
                  eventDateLocal.month, eventDateLocal.day);

              int status = event['status'];
              String eventTitle = 'Status $status';

              print('Adding event on $eventDateOnly with status $status');

              // Menambahkan event ke _markedDateMap
              _markedDateMap.add(
                eventDateOnly, // Pastikan kita menggunakan DateTime tanpa waktu
                Event(
                  date: eventDateOnly,
                  title: eventTitle,
                  // Menambahkan background warna sesuai status
                  icon: _eventBackground(status, eventDateOnly),
                ),
              );
            } catch (e) {
              print('Error parsing timestamp: $timestampString');
            }
          }

          // Debug: Tampilkan semua event yang ditambahkan
          _markedDateMap.events.forEach((date, events) {
            print(
                'Date: $date, Events: ${events.map((e) => e.title).toList()}');
          });

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk menambahkan background untuk status event
  Widget _eventBackground(int status, DateTime date) {
    Color backgroundColor;

    // Background berdasarkan status event
    switch (status) {
      case 1:
        backgroundColor = Colors.green; // Event status 1 (green)
        break;
      case 2:
        backgroundColor = Colors.yellow; // Event status 2 (yellow)
        break;
      case 3:
        backgroundColor = Colors.grey; // Event status 3 (grey)
        break;
      default:
        backgroundColor =
            const Color.fromARGB(255, 253, 18, 1); // Default status (blue)
    }

    // Menambahkan background untuk hari Sabtu dan Minggu
    if (date.weekday == 6 || date.weekday == 7) {
      // Sabtu (6) atau Minggu (7)
      backgroundColor = Colors.purple; // Ungu untuk akhir pekan
    }

    print('Generating background color $backgroundColor');

    return Container(
      width: 40, // Sesuaikan dengan ukuran yang diinginkan
      height: 40, // Sesuaikan dengan ukuran yang diinginkan
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.rectangle,
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Center(
        child: Text(
          '${date.day}', // Menampilkan tanggal (angka) di dalam latar belakang
          style: TextStyle(
            color: const Color.fromARGB(255, 10, 0, 0),
            fontSize: 16, // Ukuran font sesuai keinginan
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Fungsi untuk menambahkan event untuk Sabtu dan Minggu dengan background ungu
  void _addWeekendEvents() {
    for (int i = 1; i <= 12; i++) {
      for (int j = 1; j <= 31; j++) {
        DateTime date = DateTime(2024, i, j);

        // Jika hari itu Sabtu (6) atau Minggu (7)
        if (date.weekday == 6 || date.weekday == 7) {
          // Tambahkan event dengan background ungu
          _markedDateMap.add(
            date,
            Event(
              date: date,
              title: 'Weekend', // Anda bisa menyesuaikan title
              icon: _eventBackground(0, date), // Menggunakan background ungu
            ),
          );
        }
      }
    }
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
          backgroundColor: const Color.fromARGB(255, 69, 206, 236),
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
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(10.0), // Padding is already safe
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 9),
                    // Limit the height of the CalendarCarousel
                    Container(
                      height: 330,
                      padding: EdgeInsets.all(10.0),
                      child: CalendarCarousel<Event>(
                        markedDatesMap: _markedDateMap,
                        markedDateShowIcon: true,
                        markedDateIconBuilder: (event) => event.icon,
                        markedDateIconMargin: 4.0,
                        selectedDayButtonColor: Colors.blue,
                        todayButtonColor: Colors.green,
                        todayTextStyle: TextStyle(
                          color: Colors.white,
                        ),
                        selectedDayTextStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),

                    // Stack Progress Bar
                    Container(
                      width: 310,
                      height: 52,
                      child: Stack(
                        children: [
                          // Circular Indicators
                          Positioned(
                            left: 0,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color.fromARGB(255, 4, 249, 65),
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            top: 0,
                            child: SizedBox(
                              width: 35,
                              height: 16,
                              child: Text(
                                'Hadir',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 53,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Colors.yellow,
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 72,
                            top: 0,
                            child: SizedBox(
                              width: 95,
                              height: 16,
                              child: Text(
                                'Terlambat',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 124,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color.fromARGB(255, 252, 13, 0),
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 142,
                            top: 0,
                            child: SizedBox(
                              width: 68,
                              height: 16,
                              child: Text(
                                'Absen',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 227,
                            top: 1,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: ShapeDecoration(
                                color: Color(0xFFD9D9D9),
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 245,
                            top: 0,
                            child: SizedBox(
                              width: 77,
                              height: 16,
                              child: Text(
                                'Libur',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 1),
                    if (_markedDateMap.getEvents(_selectedDate).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event on ${DateFormat.yMMMMd().format(_selectedDate)}:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          ..._markedDateMap
                              .getEvents(_selectedDate)
                              .map((event) => ListTile(
                                    leading: event.icon,
                                  ))
                              .toList(),
                        ],
                      )
                    else
                      Center(
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to the BookPage when the widget is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AbsenPage(
                                  classId: widget.classId,
                                  sectionId: widget.sectionId,
                                  studentId: widget.studentId,
                                  subjectId: widget.subjectId,
                                  latId: 0.0,
                                  longId: 0.0,
                                  namalengkap: widget.namalengkap,
                                ),
                              ),
                            );
                          },
                          child: Text("Absen Mandiri Siswa"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
            height: 145,
            decoration: BoxDecoration(
              color: Color.fromARGB(0, 252, 252, 252),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                // Navigate to the BookPage when the widget is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPage(
                        classId: widget.classId,
                        sectionId: widget.sectionId,
                        studentId: widget.studentId,
                        subjectId: widget.subjectId,
                        alamat: widget.alamat,
                        status: widget.status,
                        namalengkap: widget.namalengkap),
                  ),
                );
              },
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 65,
                    child: Container(
                      width: 72,
                      height: 90,
                      decoration: ShapeDecoration(
                        color: Color(0xFF00C1FF),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Color(0xFF2EA0FC)),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 110,
                    child: SizedBox(
                      width: 72,
                      height: 80,
                      child: Text(
                        'Jadwal\nKelas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 21,
                    top: 75,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/jam1.png"),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 288,
                    top: 57,
                    child: GestureDetector(
                      onTap: () async {
                        // Show loading indicator before logging out (optional)
                        // Perform logout logic
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(
                            'class_routine_cache'); // Remove the cached data
                        await prefs
                            .remove('cache_time'); // Remove the cache timestamp
                        await prefs.remove(
                            'user_token'); // Optional: remove user authentication token

                        // Navigate to login screen or home page after logging out
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyHomePage(), // Your login page widget
                          ),
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 90,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 10,
                              child: Container(
                                width: 72,
                                height: 92,
                                decoration: ShapeDecoration(
                                  color: Color(0xFF00C1FF),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        width: 1, color: Color(0xFF2EA0FC)),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 57,
                              child: SizedBox(
                                width: 72,
                                height: 15,
                                child: Text(
                                  'Keluar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 21,
                              top: 20,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/images/keluar.png"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 144,
                    top: 57,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NilaiSiswa(
                              classId: widget.classId,
                              sectionId: widget.sectionId,
                              studentId: widget.studentId,
                              subjectId: widget.subjectId,
                              alamat: widget.alamat,
                              status: widget.status,
                              namalengkap: widget.namalengkap,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 120, // Total height to fit both text and image
                        child: Stack(
                          clipBehavior: Clip
                              .none, // Prevents clipping of overflowing widgets
                          children: [
                            // Background container
                            Positioned(
                              left: 0,
                              top: 10,
                              child: Container(
                                width: 72,
                                height: 92,
                                decoration: ShapeDecoration(
                                  color: Color(0xFF00C1FF),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: Color(0xFF2EA0FC),
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Text "Nilai Siswa"
                            Positioned(
                              left: 0,
                              top:
                                  60, // Adjusted position to avoid overlapping with the icon
                              child: SizedBox(
                                width: 72,
                                child: Text(
                                  'Nilai\nSiswa',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            // Icon Image
                            Positioned(
                              left: 21,
                              top:
                                  18, // Adjusted position to align with the background
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/images/nilai.png"),
                                    fit: BoxFit
                                        .contain, // Ensures the image scales appropriately
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 216,
                    top: 38,
                    child: Container(
                      width: 72,
                      height: 110,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AbsenSiswa(
                                      classId: widget.classId,
                                      sectionId: widget.sectionId,
                                      studentId: widget.studentId,
                                      subjectId: widget.subjectId,
                                      alamat: widget.alamat,
                                      status: widget.status,
                                      namalengkap: widget.namalengkap,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 72,
                                height: 110,
                                decoration: ShapeDecoration(
                                  color: Color.fromARGB(172, 108, 184, 73),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        width: 1, color: Color(0xFF2EA0FC)),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(50),
                                      topRight: Radius.circular(50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 65,
                            child: SizedBox(
                              width: 72,
                              height: 48,
                              child: Text(
                                'Absensi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            top: 10,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("assets/images/catke.png"),
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 72,
                    top: 47,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to the BookPage when the widget is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SiswaPage2(
                                classId: widget.classId,
                                sectionId: widget.sectionId,
                                studentId: widget.studentId,
                                subjectId: widget.subjectId,
                                alamat: widget.alamat,
                                status: widget.status,
                                namalengkap: widget.namalengkap),
                          ),
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 100,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 19,
                              child: Container(
                                width: 72,
                                height: 100,
                                decoration: ShapeDecoration(
                                  color: Color(0xFF00C1FF),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        width: 1, color: Color(0xFF2EA0FC)),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 62,
                              child: SizedBox(
                                width: 72,
                                height: 35,
                                child: Text(
                                  'Tugas\nPR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              top: 25,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/images/tugaspr.png"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}
