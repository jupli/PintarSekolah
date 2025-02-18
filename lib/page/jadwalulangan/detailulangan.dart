import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;

  const DetailPage({Key? key, required this.dataList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Menggunakan Set untuk menyimpan ID unik
    final Set<int> uniqueIds = {};

    // Mengfilter dataList untuk menghindari duplikasi
    final List<Map<String, dynamic>> filteredDataList = dataList.where((data) {
      final int id = data['id']; // Pastikan Anda memiliki ID
      if (uniqueIds.contains(id)) {
        return false; // Jika ID sudah ada, jangan tambahkan
      } else {
        uniqueIds.add(id); // Tambahkan ID ke Set
        return true; // Tambahkan data ke filteredDataList
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Ulangan',
          style: TextStyle(
            color: Colors.white, // Mengubah warna teks menjadi putih
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: filteredDataList.length,
        itemBuilder: (context, index) {
          final data = filteredDataList[index];

          final String title = data['title'] ?? 'No Title';
          final String description = data['description'] ?? 'No Description';

          // Safely parsing dates from the string format
          final DateTime examDate =
              DateTime.parse(data['start'] ?? DateTime.now().toString());

          // Using locale 'id' for formatting the date in Indonesian
          final String formattedDate =
              DateFormat('EEEE, dd MMMM yyyy', 'id').format(examDate);

          // Parse start and end times directly from the string
          final String timeStart = data['start'] ?? 'No Start Time';
          final String timeEnd = data['end'] ?? 'No End Time';
          final String address = data['address'] ?? 'No Address';
          final String status = data['status'] ?? 'No Status';

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ulangan ke-${index + 1}', // Penanda ulangan ke berapa
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tanggal: $formattedDate',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Waktu: $timeStart - $timeEnd',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Deskripsi:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    thickness: 2,
                    color: Colors.blue,
                  ), // Garis pemisah
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
