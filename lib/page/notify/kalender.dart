import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Import other necessary pages
import '../book/bookpage.dart';
import '../dashboard/dashboard.dart';
import '../mapel/mapel.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';

class KalenderPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const KalenderPage(
      {Key? key,
      required this.classId,
      required this.sectionId,
      required this.studentId,
      required this.subjectId,
      required this.alamat,
      required this.status,
      required this.namalengkap})
      : super(key: key);

  @override
  _KalenderPageState createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> pengumumanData = [];
  List<dynamic> ulanganData = [];
  List<dynamic> semesterData = [];
  bool isLoading = true;
  TabController? _tabController;
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final pengumumanResponse = await http.get(
        Uri.parse(
            'http://api-pinakad.pintarkerja.com/pengumuman.php?class_id=${widget.classId}&subject_id=${widget.sectionId}'),
      );
      final ulanganResponse = await http.get(
        Uri.parse(
            'http://api-pinakad.pintarkerja.com/ulangan.php?class_id=${widget.classId}'),
      );
      final semesterResponse = await http.get(
        Uri.parse(
            'http://api-pinakad.pintarkerja.com/semester.php?class_id=${widget.classId}'),
      );

      if (pengumumanResponse.statusCode == 200) {
        final pengumumanJson = json.decode(pengumumanResponse.body);
        if (pengumumanJson['status'] == 'success') {
          setState(() {
            pengumumanData = pengumumanJson['data'] ?? [];
          });
        } else {
          print('Pengumuman Error: ${pengumumanJson['message']}');
          setState(() {
            pengumumanData = [];
          });
        }
      } else {
        print('Failed to load pengumuman data');
        setState(() {
          pengumumanData = [];
        });
      }

      if (ulanganResponse.statusCode == 200) {
        final ulanganJson = json.decode(ulanganResponse.body);
        if (ulanganJson['status'] == 'success') {
          setState(() {
            ulanganData = ulanganJson['data'] ?? [];
          });
        } else {
          print('Ulangan Error: ${ulanganJson['message']}');
          setState(() {
            ulanganData = [];
          });
        }
      } else {
        print('Failed to load ulangan data');
        setState(() {
          ulanganData = [];
        });
      }

      if (semesterResponse.statusCode == 200) {
        final semesterJson = json.decode(semesterResponse.body);
        if (semesterJson['status'] == 'success') {
          setState(() {
            semesterData = semesterJson['data'] ?? [];
          });
        } else {
          print('Semester Error: ${semesterJson['message']}');
          setState(() {
            semesterData = [];
          });
        }
      } else {
        print('Failed to load semester data');
        setState(() {
          semesterData = [];
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
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
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pengumuman'),
            Tab(text: 'Jadwal Ulangan'),
            Tab(text: 'Ujian Semester'),
          ],
          labelColor: const Color.fromARGB(255, 255, 234, 0),
          unselectedLabelColor: Colors.white54,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                buildTabContentPengumuman(pengumumanData),
                buildTabContentUlangan(ulanganData),
                buildTabContentSemester(semesterData),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 31, 40, 174),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/bxs_home-alt-2.png')),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/mapel3.png')),
            label: 'Mapel',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/bxs_book-alt.png')),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/entypo_video.png')),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/bell.png')),
            label: 'Notify',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/person.png')),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: const Color.fromARGB(255, 31, 40, 174),
        onTap: _onItemTapped,
      ),
    );
  }

  // Function to build content for the 'Pengumuman' tab
  Widget buildTabContentPengumuman(List<dynamic> data) {
    return SfCalendar(
      view: CalendarView.month,
      dataSource: MeetingDataSource(_getPengumumanDataSource(data)),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
      ),
      appointmentTextStyle: const TextStyle(
        fontSize: 14.0, // Ensure font size is valid
        color: Colors.black, // Default text color
      ),
    );
  }

  // Function to build content for the 'Jadwal Ulangan' tab
  Widget buildTabContentUlangan(List<dynamic> data) {
    return SfCalendar(
      view: CalendarView.month,
      dataSource: MeetingDataSource(_getUlanganDataSource(data)),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
      ),
      appointmentTextStyle: const TextStyle(
        fontSize: 14.0, // Ensure font size is valid
        color: Colors.black, // Default text color
      ),
    );
  }

  // Function to build content for the 'Ujian Semester' tab
  Widget buildTabContentSemester(List<dynamic> data) {
    return SfCalendar(
      view: CalendarView.month,
      dataSource: MeetingDataSource(_getSemesterDataSource(data)),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
      ),
      appointmentTextStyle: const TextStyle(
        fontSize: 14.0, // Ensure font size is valid
        color: Colors.black, // Default text color
      ),
    );
  }

  // Function to fetch and map 'Pengumuman' data to appointments
  List<Appointment> _getPengumumanDataSource(List<dynamic> events) {
    List<Appointment> appointments = <Appointment>[];

    for (var event in events) {
      try {
        final DateTime startTime =
            DateTime.parse('${event['date']} ${event['time']}');
        final String subject = event['notify'] ?? 'No Subject';

        appointments.add(Appointment(
          startTime: startTime,
          endTime: startTime
              .add(const Duration(hours: 1)), // Assuming 1 hour duration
          subject: subject,
          color: Colors.blue, // Default color
        ));
      } catch (e) {
        print('Error parsing event: $e');
      }
    }

    return appointments;
  }

  List<Appointment> _getUlanganDataSource(List<dynamic> events) {
    List<Appointment> appointments = <Appointment>[];

    for (var event in events) {
      try {
        final String startDateTimeStr = '${event['start']}';
        final String endDateTimeStr = '${event['end']}';
        final DateTime startTime = DateTime.parse(startDateTimeStr);
        final DateTime endTime = DateTime.parse(endDateTimeStr);
        final String subject = event['title'] ?? 'No Title';
        final String colorStr =
            event['color'] ?? '#0000FF'; // Default to blue if color is null

        appointments.add(Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: subject,
          color: Color(int.parse(colorStr.replaceFirst('#', '0xFF'))),
        ));
      } catch (e) {
        print('Error parsing ulangan event: $e');
      }
    }

    return appointments;
  }

  List<Appointment> _getSemesterDataSource(List<dynamic> events) {
    List<Appointment> appointments = <Appointment>[];

    for (var event in events) {
      try {
        final DateTime startTime = DateTime.parse(event['start']);
        final DateTime endTime = DateTime.parse(event['end']);
        final String subject = event['name'] ?? 'No Name';

        appointments.add(Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: subject,
          color: Colors.red, // Default color
        ));
      } catch (e) {
        print('Error parsing semester event: $e');
      }
    }

    return appointments;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
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
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MapelPage(
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
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookPage(
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
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPage(
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
          break;
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => KalenderPage(
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
          break;
        case 5:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
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
          break;
        default:
          break;
      }
    });
  }
}

// Custom DataSource for Calendar
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
