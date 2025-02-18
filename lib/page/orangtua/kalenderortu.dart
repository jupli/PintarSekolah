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

class KalenderOrtuPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;

  const KalenderOrtuPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _KalenderOrtuPageState createState() => _KalenderOrtuPageState();
}

class _KalenderOrtuPageState extends State<KalenderOrtuPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> pengumumanData = [];
  List<dynamic> ulanganData = [];
  List<dynamic> semesterData = [];
  bool isLoading = true;
  late TabController _tabController;
  late CalendarController _calendarController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calendarController = CalendarController();
    _selectedDate = DateTime.now();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await Future.wait([
        _fetchData('pengumuman', pengumumanData, 'pengumuman.php'),
        _fetchData('ulangan', ulanganData, 'ulangan.php'),
        _fetchData('semester', semesterData, 'semester.php'),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchData(
      String type, List<dynamic> data, String endpoint) async {
    final response = await http.get(Uri.parse(
        'http://api-pinakad.pintarkerja.com/$endpoint?class_id=${widget.classId}'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          data.clear();
          data.addAll(jsonData['data'] ?? []);
        });
      } else {
        print('$type Error: ${jsonData['message']}');
      }
    } else {
      print('Failed to load $type data: ${response.statusCode}');
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      _calendarController.displayDate = _selectedDate;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      _calendarController.displayDate = _selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logop.png',
            fit: BoxFit.contain, height: 40),
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
                _buildTabContent(pengumumanData, _getPengumumanDataSource),
                _buildTabContent(ulanganData, _getUlanganDataSource),
                _buildTabContent(semesterData, _getSemesterDataSource),
              ],
            ),
    );
  }

  Widget _buildTabContent(List<dynamic> data,
      List<Appointment> Function(List<dynamic>) dataSourceBuilder) {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(
          child: SfCalendar(
            view: CalendarView.month,
            controller: _calendarController,
            dataSource: MeetingDataSource(dataSourceBuilder(data)),
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
              showAgenda: true,
            ),
            appointmentTextStyle: TextStyle(
              fontSize: 14.0 < 0 ? 12.0 : 14.0, // Fallback to 12.0 if negative
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
        Text('${_selectedDate.month}/${_selectedDate.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
            icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
      ],
    );
  }

  List<Appointment> _getPengumumanDataSource(List<dynamic> events) {
    return _getDataSource(events, 'date', 'time', 'notify', Colors.blue);
  }

  List<Appointment> _getUlanganDataSource(List<dynamic> events) {
    return _getDataSource(events, 'start', 'end', 'title', Colors.blue,
        isEndTime: true);
  }

  List<Appointment> _getSemesterDataSource(List<dynamic> events) {
    return _getDataSource(events, 'start', 'end', 'name', Colors.red,
        isEndTime: true);
  }

  List<Appointment> _getDataSource(List<dynamic> events, String startKey,
      String? endKey, String titleKey, Color defaultColor,
      {bool isEndTime = false}) {
    List<Appointment> appointments = <Appointment>[];

    for (var event in events) {
      try {
        final DateTime startTime = DateTime.parse(event[startKey]);
        final DateTime endTime = isEndTime
            ? DateTime.parse(event[endKey])
            : startTime.add(
                const Duration(hours: 1)); // 1 hour duration for single events
        final String subject = event[titleKey] ?? 'No Subject';

        appointments.add(Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: subject,
          color: defaultColor,
        ));
      } catch (e) {
        print('Error parsing event: $e');
      }
    }

    return appointments;
  }

  void _onItemTapped(int index) {
    // Handle navigation here
  }
}

// Custom DataSource for Calendar
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
