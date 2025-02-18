import 'package:pintar_akademik/page/quiz/quizmodel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'testpage.dart';

class QuizPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final int teacherId;
  final String matapelajaranId;
  final String alamat;
  final String status;

  const QuizPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.matapelajaranId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Datum> questionList = []; // Use List<Datum> instead of List<Quizmodel>

  final String url =
      "https://script.google.com/macros/s/AKfycbzwsSvNke0mJEtAOBHaD0uGFkSJyBI6j_nCG8BHbh1OSRB8VjsRsIBJdUle9k5jGyDJ/exec";

  Future<void> getAllData() async {
    try {
      var response = await http.get(Uri.parse(url));
      var data = json.decode(response.body);
      // Assuming the JSON structure is { "data": [ ... ] }
      var quizmodel = Quizmodel.fromJson(data);
      setState(() {
        questionList =
            quizmodel.data; // Extract the list of Datum from Quizmodel
      });
    } catch (err) {
      print('Error: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz : ${widget.matapelajaranId}'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await getAllData(); // Wait for data to be fetched
                  if (questionList.isNotEmpty) {
                    // Navigate to TesPage when the button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TesPage(
                          classId: widget.classId,
                          sectionId: widget.sectionId,
                          studentId: widget.studentId,
                          subjectId: widget.subjectId,
                          teacherId: widget.teacherId,
                          matapelajaranId: widget.matapelajaranId,
                          alamat: widget.alamat,
                          status: widget.status,
                          quizmodelList: questionList, // Pass the list of Datum
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Mulai Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
