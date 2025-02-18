import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AbsenDetailPage extends StatefulWidget {
  final int teacher_id;
  final int subject_id;
  final String namaguru;
  final String classId;

  const AbsenDetailPage({
    Key? key,
    required this.teacher_id,
    required this.subject_id,
    required this.namaguru,
    required this.classId,
  }) : super(key: key);

  @override
  _AbsenDetailPageState createState() => _AbsenDetailPageState();
}

class _AbsenDetailPageState extends State<AbsenDetailPage>
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
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
    final nilaiData = await _fetchNilai(classId);

    // Pisahkan data ke dalam dua kategori
    final yanghadir = nilaiData.where((nilai) => nilai['status'] == 1).toList();
    final yangabsen = nilaiData.where((nilai) => nilai['status'] != 1).toList();

    // Simpan hasil ke dalam _nilaiPerTab
    _nilaiPerTab[classId] = {
      'nilai_ulangan': yanghadir,
      'nilai_uts': yangabsen,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchNilai(String classId) async {
    final url = Uri.parse(
        'http://api-pinakad.pintarkerja.com/get_absensidua.php?class_name=$classId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        List<Map<String, dynamic>> nilaiData =
            List<Map<String, dynamic>>.from(data['data']);

        // Debugging: Lihat data sebelum filtering
        print('Data before filtering: $nilaiData');

        return nilaiData; // Kembalikan semua data untuk pemisahan
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
                    (a['first_name'] ?? '').compareTo(b['first_name'] ?? '');
                break;
              case 'Sex':
                comparison = (a['sex'] ?? '').compareTo(b['sex'] ?? '');
                break;
              case 'Tanggal':
                comparison =
                    (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0);
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
            _buildTab('Murid Hadir', 0),
            _buildTab('Murid Absen', 1),
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
                    _buildTabContent(
                        widget.classId, 'nilai_ulangan'), // Murid Hadir
                    _buildTabContent(
                        widget.classId, 'nilai_uts'), // Murid Absen
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

    print('Nilai Data: $nilaiData');

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
                    'ABSENSI KELAS :  $classId',
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
                        label: _buildDataColumn('Sex'),
                        onSort: (columnIndex, _) => _sortData('Sex'),
                      ),
                      DataColumn(
                        label: _buildDataColumn('Tanggal'),
                        onSort: (columnIndex, _) => _sortData('Tanggal'),
                      ),
                    ],
                    rows: List.generate(
                      nilaiData.length,
                      (index) {
                        final nilai = nilaiData[index];
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(_buildDataCell((index + 1).toString())),
                            DataCell(_buildDataCell(
                                (nilai['first_name'] ?? '') +
                                    ' ' +
                                    (nilai['last_name'] ?? ''))),
                            DataCell(_buildDataCell(nilai['sex'] ?? '')),
                            DataCell(_buildDataCell(
                                formatDate(int.parse(nilai['timestamp'])))),
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
    _tabController.dispose();
    super.dispose();
  }
}
