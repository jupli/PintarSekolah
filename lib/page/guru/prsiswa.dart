import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'nilaidetailpage.dart';
import 'prsiswa_OLD.dart';

class PrPage extends StatefulWidget {
  final int teacher_id;
  final int subject_id;
  final String namaguru;
  final String classId;

  const PrPage({
    Key? key,
    required this.teacher_id,
    required this.subject_id,
    required this.namaguru,
    required this.classId,
  }) : super(key: key);

  @override
  _PrPageState createState() => _PrPageState();
}

class _PrPageState extends State<PrPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _classIds = [];
  List<int> _subjectIds = []; // Tambahkan ini untuk menyimpan subject_ids
  Map<String, List<Map<String, dynamic>>> _PrPerTab = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClassIdsAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassIdsAndData() async {
    try {
      final classIdsResponse = await http.get(Uri.parse(
          'http://api-pinakad.pintarkerja.com/get_class.php?teacher_id=${widget.teacher_id}&subject_id=${widget.subject_id}&class_name=${widget.classId}'));

      if (classIdsResponse.statusCode == 200) {
        final classIdsData = jsonDecode(classIdsResponse.body);
        if (classIdsData['status'] == 'success') {
          setState(() {
            _classIds = List<String>.from(classIdsData['data']
                .map((item) => item['kelas_name'].toString())
                .toSet()
                .toList());
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToNilai(String classId) {
    // Cetak data ke console
    print('Navigating to NilaiDetailPage with the following data:');
    print('Class ID: $classId');
    print('Teacher ID: ${widget.teacher_id}');
    print('Subject ID: ${widget.subject_id}');
    print('Nama Guru: ${widget.namaguru}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrdetailPage(
          classId: classId,
          teacher_id: widget.teacher_id,
          subject_id: widget.subject_id,
          namaguru: widget.namaguru,
        ),
      ),
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
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
              ),
              itemCount: _classIds.length,
              itemBuilder: (context, index) {
                final classId = _classIds[index];
                return GestureDetector(
                  onTap: () => _navigateToNilai(classId),
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        'Pekerjaan Rumah:\nClass $classId',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
