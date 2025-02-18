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

class _PrdetailPageState extends State<PrdetailPage> {
  List<Map<String, dynamic>> _prData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prData =
          await _fetchPr(widget.teacher_id, widget.subject_id, widget.classId);
      print('Fetched PR Data: $prData');

      setState(() {
        _isLoading = false;
        _prData = prData; // Simpan data langsung ke variabel
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to fetch data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPr(
      int teacher_id, int subject_id, String classId) async {
    final url = Uri.parse(
        'http://api-pinakad.pintarkerja.com/pr.php?subject_id=$subject_id&class_name=$classId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load PR data');
      }
    } else {
      throw Exception('Failed to load PR data');
    }
  }

  String formatDate(String timestamp) {
    DateTime date = DateTime.parse(timestamp); // Ubah menjadi DateTime
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_prData.isEmpty) {
      return Center(child: Text('Tidak ada data untuk ditampilkan.'));
    }

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal, // Membuat tabel dapat digeser secara horizontal
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DataTable(
          columns: [
            DataColumn(label: _buildDataColumn('No')),
            DataColumn(label: _buildDataColumn('Tugas')),
            DataColumn(label: _buildDataColumn('Pelajaran')),
            DataColumn(label: _buildDataColumn('Tanggal Mulai')),
            DataColumn(label: _buildDataColumn('Tanggal Selesai')),
          ],
          rows: List.generate(_prData.length, (index) {
            final pr = _prData[index];
            return DataRow(cells: [
              DataCell(_buildDataCell((index + 1).toString())),
              DataCell(_buildDataCell(pr['title'] ?? '')),
              DataCell(_buildDataCell(pr['description']?.toString() ?? '')),
              DataCell(_buildDataCell(formatDate(pr['publish_date'] ?? ''))),
              DataCell(_buildDataCell(pr['date_end']?.toString() ?? '')),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildDataColumn(String text) {
    return Center(
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)));
  }

  Widget _buildDataCell(String text) {
    return Container(
        padding: EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Text(text));
  }
}
