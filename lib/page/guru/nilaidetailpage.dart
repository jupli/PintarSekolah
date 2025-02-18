import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NilaiDetailPage extends StatefulWidget {
  final int teacher_id;
  final int subject_id;
  final String namaguru;
  final String classId;

  const NilaiDetailPage({
    Key? key,
    required this.teacher_id,
    required this.subject_id,
    required this.namaguru,
    required this.classId,
  }) : super(key: key);

  @override
  _NilaiDetailPageState createState() => _NilaiDetailPageState();
}

class _NilaiDetailPageState extends State<NilaiDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _classIds = [];
  Map<String, Map<String, List<Map<String, dynamic>>>> _nilaiPerTab = {};
  bool _isLoading = true;
  bool _isAscending = true;
  String? _sortColumn;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Memperbarui tampilan saat tab berubah
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await _fetchNilaiForAllTabs(widget.classId);
      setState(() {
        _classIds.add(widget.classId);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNilaiForAllTabs(String classId) async {
    final nilaiUlangan = await _fetchNilai(widget.teacher_id, widget.subject_id,
        classId, 'nilai_ulangan', 'Ulangan Harian');
    final nilaiUTS = await _fetchNilai(widget.teacher_id, widget.subject_id,
        classId, 'nilai_uts', 'Ujian Tengah Semester');
    final nilaiUAS = await _fetchNilai(widget.teacher_id, widget.subject_id,
        classId, 'nilai_uas', 'Ujian Akhir Semester');

    _nilaiPerTab[classId] = {
      'nilai_ulangan': nilaiUlangan,
      'nilai_uts': nilaiUTS,
      'nilai_uas': nilaiUAS,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchNilai(int teacher_id, int subject_id,
      String classId, String jenisNilai, String titleFilter) async {
    final url = Uri.parse(
        'http://api-pinakad.pintarkerja.com/get_nilai.php?teacher_id=$teacher_id&subject_id=$subject_id&class_name=$classId&jenis_nilai=$jenisNilai');
    //'http://api-pinakad.pintarkerja.com/get_nilai.php?teacher_id=6&class_name=10-IPS-2');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print('Response body: ${response.body}'); // Debugging respons
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        List<Map<String, dynamic>> nilaiData =
            List<Map<String, dynamic>>.from(data['data']);
        return nilaiData
            .where((nilai) => nilai['ujian']?.contains(titleFilter) ?? false)
            .toList();
      } else {
        throw Exception('Failed to load nilai data: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load nilai data: ${response.reasonPhrase}');
    }
  }

  void _sortData(String column) {
    setState(() {
      _isAscending = (_sortColumn == column) ? !_isAscending : true;
      _sortColumn = column;

      for (var classId in _classIds) {
        _nilaiPerTab[classId]?.forEach((key, nilaiList) {
          nilaiList.sort((a, b) {
            int comparison;
            switch (column) {
              case 'Nama':
                comparison =
                    (a['firstname'] ?? '').compareTo(b['firstname'] ?? '');
                break;
              case 'Pelajaran':
                comparison = (a['title'] ?? '').compareTo(b['title'] ?? '');
                break;
              case 'Tanggal':
                comparison = (a['tanggal'] ?? 0).compareTo(b['tanggal'] ?? 0);
                break;
              case 'Nilai':
                comparison = (num.tryParse(a['nilai']?.toString() ?? '0') ?? 0)
                    .compareTo(
                        num.tryParse(b['nilai']?.toString() ?? '0') ?? 0);
                break;
              default:
                comparison = 0;
            }
            return _isAscending ? comparison : -comparison;
          });
        });
      }
    });
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _buildTab('Nilai Ulangan', 0),
            _buildTab('Nilai UTS', 1),
            _buildTab('Nilai UAS', 2),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(widget.classId, 'nilai_ulangan'),
                    _buildTabContent(widget.classId, 'nilai_uts'),
                    _buildTabContent(widget.classId, 'nilai_uas'),
                  ],
                ),
    );
  }

  Widget _buildTab(String text, int index) {
    return Tab(
      child: Text(
        text,
        style: TextStyle(
          fontWeight: _tabController.index == index
              ? FontWeight.bold
              : FontWeight.normal,
          color: _tabController.index == index
              ? Colors.orange
              : const Color.fromARGB(255, 249, 249, 249),
        ),
      ),
    );
  }

  Widget _buildTabContent(String classId, String nilaiKey) {
    final nilaiData = _nilaiPerTab[classId]?[nilaiKey] ?? [];

    if (nilaiData.isEmpty) {
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
                    'NILAI ${nilaiKey.replaceAll('nilai_', '').toUpperCase()} KELAS :  $classId',
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
                      DataColumn(
                        label: _buildDataColumn('Nama'),
                        onSort: (columnIndex, _) => _sortData('Nama'),
                      ),
                      DataColumn(
                        label: _buildDataColumn('Pelajaran'),
                        onSort: (columnIndex, _) => _sortData('Pelajaran'),
                      ),
                      DataColumn(
                        label: _buildDataColumn('Tanggal'),
                        onSort: (columnIndex, _) => _sortData('Tanggal'),
                      ),
                      DataColumn(
                        label: _buildDataColumn('Nilai'),
                        onSort: (columnIndex, _) => _sortData('Nilai'),
                      ),
                      DataColumn(
                        label: _buildDataColumn('namakelas'),
                        onSort: (columnIndex, _) => _sortData('namakelas'),
                      ),
                    ],
                    rows: List.generate(
                      nilaiData.length,
                      (index) {
                        final nilai = nilaiData[index];
                        // Parse 'tanggal' as an integer
                        int timestamp = (nilai['tanggal'] != null)
                            ? int.parse(nilai['tanggal'].toString())
                            : 0;

                        return DataRow(
                          cells: <DataCell>[
                            DataCell(_buildDataCell((index + 1).toString())),
                            DataCell(_buildDataCell((nilai['firstname'] ?? '') +
                                ' ' +
                                (nilai['lastname'] ?? ''))),
                            DataCell(_buildDataCell(nilai['title'] ?? '')),
                            DataCell(_buildDataCell(formatDate(timestamp))),
                            DataCell(_buildDataCell(
                                nilai['nilai']?.toString() ?? '')),
                            DataCell(_buildDataCell(
                                nilai['namakelas']?.toString() ?? '')),
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

  String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildDataColumn(String text) {
    return GestureDetector(
      onTap: () {
        if (text == 'Nama') {
          _sortData('Nama');
        } else if (text == 'Pelajaran') {
          _sortData('Pelajaran');
        } else if (text == 'Tanggal') {
          _sortData('Tanggal');
        } else if (text == 'Nilai') {
          _sortData('Nilai');
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_sortColumn == text)
            Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      padding: EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(text),
    );
  }

  @override
  void dispose() {
    _tabController.dispose(); // Pastikan untuk membuang TabController
    super.dispose();
  }
}
