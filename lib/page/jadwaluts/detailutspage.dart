import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailUtsPage extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;

  const DetailUtsPage({Key? key, required this.dataList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail UT & UAS',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: dataList.isEmpty
          ? Center(child: Text('Tidak ada data'))
          : ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                final data = dataList[index];

                // Log the entire data map for debugging
                print('Data Map: $data');

                final String title = data['title'] ?? 'No Title';
                final String description =
                    data['description'] ?? 'No Description';

                // Cek dan parsing tanggal ujian
                final examDateValue =
                    int.tryParse(data['exam_date'].toString());
                final DateTime examDate = examDateValue != null
                    ? DateTime.fromMillisecondsSinceEpoch(examDateValue * 1000)
                    : DateTime.now();

                final String formattedDate =
                    DateFormat('EEEE, dd MMMM yyyy', 'id').format(examDate);

                // Directly assign time as strings
                String timeStartStr = data['time_start'] ?? 'No Start Time';
                String timeEndStr = data['time_end'] ?? 'No End Time';

                print('Time Start: $timeStartStr'); // Debug log
                print('Time End: $timeEndStr'); // Debug log

// Check if the time strings are in the expected format
                final timeStart = _parseTime(timeStartStr);
                final timeEnd = _parseTime(timeEndStr);

                final String formattedTimeStart = timeStart != null
                    ? DateFormat('HH:mm').format(timeStart)
                    : 'Format Error: $timeStartStr'; // More informative message
                final String formattedTimeEnd = timeEnd != null
                    ? DateFormat('HH:mm').format(timeEnd)
                    : 'Format Error: $timeEndStr'; // More informative message

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ujian ke-${index + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mata Ujian : $title',
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
                          'Waktu: $formattedTimeStart - $formattedTimeEnd',
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  DateTime? _parseTime(String timeStr) {
    try {
      // Expecting time in the format HH:mm:ss
      return DateFormat('HH:mm:ss').parse(timeStr);
    } catch (e) {
      print('Error parsing time: $e');
      return null; // Return null if parsing fails
    }
  }
}
