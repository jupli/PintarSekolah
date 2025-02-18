import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../page/absen/absen_page.dart';
import '../page/dashboard/dashboard.dart';
import '../page/dashboard/dashboardguru.dart';
import '../page/dashboard/dashboardortu.dart';
import '../page/guru/absenguru.dart'; // Import GuruPage here
import '../page/orangtua/orangtua.dart';

class LoginControllerGuru extends GetxController {
  RxString username = ''.obs;
  RxString password = ''.obs;
  RxBool obscurePassword = true.obs;
  RxBool loading = false.obs;

  void loguru() async {
    loading.value = true;

    try {
      var url =
          'https://api-pinakad.pintarkerja.com/loginguru.php'; // No need to put username/password in URL
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
            _handleTeacherLogin(data);
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

  void _handleTeacherLogin(Map<String, dynamic> data) {
    // Parse the 'user' field as a list of maps
    var users = data['user'] as List<dynamic>?;

    print('Received teacher login response: $data');

    if (users != null && users.isNotEmpty) {
      // Process each user object in the list
      for (var user in users) {
        var teacherData = user as Map<String, dynamic>;
        var noidguru = _parseInt(teacherData['teacher_id']);
        var mengajar = _parseInt(teacherData['subject_id']);
        var namaguru = _parseString(teacherData['first_name']) +
            ' ' +
            _parseString(teacherData['last_name']);

        print(
            'Parsed teacher data: noidguru=$noidguru, mengajar=$mengajar, namaguru=$namaguru');

        if (noidguru != 0 && mengajar != 0 && namaguru.isNotEmpty) {
          // Navigate to the teacher dashboard page
          Get.offAll(() => DashboardGuruPage(
                noidguru: noidguru,
                mengajar: mengajar,
                namaguru: namaguru,
              ));
          _successResult();
          return; // Exit after handling the first valid user
        }
      }
      // If no valid user found
      _showErrorSnackbar('Data tidak ditemukan untuk guru');
    } else {
      _showErrorSnackbar('Data tidak ditemukan untuk guru');
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
