import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../page/absen/absen_page.dart';
import '../page/dashboard/dashboard.dart';
import '../page/dashboard/dashboardguru.dart';
import '../page/dashboard/dashboardortu.dart';
import '../page/guru/absenguru.dart'; // Import GuruPage here
import '../page/orangtua/orangtua.dart';

class LoginControllerMurid extends GetxController {
  var username = ''.obs;
  var password = ''.obs;
  var loading = false.obs;

  void logmurid() async {
    loading.value = true;

    try {
      var url =
          'https://api-pinakad.pintarkerja.com/loginmurid.php'; // Correct URL
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
            _handleStudentLogin(data);
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

  void _handleStudentLogin(Map<String, dynamic> data) {
    var status = data['status'] as String?;
    if (status == 'success') {
      // Check for 'success' status from backend
      var allData = data['user'] as List<dynamic>? ?? [];
      if (allData.isNotEmpty) {
        var firstItem = allData[0] as Map<String, dynamic>;

        var classId = _parseInt(firstItem['class_id']);
        var sectionId = _parseInt(firstItem['section_id']);
        var studentId = _parseInt(firstItem['student_id']);
        var subjectId = _parseInt(firstItem['subject_id']);
        var alamat = _parseString(firstItem['address']);
        var status = _parseString(firstItem['status']);
        var namalengkap = _parseString(
            firstItem['first_name'] + ' ' + firstItem['last_name']);
        var latId = double.tryParse(firstItem['latitude'].toString()) ??
            0.0; // Parsing a double for 'latitude', defaulting to 0.0 if parsing fails
        var longId = double.tryParse(firstItem['longitude'].toString()) ??
            0.0; // Parsing a double for 'longitude', defaulting to 0.0 if parsing fails

        Get.offAll(() => DashboardPage(
              classId: classId,
              sectionId: sectionId,
              studentId: studentId,
              subjectId: subjectId,
              alamat: alamat,
              status: status,
              namalengkap: namalengkap,
            ));
        _successResult();
      } else {
        _showErrorSnackbar('Data tidak ditemukan');
      }
    } else {
      _showErrorSnackbar('Status tidak valid: $status');
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
