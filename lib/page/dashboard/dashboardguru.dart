import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../book/absensiguru.dart';
import '../book/gurupage2.dart';
import '../book/nilaiguru.dart';
import '../notify/kalender.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';

class DashboardGuruPage extends StatefulWidget {
  final int noidguru;
  final int mengajar;
  final String namaguru;

  const DashboardGuruPage({
    Key? key,
    required this.noidguru,
    required this.mengajar,
    required this.namaguru,
  }) : super(key: key);

  @override
  _DashboardGuruPageState createState() => _DashboardGuruPageState();
}

class _DashboardGuruPageState extends State<DashboardGuruPage> {
  List<dynamic> data = []; // Stores all data
  List<dynamic> daySpecificData = []; // Stores data for the selected day
  bool isLoading = true;
  int _selectedIndex = 0;
  bool showWhiteScreen = false; // State for showing white screen
  String selectedDay = ""; // Store the selected day
  bool isExpanded = false;
  bool isLocked = true;
  String day = '';

  @override
  void initState() {
    super.initState();
    _clearCache(); // Clear cache when page loads
    fetchData(); // Call fetchData to get initial data
  }

  // Function to clear cache
  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_time'); // Remove cache time
    await prefs.remove('class_routine_cache'); // Remove class routine cache
    print("Cache and cache_time cleared.");
  }

  // Function to fetch data
  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('class_routine_cache');

    if (cachedData != null) {
      final decodedData = json.decode(cachedData);
      setState(() {
        data = decodedData['data'];
        isLoading = false;
      });
      print("Using cached data.");
    } else {
      print("No valid cache found. Fetching new data...");
      await _fetchAndCacheData(
          prefs); // Directly fetch fresh data without checking cache time
    }
  }

  // Get the current day in English (e.g., Monday, Tuesday)
  String getCurrentDayInEnglish() {
    final DateTime now = DateTime.now();
    final String day = DateFormat('EEEE').format(now);
    return day; // Return day in English (e.g., "Monday", "Tuesday")
  }

  // Fetch and cache data
  Future<void> _fetchAndCacheData(SharedPreferences prefs) async {
    String day = getCurrentDayInEnglish(); // Get current day in English
    final String url =
        'https://api-pinakad.pintarkerja.com/get_dashboard_OLD22.php?noidguru=${widget.noidguru}&day=$day';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData['status'] == 'success') {
          setState(() {
            data = decodedData['data']; // Data langsung diambil
            isLoading = false;

            // Menyimpan data yang diperbarui ke cache
            prefs.setString('class_routine_cache', json.encode(decodedData));
            print("Data fetched and cached.");
          });
        } else {
          throw Exception('Failed to load data: ${decodedData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  // Fetch data for a specific day (selected day)
  Future<void> fetchDataByDay(String day) async {
    final String url =
        'https://api-pinakad.pintarkerja.com/get_dashboard_OLD2.php?noidguru=${widget.noidguru}&day=$day';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Remove the "Connected successfully" part from the response body
        String rawResponse = response.body.trim();
        if (rawResponse.startsWith("Connected successfully")) {
          rawResponse = rawResponse.substring("Connected successfully".length);
        }

        print('Trimmed response body: $rawResponse');

        try {
          final decodedData = json.decode(rawResponse);
          if (decodedData['status'] == 'success') {
            setState(() {
              daySpecificData = decodedData['data'];
              showWhiteScreen = true;
            });
          } else {
            setState(() {
              daySpecificData = [];
              showWhiteScreen = true;
            });
          }
        } catch (e) {
          print("Error decoding JSON: $e");
          setState(() {
            showWhiteScreen = false;
          });
        }
      } else {
        setState(() {
          showWhiteScreen = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        showWhiteScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final currentHour = DateTime.now().hour;
    final currentMinute = DateTime.now().minute;

    // Process ongoing and upcoming classes (as before)
    List<dynamic> ongoingClasses = [];
    List<dynamic> upcomingClasses = [];

    for (var item in data) {
      final int startHour = int.parse(item['time_start']);
      final int startMinute = int.parse(item['time_start_min']);
      final int endHour = int.parse(item['time_end']);
      final int endMinute = int.parse(item['time_end_min']);

      final startTimeInMinutes = startHour * 60 + startMinute;
      final endTimeInMinutes = endHour * 60 + endMinute;
      final currentTimeInMinutes = currentHour * 60 + currentMinute;

      print(
          "Checking class: ${item['name']}, Start: $startTimeInMinutes, End: $endTimeInMinutes, Current Time: $currentTimeInMinutes");

      if (currentTimeInMinutes >= startTimeInMinutes &&
          currentTimeInMinutes < endTimeInMinutes) {
        ongoingClasses.add(item);
      } else if (currentTimeInMinutes < startTimeInMinutes) {
        upcomingClasses.add(item);
      }
    }

    List<String> daysOfWeek = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logop.png',
                fit: BoxFit.contain,
                height: 40,
              ),
              SizedBox(
                  width: 65), // Adds some spacing between the logo and the name
              Text(
                widget.namaguru, // Display the full name from the widget
                style: TextStyle(
                  fontSize: 12, // Adjust the font size as necessary
                  //fontWeight: FontWeight.bold, // Optional: Make the text bold
                  color: Colors.white, // Text color
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 69, 206, 236),
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Display ongoing classes (as before)
                    const Text('Kelas Sedang Berlangsung :',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 16),
                    // Kelas Sedang Berlangsung
                    if (ongoingClasses.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 90,
                        decoration: ShapeDecoration(
                          color: Color.fromARGB(255, 247, 148, 1),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 247, 148, 1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      DateFormat('EEEE, d MMMM yyyy')
                                          .format(DateTime.now()),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 0),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${ongoingClasses[0]['time_start']} - ${ongoingClasses[0]['time_end']} WIB',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${ongoingClasses[0]['name']}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, 30),
                                    child: Image.asset(
                                      'assets/images/blackboard1.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    const Text(
                      'Kelas Selanjutnya: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    // Kelas Selanjutnya (Hanya 1 Kelas yang ditampilkan)
                    if (upcomingClasses.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 90,
                        decoration: ShapeDecoration(
                          color: Color.fromARGB(255, 69, 206, 236),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 69, 206, 236)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      DateFormat('EEEE, d MMMM yyyy')
                                          .format(DateTime.now().add(
                                        Duration(
                                          minutes: (int.parse(upcomingClasses[0]
                                                          ['time_start']) *
                                                      60 +
                                                  int.parse(upcomingClasses[0]
                                                      ['time_start_min'])) -
                                              (currentHour * 60 +
                                                  currentMinute),
                                        ),
                                      )),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 0),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${upcomingClasses[0]['time_start']} - ${upcomingClasses[0]['time_end']} WIB',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${upcomingClasses[0]['name']}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, 20),
                                    child: Image.asset(
                                      'assets/images/pepen1.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                    const Text('Jadwal Mengajar Sepekan: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        // Display days of the week (Monday to Saturday)
                        Column(
                          children: daysOfWeek.map((day) {
                            return Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: ExpansionTile(
                                title: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 69, 206, 236),
                                    minimumSize: Size(
                                      MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.height * 0.06,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isLocked = !isLocked;
                                      selectedDay = day;
                                      // Map the selected day to the English day
                                      if (selectedDay == 'Senin') {
                                        day = 'Monday';
                                      } else if (selectedDay == 'Selasa') {
                                        day = 'Tuesday';
                                      } else if (selectedDay == 'Rabu') {
                                        day = 'Wednesday';
                                      } else if (selectedDay == 'Kamis') {
                                        day = 'Thursday';
                                      } else if (selectedDay == 'Jumat') {
                                        day = 'Friday';
                                      } else if (selectedDay == 'Sabtu') {
                                        day = 'Saturday';
                                      }
                                      showWhiteScreen =
                                          true; // Allow data to be displayed
                                    });

                                    print("Fetching data for $day...");
                                    fetchDataByDay(
                                        day); // Trigger data fetch for selected day
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Image.asset(
                                        isLocked
                                            ? 'assets/images/jam1.png' // Locked icon
                                            : 'assets/images/jam1.png', // Same image for both states (you can change this)
                                        width: 24,
                                        height: 24,
                                      ),
                                    ],
                                  ),
                                ),
                                onExpansionChanged: (bool expanded) {
                                  setState(() {
                                    isExpanded = expanded;
                                  });
                                },
                                children: [
                                  // Display data when the screen is white and the correct day is selected
                                  if (showWhiteScreen &&
                                      selectedDay == day &&
                                      daySpecificData.isNotEmpty)
                                    Container(
                                      height: screenHeight *
                                          0.8, // Adjust height based on screen size
                                      child: ListView.builder(
                                        itemCount: daySpecificData.length,
                                        itemBuilder: (context, index) {
                                          final item = daySpecificData[index];
                                          final timeStart =
                                              '${item['time_start']}:${item['time_start_min']} WIB';
                                          final timeEnd =
                                              '${item['time_end']}:${item['time_end_min']} WIB';
                                          final subject =
                                              item['name']?.toString() ??
                                                  'No Subject';
                                          final teacherName =
                                              '${item['first_name']} ${item['last_name']}';
                                          final className =
                                              'Class: ${item['namek']?.toString() ?? ''}';

                                          return GestureDetector(
                                            child: Container(
                                              width: double.infinity,
                                              height: 82,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Stack(
                                                children: [
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    child: Container(
                                                      width:
                                                          screenWidth * 0.9 - 3,
                                                      height: 82,
                                                      decoration:
                                                          ShapeDecoration(
                                                        color: Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        shadows: const [
                                                          BoxShadow(
                                                            color: Color(
                                                                0x0C000000),
                                                            blurRadius: 20,
                                                            offset:
                                                                Offset(0, 0),
                                                            spreadRadius: 0,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left:
                                                        screenWidth * 0.9 - 90,
                                                    top: 46,
                                                    child: Text(
                                                      className,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF4B4B4B),
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 0.30,
                                                        letterSpacing: -0.20,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 10,
                                                    top: 23,
                                                    child: Text(
                                                      subject,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF4B4B4B),
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 0.30,
                                                        letterSpacing: -0.20,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 218,
                                                    top: 23,
                                                    child: Text(
                                                      '$timeStart - $timeEnd',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF4B4B4B),
                                                        fontSize: 10,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        height: 0.30,
                                                        letterSpacing: -0.20,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 10,
                                                    top: 40,
                                                    child: Text(
                                                      teacherName,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF4B4B4B),
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 0.21,
                                                        letterSpacing: -0.24,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  // If no data, show a placeholder or message
                                  if (showWhiteScreen &&
                                      selectedDay == day &&
                                      daySpecificData.isEmpty)
                                    Center(
                                        child: Text(
                                            'No data available for this day.')),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          height: 125, // Increased height to make space for the stacked items
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 30,
                child: Container(
                  width: 72,
                  height: 96,
                  decoration: ShapeDecoration(
                    color: Color(0xFFF99436),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: Color(0xFF748A9C)),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 80,
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
                top: 43,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/jam.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 288,
                top: 47,
                child: GestureDetector(
                  onTap: () async {
                    // Logout logic here
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(
                        'class_routine_cache'); // Remove the cached data
                    await prefs
                        .remove('cache_time'); // Remove the cache timestamp
                    await prefs.remove(
                        'user_token'); // Optional: remove user authentication token
                    // Add any other data you need to clear

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
                          top: 0,
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
                          top: 47,
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
                          top: 13,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/keluar.png"),
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
                top: 47,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to the BookPage when the widget is tapped
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NilaiGuru(
                            noidguru: widget.noidguru,
                            mengajar: widget.mengajar,
                            namaguru: widget.namaguru),
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
                          top: 0,
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
                          top: 42,
                          child: SizedBox(
                            width: 72,
                            height: 35,
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
                        Positioned(
                          left: 21,
                          top: 13,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/nilai.png"),
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
                left: 216,
                top: 47,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AbsensiGuru(
                            noidguru: widget.noidguru,
                            mengajar: widget.mengajar,
                            namaguru: widget.namaguru),
                      ),
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 120, // Adjusted height for better spacing
                    child: Stack(
                      children: [
                        // Background container
                        Positioned(
                          left: 0,
                          top: 0,
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
                        // Text: Absensi
                        Positioned(
                          left: 0,
                          top: 50, // Adjusted to align text properly
                          child: SizedBox(
                            width: 72,
                            height: 38,
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
                        // Icon/Image
                        Positioned(
                          left: 21,
                          top: 10, // Adjusted position for proper alignment
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/absensi.png"),
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
                left: 72,
                top: 47,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to the BookPage when the widget is tapped
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuruPage2(
                            noidguru: widget.noidguru,
                            mengajar: widget.mengajar,
                            namaguru: widget.namaguru),
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
                          top: 0,
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
                          top: 40,
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
                          left: 21,
                          top: 11,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/tugaspr.png"),
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
        ));
  }
}
