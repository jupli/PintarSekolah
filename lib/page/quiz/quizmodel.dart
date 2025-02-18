// To parse this JSON data, do
//
//     final quizmodel = quizmodelFromJson(jsonString);

import 'dart:convert';

Quizmodel quizmodelFromJson(String str) => Quizmodel.fromJson(json.decode(str));

String quizmodelToJson(Quizmodel data) => json.encode(data.toJson());

class Quizmodel {
  List<Datum> data;

  Quizmodel({
    required this.data,
  });

  factory Quizmodel.fromJson(Map<String, dynamic> json) => Quizmodel(
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class Datum {
  int id;
  String question;
  String optionA;
  String optionB;
  String optionC;
  String optionD;
  String answer;
  String correctAnswer;

  Datum({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.answer,
    required this.correctAnswer,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["Id"] ?? 0,
        question: json["Question"] ?? '',
        optionA: json["option_a"] ?? '',
        optionB: json["option_b"] ?? '',
        optionC: json["option_c"] ?? '',
        optionD: json["option_d"] ?? '',
        answer: json["answer"] ?? '',
        correctAnswer: json["correct answer"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "Question": question,
        "option_a": optionA,
        "option_b": optionB,
        "option_c": optionC,
        "option_d": optionD,
        "answer": answer,
        "correct answer": correctAnswer,
      };
}
