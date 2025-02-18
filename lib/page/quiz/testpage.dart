import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:countdown_progress_indicator/countdown_progress_indicator.dart';
import 'package:pintar_akademik/page/quiz/quizmodel.dart';

import 'resultpage.dart';

class TesPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final int teacherId;
  final String matapelajaranId;
  final String alamat;
  final String status;
  final List<Datum> quizmodelList; // Change to List<Datum>

  const TesPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.matapelajaranId,
    required this.alamat,
    required this.status,
    required this.quizmodelList, // Accept the list of Datum
  }) : super(key: key);

  @override
  _TesPageState createState() => _TesPageState();
}

class _TesPageState extends State<TesPage> {
  final CountDownController _controller = CountDownController();
  int index = 0;
  int result = 0;

  void navigate(String optionChar) {
    setState(() {
      if (optionChar == widget.quizmodelList[index].answer) {
        result++;
      }
      index++;
      if (index == widget.quizmodelList.length) {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => ResultPage(
              result: result, // Pass the result to ResultPage
            ),
          ),
        )
            .then((value) {
          setState(() {
            // Handle any updates if needed
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 10, 109),
      appBar: AppBar(
        title: const Text('Tes Page'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: kToolbarHeight + 16,
              left: 16,
              child: Text(
                "${index + 1}/${widget.quizmodelList.length}",
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: kToolbarHeight + 56 + 16,
              left: MediaQuery.of(context).size.width / 2 - 75,
              child: SizedBox(
                height: 150,
                width: 150,
                child: CountDownProgressIndicator(
                  controller: _controller,
                  valueColor: const Color.fromARGB(255, 250, 146, 0),
                  backgroundColor: const Color.fromARGB(255, 249, 249, 249),
                  initialPosition: 0,
                  duration: 60,
                  timeFormatter: (seconds) {
                    return Duration(seconds: seconds)
                        .toString()
                        .split('.')[0]
                        .padLeft(8, '0');
                  },
                  timeTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                  onComplete: () => null,
                ),
              ),
            ),
            Positioned(
              top: kToolbarHeight + 56 + 16 + 200,
              left: 16,
              right: 16,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.quizmodelList[index].question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: kToolbarHeight + 56 + 16 + 200 + 80,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        navigate(widget.quizmodelList[index].optionA),
                    child: Text(widget.quizmodelList[index].optionA),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        navigate(widget.quizmodelList[index].optionB),
                    child: Text(widget.quizmodelList[index].optionB),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        navigate(widget.quizmodelList[index].optionC),
                    child: Text(widget.quizmodelList[index].optionC),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        navigate(widget.quizmodelList[index].optionD),
                    child: Text(widget.quizmodelList[index].optionD),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
