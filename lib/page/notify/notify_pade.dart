import 'dart:convert';
import 'package:pintar_akademik/page/book/bookpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Other imports
import '../dashboard/dashboard.dart';
import '../mapel/mapel.dart';
import '../notify/notify_pade.dart';
import '../profile/profile_page.dart';
import '../video/video_page.dart';

class NotifyPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const NotifyPage(
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
  _NotifyPageState createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> {
  List<dynamic> notifyData = [];
  bool isLoading = true;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final String url =
        'http://api-pinakad.pintarkerja.com/notify.php?class_id=${widget.classId}&subject_id=${widget.subjectId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          notifyData = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        print('Failed to load data');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logop.png',
          fit: BoxFit.contain,
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
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
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Notifikasi Penting untuk kamu :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: screenWidth,
                    height: 166,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/notify.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Notifikasi Kelas:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: notifyData.length,
                      itemBuilder: (context, index) {
                        final item = notifyData[index];
                        final idn = item['date']?.toString() ?? 'No Id';
                        final name = item['notify'] ?? 'No Subject';

                        return GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('No action assigned to this item'),
                              ),
                            );
                          },
                          child: Container(
                            width: screenWidth * 0.9,
                            height: 82,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 83,
                                  top: 0,
                                  child: Container(
                                    width: screenWidth * 0.9 - 83,
                                    height: 82,
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      shadows: const [
                                        BoxShadow(
                                          color: Color(0x0C000000),
                                          blurRadius: 20,
                                          offset: Offset(0, 0),
                                          spreadRadius: 0,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 90,
                                  top: 40,
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      height: 0.21,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  left: 131,
                                  top: 60,
                                  child: Text(
                                    'Preview',
                                    style: TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      height: 0.21,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  top: 1,
                                  child: Container(
                                    width: 79,
                                    height: 80,
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      shadows: const [
                                        BoxShadow(
                                          color: Color(0x0C000000),
                                          blurRadius: 20,
                                          offset: Offset(0, 0),
                                          spreadRadius: 0,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 2,
                                  top: 26,
                                  child: Text(
                                    idn,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF4B4B4B),
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      height: 0.30,
                                      letterSpacing: -0.20,
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
          // BottomNavigationBarItem(
          //   icon: ImageIcon(
          //     AssetImage('assets/images/mapel3.png'),
          //   ),
          //   label: 'Mapel',
          // ),
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
        // case 1:
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => MapelPage(
        //         classId: widget.classId,
        //         sectionId: widget.sectionId,
        //         studentId: widget.studentId,
        //         subjectId: widget.subjectId,
        //         alamat: widget.alamat,
        //         status: widget.status,
        //       ),
        //     ),
        //   );
        //   break;
        case 1:
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
        case 2:
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
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NotifyPage(
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
                builder: (context) => ProfilePage(
                      classId: widget.classId,
                      sectionId: widget.sectionId,
                      studentId: widget.studentId,
                      subjectId: widget.subjectId,
                      alamat: widget.alamat,
                      status: widget.status,
                      namalengkap: widget.namalengkap,
                    )),
          );
          break;
        default:
          break;
      }
    });
  }
}
