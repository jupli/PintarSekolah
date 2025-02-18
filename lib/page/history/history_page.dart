import 'dart:math';
import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simulated data
    List<Map<String, dynamic>> data = [
      {
        'nama': 'John Doe',
        'alamat': '123 Main St',
        'keterangan': 'Hadir',
        'datetime': '2024-07-25 08:00:00',
      },
      {
        'nama': 'Jane Smith',
        'alamat': '456 Park Ave',
        'keterangan': 'Izin',
        'datetime': '2024-07-24 09:30:00',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Riwayat Absensi",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: data.isNotEmpty
          ? ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Data",
                            style:
                                TextStyle(fontSize: 18, color: Colors.black)),
                        content: const SizedBox(
                          height: 20,
                          child: Column(
                            children: [
                              Text("Yakin ingin menghapus data ini?",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black)),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Implementasi logika hapus data di sini
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Ya",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.pinkAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Tidak",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    margin: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.primaries[
                                  Random().nextInt(Colors.primaries.length)],
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(50)),
                            ),
                            child: Center(
                              child: Text(
                                data[index]['nama'][0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        "Nama",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        " : ",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        data[index]['nama'],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        "Alamat",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        " : ",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        data[index]['alamat'],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        "Keterangan",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        " : ",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        data[index]['keterangan'],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        "Waktu Absen",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        " : ",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        data[index]['datetime'],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                "Ups, tidak ada data!",
                style: TextStyle(fontSize: 20),
              ),
            ),
    );
  }
}
