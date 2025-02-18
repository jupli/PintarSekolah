import 'dart:convert';
import 'package:pintar_akademik/page/book/bookpage.dart';
import 'package:pintar_akademik/page/mapel/mapel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart'; //

import 'package:pintar_akademik/page/dashboard/dashboard.dart';
import 'package:pintar_akademik/page/notify/notify_pade.dart';
import 'package:pintar_akademik/page/video/video_page.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const ProfilePage({
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
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<dynamic> profileData = [];
  List<dynamic> passwordData = [];
  List<dynamic> emailData = [];
  List<dynamic> kehadiranData = [];
  List<dynamic> penilaianData = [];
  List<dynamic> pembayaranData = [];
  Map<String, List<dynamic>> mataPelajaranDetail = {};

  bool isLoading = true;
  int _selectedIndex = 4; // Set default index to 'Profile'

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final urls = {
      'Profile':
          'http://api-pinakad.pintarkerja.com/profile.php?student_id=${widget.studentId}',
      'Password':
          'http://api-pinakad.pintarkerja.com/profile.php?student_id=${widget.studentId}',
      'Email':
          'http://api-pinakad.pintarkerja.com/profile.php?student_id=${widget.studentId}',
      'Kehadiran':
          'http://api-pinakad.pintarkerja.com/kehadiran.php?student_id=${widget.studentId}',
      'Penilaian':
          'http://api-pinakad.pintarkerja.com/mata_pelajaran.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
      'Pembayaran':
          'http://api-pinakad.pintarkerja.com/book.php?class_id=${widget.classId}&subject_id=${widget.subjectId}',
    };

    try {
      final responses = await Future.wait(
        urls.entries.map((entry) => http.get(Uri.parse(entry.value))),
      );

      // Pastikan indeks benar saat menggunakan responses
      setState(() {
        profileData = _parseData(responses[0].body);
        passwordData = _parseData(responses[1].body);
        emailData = _parseData(responses[2].body);
        kehadiranData = _parseData(responses[3].body);
        penilaianData = _parseData(responses[4].body);
        pembayaranData = _parseData(responses[5].body);

        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<dynamic> _parseData(String responseBody) {
    final Map<String, dynamic> decoded = json.decode(responseBody);
    return decoded['data'] ?? [];
  }

  Future<void> _showProfileData(String section) async {
    if (isLoading) {
      await fetchData(); // Fetch data if still loading
    }

    String content = 'No data available';
    List<dynamic> data;

    switch (section) {
      case 'Profile':
        data = profileData;
        break;
      case 'Password':
        data = passwordData;
        break;
      case 'Email':
        data = emailData;
        break;
      case 'Kehadiran':
        data = kehadiranData;
        break;
      case 'Penilaian':
        data = penilaianData;
        break;
      case 'Pembayaran':
        data = pembayaranData;
        break;
      default:
        data = [];
        break;
    }

    if (data.isNotEmpty) {
      switch (section) {
        case 'Password':
          final String oldPassword1 = data[0]['password2'] ?? 'No password';
          _showPasswordInputDialog(oldPassword1);
          break;
        case 'Email':
          final String email1 = data[0]['email'] ?? 'No Email';
          _showEmailInputDialog(email1);
          break;
        case 'Kehadiran':
          _showKehadiranDialog();
          break;
        case 'Penilaian':
          _showPenilaianDialog();
          break;
        default:
          _showModal(section, content);
          break;
      }
    } else {
      _showModal(section, 'No data available');
    }
  }

  Future<void> _fetchDetailData(String subjectId) async {
    // URL endpoint untuk detail data mata pelajaran
    final url =
        'http://api-pinakad.pintarkerja.com/mata_pelajaran_detail.php?student_id=${widget.studentId}&subject_id=$subjectId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          mataPelajaranDetail[subjectId] = _parseData(response.body);
        });
      } else {
        print('Failed to load mata pelajaran detail data');
      }
    } catch (e) {
      print('Error fetching mata pelajaran detail data: $e');
    }
  }

  void _showPasswordInputDialog(String oldPassword1) {
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display old password as text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Old Password: $oldPassword1',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // New Password input
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                final newPassword = newPasswordController.text;

                if (newPassword.isNotEmpty) {
                  _handlePasswordSubmission(oldPassword1, newPassword);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a new password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEmailInputDialog(String email1) {
    final newEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Email ?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display old password as text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Old email: $email1',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // New Password input
              TextField(
                controller: newEmailController,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  hintText: 'Enter your new email',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                final newEmail = newEmailController.text;

                if (newEmail.isNotEmpty) {
                  _handleEmailSubmission(email1, newEmail);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a new email')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showKehadiranDialog() {
    final List<Attendance> attendanceList = kehadiranData.map((item) {
      // Convert the timestamp to an integer
      final timestamp = int.parse(item['timestamp'].toString()) *
          1000; // Convert to milliseconds
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final status = item['status'] ?? 'No status';
      final details = status == 1 ? 'Hadir' : 'Absen';
      return Attendance(date, details);
    }).toList();

    final monthlyReports = groupAttendanceByMonth(attendanceList);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kehadiran Bulanan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: monthlyReports.length,
              itemBuilder: (context, index) {
                final report = monthlyReports[index];
                return ExpansionTile(
                  title: Text('Month: ${report.month}'),
                  children: report.attendances.map((attendance) {
                    return ListTile(
                      title: Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(attendance.date)}'),
                      subtitle: Text('Details: ${attendance.details}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPenilaianDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Penilaian'),
          content: DefaultTabController(
            length:
                penilaianData.length, // Dynamic number of tabs based on data
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true, // To handle many tabs
                  tabs: penilaianData.map((subject) {
                    return Tab(
                      text: subject['name'].toString(), // Ensure it's a String
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: 300, // Adjust height as needed
                  child: TabBarView(
                    children: penilaianData.map((subject) {
                      return FutureBuilder(
                        future: _fetchDetailData(subject['subject_id']
                            .toString()), // Ensure it's a String
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else {
                            return _buildMataPelajaranContent(
                                subject['subject_id']
                                    .toString()); // Ensure it's a String
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMataPelajaranContent(String subjectId) {
    // Get detail data for the selected subject
    List<dynamic> detailData = mataPelajaranDetail[subjectId] ?? [];

    if (detailData.isEmpty) {
      return Center(
          child: Text('No data available for subject ID: $subjectId.'));
    }

    return ListView.builder(
      itemCount: detailData.length,
      itemBuilder: (context, index) {
        final data = detailData[index];

        // Convert Unix timestamp to DateTime
        final int? timestamp = data['exam_date'] != null
            ? int.tryParse(data['exam_date'].toString())
            : null;
        final DateTime? date = timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
            : null;

        // Format the date
        final DateFormat dateFormat =
            DateFormat('yyyy-MM-dd'); // Customize the format as needed
        final String formattedDate =
            date != null ? dateFormat.format(date) : 'No date available';

        return ListTile(
          title: Text(data['title'] ?? 'No pelajaran'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nilai: ${data['obtained_mark'] ?? 'No pelajaran'}'),
              const SizedBox(height: 4), // Optional space between lines of text
              Text('Tanggal : $formattedDate'), // Display the formatted date
            ],
          ),
        );
      },
    );
  }

  List<MonthlyReport> groupAttendanceByMonth(List<Attendance> attendanceList) {
    final Map<String, List<Attendance>> groupedData = {};

    for (var attendance in attendanceList) {
      final month = DateFormat('yyyy-MM').format(attendance.date);

      if (!groupedData.containsKey(month)) {
        groupedData[month] = [];
      }
      groupedData[month]?.add(attendance);
    }

    return groupedData.entries.map((entry) {
      final month = entry.key;
      final attendances = entry.value;

      return MonthlyReport(month, attendances);
    }).toList();
  }

  void _handlePasswordSubmission(String oldPassword1, String newPassword) {
    // Hash old password and new password
    final oldPasswordHash = _generateSha1Hash(oldPassword1);
    final newPasswordHash = _generateSha1Hash(newPassword);

    // Print the hashed passwords (for debugging)
    print('Old Password Hash: $oldPasswordHash');
    print('New Password Hash: $newPasswordHash');
  }

  String _generateSha1Hash(String input) {
    final bytes = utf8.encode(input); // Convert the input string to bytes
    final digest = sha1.convert(bytes); // Compute the SHA-1 hash
    return digest.toString(); // Convert the hash to a string
  }

  void _handleEmailSubmission(String email1, String newEmail) {
    // Hash old password and new password
    final oldPasswordHash = email1;
    final newPasswordHash = newEmail;
  }

  void _showModal(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: Image.asset(
          'assets/images/logop.png',
          fit: BoxFit.contain,
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Profile Picture Container
            Container(
              width: 50,
              height: 50,
              decoration: const ShapeDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      "http://api-pinakad.pintarkerja.com/images/foto.png"),
                  fit: BoxFit.fill,
                ),
                shape: OvalBorder(
                  side: BorderSide(width: 3.62, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User Information
            Container(
              width: 330,
              height: 168,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: profileData.length,
                  itemBuilder: (context, index) {
                    final item = profileData[index];
                    final nama1 = item['first_name'] ?? 'No First Name';
                    final nama2 = item['last_name'] ?? 'No Last Name';
                    final email = item['email'] ?? 'No email';
                    final alamat = item['address'] ?? 'No Address';
                    final telpon = item['phone'] ?? 'No Phone';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name and Email
                        Text(
                          '$nama1 $nama2',
                          style: const TextStyle(
                            color: Color(0xFF4B4B4B),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Address: $alamat',
                          style: const TextStyle(
                            color: Color(0xFF4B4B4B),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: $telpon',
                          style: const TextStyle(
                            color: Color(0xFF4B4B4B),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Section Titles as Center-Aligned Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _showProfileData('Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _showProfileData('Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Password',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _showProfileData('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Email',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _showProfileData('Kehadiran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Kehadiran',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _showProfileData('Penilaian'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Penilaian',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _showProfileData('Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Pembayaran',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Decorative Containers
            Container(
              width: 330,
              height: 168,
              decoration: ShapeDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                      "http://api-pinakad.pintarkerja.com/images/infak.jpg"),
                  fit: BoxFit.fill,
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Small Containers
            // Add your additional small containers here if needed
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 31, 40, 174),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/bxs_home-alt-2.png'),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/bxs_book-alt.png'),
            ),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/entypo_video.png'),
            ),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/bell.png'),
            ),
            label: 'Notify',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/person.png'),
            ),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Widget page;

      switch (index) {
        case 0:
          page = DashboardPage(
            classId: widget.classId,
            sectionId: widget.sectionId,
            studentId: widget.studentId,
            subjectId: widget.subjectId,
            alamat: widget.alamat,
            status: widget.status,
            namalengkap: widget.namalengkap,
          );
          break;

        case 1:
          page = BookPage(
            classId: widget.classId,
            sectionId: widget.sectionId,
            studentId: widget.studentId,
            subjectId: widget.subjectId,
            alamat: widget.alamat,
            status: widget.status,
            namalengkap: widget.namalengkap,
          );
          break;
        case 2:
          page = VideoPage(
            classId: widget.classId,
            sectionId: widget.sectionId,
            studentId: widget.studentId,
            subjectId: widget.subjectId,
            alamat: widget.alamat,
            status: widget.status,
            namalengkap: widget.namalengkap,
          );
          break;
        case 3:
          page = NotifyPage(
            classId: widget.classId,
            sectionId: widget.sectionId,
            studentId: widget.studentId,
            subjectId: widget.subjectId,
            alamat: widget.alamat,
            status: widget.status,
            namalengkap: widget.namalengkap,
          );
          break;
        default:
          page = ProfilePage(
            classId: widget.classId,
            sectionId: widget.sectionId,
            studentId: widget.studentId,
            subjectId: widget.subjectId,
            alamat: widget.alamat,
            status: widget.status,
            namalengkap: widget.namalengkap,
          );
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    });
  }
}

class Attendance {
  final DateTime date;
  final String details;

  Attendance(this.date, this.details);
}

class MonthlyReport {
  final String month;
  final List<Attendance> attendances;

  MonthlyReport(this.month, this.attendances);
}
