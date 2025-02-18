import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NilaiPage extends StatefulWidget {
  final int teacher_id;
  final int subject_id;
  final String namaguru;

  const NilaiPage({
    Key? key,
    required this.teacher_id,
    required this.subject_id,
    required this.namaguru,
  }) : super(key: key);

  @override
  _NilaiPageState createState() => _NilaiPageState();
}

class _NilaiPageState extends State<NilaiPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController; // Nullable TabController
  List<String> _classIds = [];
  Map<String, Map<String, List<Map<String, dynamic>>>> _nilaiPerTab = {};
  bool _isLoading = true;
  bool _isAscending = true;
  String? _sortColumn;

  @override
  void initState() {
    super.initState();
    _fetchClassIdsAndData();
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Dispose if it's initialized
    super.dispose();
  }

  Future<void> _fetchClassIdsAndData() async {
    try {
      final classIdsResponse = await http.get(Uri.parse(
          'http://api-pinakad.pintarkerja.com/get_class.php?teacher_id=${widget.teacher_id}&subject_id=${widget.subject_id}'));

      if (classIdsResponse.statusCode == 200) {
        final classIdsData = jsonDecode(classIdsResponse.body);
        if (classIdsData['status'] == 'success') {
          setState(() {
            // Mengambil kelas_name dan menghindari duplikat
            _classIds = classIdsData['data']
                .map((item) => item['kelas_name'].toString())
                .toSet()
                .toList(); // Menggunakan Set untuk menghindari duplikat
            print("Class IDs: $_classIds"); // Log untuk debugging
          });

          if (_classIds.isNotEmpty) {
            // Inisialisasi TabController setelah _classIds diisi
            _tabController =
                TabController(length: _classIds.length, vsync: this);
            _tabController?.addListener(_handleTabChange);

            await _fetchNilaiForAllTabs(_classIds[0]);
            setState(() {
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false; // Set loading to false if no class IDs
            });
          }
        } else {
          throw Exception('Failed to load class IDs');
        }
      } else {
        throw Exception('Failed to load class IDs');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void _handleTabChange() async {
    if (_tabController?.indexIsChanging == true) {
      final classId = _classIds[_tabController!.index];
      await _fetchNilaiForAllTabs(classId);
      setState(() {});
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
      'http://api-pinakad.pintarkerja.com/get_nilai.php?teacher_id=$teacher_id&subject_id=$subject_id&class_name=$classId&jenis_nilai=$jenisNilai',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        List<Map<String, dynamic>> nilaiData =
            List<Map<String, dynamic>>.from(data['data']);
        return nilaiData
            .where((nilai) => nilai['ujian']?.contains(titleFilter) ?? false)
            .toList();
      } else {
        throw Exception('Failed to load nilai data');
      }
    } else {
      throw Exception('Failed to load nilai data');
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
        bottom: _classIds.isNotEmpty && _tabController != null
            ? TabBar(
                controller: _tabController,
                tabs: List.generate(
                  _classIds.length,
                  (index) => Tab(
                    child: Text(
                      'Class ${_classIds[index]}',
                      style: TextStyle(
                        color: _tabController!.index == index
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
          : TabBarView(
              controller: _tabController,
              children: _classIds.map((classId) {
                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: 'Nilai Ulangan'),
                          Tab(text: 'Nilai UTS'),
                          Tab(text: 'Nilai UAS'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTabContent(classId, 'nilai_ulangan'),
                            _buildTabContent(classId, 'nilai_uts'),
                            _buildTabContent(classId, 'nilai_uas'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(_buildDataCell((index + 1).toString())),
                            DataCell(_buildDataCell((nilai['firstname'] ?? '') +
                                ' ' +
                                (nilai['lastname'] ?? ''))),
                            DataCell(_buildDataCell(nilai['title'] ?? '')),
                            DataCell(_buildDataCell(
                                formatDate(nilai['tanggal'] ?? 0))),
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
}
