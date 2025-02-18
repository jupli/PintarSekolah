import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrdetailPage extends StatefulWidget {
  final int teacher_id;
  final int subject_id;
  final String namaguru;
  final String classId;

  const PrdetailPage({
    Key? key,
    required this.teacher_id,
    required this.subject_id,
    required this.namaguru,
    required this.classId,
  }) : super(key: key);

  @override
  _PrdetailPageState createState() => _PrdetailPageState();
}

class _PrdetailPageState extends State<PrdetailPage>
    with SingleTickerProviderStateMixin {
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
          'http://api-pinakad.pintarkerja.com/get_class.php?teacher_id=${widget.teacher_id}&subject_id=${widget.subject_id}'));

      if (classIdsResponse.statusCode == 200) {
        final classIdsData = jsonDecode(classIdsResponse.body);
        print('Class IDs Response: ${classIdsData}');

        if (classIdsData['status'] == 'success') {
          setState(() {
            _classIds = List<String>.from(classIdsData['data']
                .map((item) => item['kelas_name'].toString()));
            // Save subject_ids for each class
            _subjectIds = List<int>.from(classIdsData['data']
                .map((item) => item['subject_id'])); // Save subject_ids here
            _tabController =
                TabController(length: _classIds.length, vsync: this)
                  ..addListener(_handleTabChange);
          });

          print('Class IDs: $_classIds');

          // Fetch data for each class
          for (int i = 0; i < _classIds.length; i++) {
            await _fetchPrForAllTabs(
                _classIds[i], _subjectIds[i]); // Pass subject_id
          }
        } else {
          _showError('Failed to load class IDs');
        }
      } else {
        _showError('Failed to load class IDs');
      }
    } catch (e) {
      _showError('Error fetching data: $e');
    }
  }

  void _handleTabChange() async {
    if (_tabController.indexIsChanging) {
      final classId = _classIds[_tabController.index];
      final subjectId =
          _subjectIds[_tabController.index]; // Dapatkan subjectId yang sesuai
      print('Switching to class: $classId'); // Log the switching class
      await _fetchPrForAllTabs(
          classId, subjectId); // Pass classId and subjectId
    }
  }

  Future<void> _fetchPrForAllTabs(String classId, int subjectId) async {
    setState(() {
      _isLoading = true; // Show loading while fetching
    });

    try {
      final PrData = await _fetchPr(
          widget.teacher_id, subjectId, classId); // Use the correct subject_id
      setState(() {
        _PrPerTab[classId] = PrData;
        _isLoading = false; // Set loading to false after fetching data
      });
      print('Fetched PrData for $classId: $PrData');
    } catch (e) {
      _showError('Error fetching Pr data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPr(
      int teacher_id, int subject_id, String classId) async {
    final url = Uri.parse(
      'http://api-pinakad.pintarkerja.com/pr.php?subject_id=$subject_id&class_name=$classId',
    );
    final response = await http.get(url);

    print('Pr API Response: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load Pr data');
      }
    } else {
      throw Exception('Failed to load Pr data');
    }
  }

  String formatDate(dynamic timestamp) {
    int millis = 0;
    if (timestamp is String) {
      millis = int.tryParse(timestamp) ?? 0; // Default to 0 if conversion fails
    } else if (timestamp is int) {
      millis = timestamp; // Use it directly if it's already an int
    }

    final date = DateTime.fromMillisecondsSinceEpoch(millis * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          bottom: _classIds.isNotEmpty
              ? TabBar(
                  controller: _tabController,
                  tabs: List.generate(
                    _classIds.length,
                    (index) => Tab(
                      child: Text(
                        'Class ${_classIds[index]}',
                        style: TextStyle(
                          color: _tabController.index == index
                              ? const Color.fromARGB(255, 243, 87, 15)
                              : const Color.fromARGB(255, 248, 246, 246),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : GestureDetector(
                onHorizontalDragUpdate: (details) {
                  // Tidak melakukan apa-apa saat menggulir horizontal
                },
                child: TabBarView(
                  controller: _tabController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Menonaktifkan scroll tab
                  children: _classIds.map((classId) {
                    return _buildTabContent(classId);
                  }).toList(),
                ),
              ));
  }

  Widget _buildTabContent(String classId) {
    final PrData = _PrPerTab[classId] ?? [];

    if (PrData.isEmpty) {
      return Center(child: Text('Tidak ada data untuk ditampilkan.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'TUGAS KELAS: $classId',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16.0,
                    columns: <DataColumn>[
                      DataColumn(label: _buildDataColumn('No')),
                      DataColumn(label: _buildDataColumn('Tugas')),
                      DataColumn(label: _buildDataColumn('Pelajaran')),
                      DataColumn(label: _buildDataColumn('Tanggal')),
                      DataColumn(label: _buildDataColumn('Pr')),
                    ],
                    rows: List.generate(
                      PrData.length,
                      (index) {
                        final Pr = PrData[index];
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(_buildDataCell((index + 1).toString())),
                            DataCell(_buildDataCell(Pr['title'] ?? '')),
                            DataCell(_buildDataCell(Pr['description']
                                .toString())), // Adjust as necessary
                            DataCell(
                                _buildDataCell(formatDate(Pr['publish_date']))),
                            DataCell(_buildDataCell(
                                Pr['homework_code']?.toString() ?? '')),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn(String text) {
    return Center(
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      padding: EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}
