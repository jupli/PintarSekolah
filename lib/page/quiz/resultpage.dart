// Assume that ResultPage is another screen where the result will be shown
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultPage extends StatelessWidget {
  final int result;

  const ResultPage({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Page'),
      ),
      body: Center(
        child: Text(
          'Your result: $result',
          style: GoogleFonts.roboto(
            fontSize: 22,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
