import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailTugasPage extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;

  const DetailTugasPage({Key? key, required this.dataList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Tugas/PR',
          style: TextStyle(
            color: Colors.white, // Mengubah warna teks menjadi putih
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          final data = dataList[index];
          final String title = data['title'] ?? 'No Title';
          final String description = data['description'] ?? 'No Description';

          // Handling publish_date as a String
          String? publishDateString = data['publish_date'];
          DateTime? examDate;
          if (publishDateString != null) {
            try {
              // Assuming the date is in format 'yyyy-MM-dd HH:mm:ss'
              examDate =
                  DateFormat('yyyy-MM-dd HH:mm:ss').parse(publishDateString);
            } catch (e) {
              examDate = null; // Fallback if parsing fails
            }
          }
          final String formattedDate = examDate != null
              ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(examDate)
              : 'No Date';

          // Handle time_end which is a longtext field in your database
          final String timeEnd = data['date_end'] ?? 'No End Time';

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tugas ke-${index + 1}', // Penanda ulangan ke berapa
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tugas/PR: $title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tanggal Mulai: $formattedDate',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Waktu Selesai: - $timeEnd',
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
