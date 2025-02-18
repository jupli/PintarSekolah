import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../page/absen/absen_page.dart';
import '../page/dashboard/dashboard.dart';
import '../page/dashboard/dashboardguru.dart';
import '../page/dashboard/dashboardortu.dart';
import '../page/guru/absenguru.dart'; // Import GuruPage here
import '../page/orangtua/orangtua.dart';

class LoginControllerOrtu extends GetxController {
  var username = ''.obs;
  var password = ''.obs;
  var loading = false.obs;
  var obscurePassword = true.obs;

  void loginortu() async {
    loading.value = true;

    try {
      var url =
          'https://api-pinakad.pintarkerja.com/loginortu.php'; // Correct URL
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': username.value,
          'password': password.value,
        }),
      );

      print('Response body: ${response.body}'); // Print the raw response

      if (response.statusCode == 200) {
        try {
          // Decode JSON response
          var data = jsonDecode(response.body) as Map<String, dynamic>;

          if (data['status'] == 'success') {
            _handleParentLogin(data);
          } else {
            _showErrorSnackbar('Login failed: ${data['message']}');
          }
        } catch (e) {
          print('Error decoding JSON: $e');
          _showErrorSnackbar('Failed to parse response. Please try again.');
        }
      } else {
        _showErrorSnackbar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorSnackbar('An error occurred during login. Please try again.');
    }

    loading.value = false;
  }

  void _handleParentLogin(Map<String, dynamic> data) {
    var status = data['status'] as String?; // Check login status
    if (status == 'success') {
      var allData = data['user'] as List<dynamic>? ??
          []; // Access 'user' instead of 'data'

      if (allData.isNotEmpty) {
        var firstItem = allData[0] as Map<String, dynamic>;

        // Parse user-related data
        var classId = _parseInt(firstItem['class_id']);
        var sectionId = _parseInt(firstItem['section_id']);
        var studentId = _parseInt(firstItem['student_id']);
        var subjectId = _parseInt(firstItem['subject_id']);
        var parentId = _parseInt(firstItem['enroll_id']);
        var teacherId = _parseInt(firstItem['teacher_id']);
        var namadepan = _parseString(firstItem['first_name']);
        var namabelakang = _parseString(firstItem['last_name']);
        var matapelajaranId = _parseString(firstItem['matapelajaran_id']);
        var alamat = _parseString(firstItem['address']);
        var status = _parseString(firstItem['status']);
        var latId = _parseDouble(firstItem['latitude']);
        var longId = _parseDouble(firstItem['longitude']);
        var namalengkap = _parseString(
            firstItem['first_name'] + ' ' + firstItem['last_name']);

        // Navigate to the DashboardOrtuPage with the parsed data
        Get.offAll(() => DashboardOrtuPage(
              classId: classId,
              sectionId: sectionId,
              studentId: studentId,
              parentId: parentId,
              subjectId: subjectId,
              alamat: alamat,
              status: status,
              namalengkap: namalengkap,
            ));
        _successResult();
      } else {
        _showErrorSnackbar('Data not found for the user.');
      }
    } else {
      _showErrorSnackbar('Invalid status: $status');
    }
  }

  int _parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _parseString(dynamic value) {
    return value?.toString() ?? '';
  }

  void _showErrorSnackbar(String message) {
    Get.rawSnackbar(message: message);
  }

  void _successResult() {
    // Handle successful login
    print('Login successful!');
  }

  void _errorResult() {
    // Handle failed login
    print('Login failed!');
  }
}
