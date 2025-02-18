import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../page/dashboard/dashboard.dart';
import '../page/orangtua/orangtua.dart'; // Replace with the correct import

class LoginController extends GetxController {
  var username = ''.obs;
  var password = ''.obs;
  var loading = false.obs; // Use .obs to make loading reactive

  void login() async {
    loading.value = true; // Set loading state to true
    update(); // Update UI to show loading indicator

    try {
      var url =
          //'http://192.168.18.116/databackend/login.php'; // Adjust with your IP or localhost
          'http://192.168.100.141/databackend/login.php';
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': username.value,
          'password': password.value,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == 'successp') {
          // Password found in enroll table
          var allData =
              data['data'] as List<dynamic>?; // Safely cast to List<dynamic>
          if (allData != null && allData.isNotEmpty) {
            var firstItem = allData[0] as Map<String, dynamic>;

            // Extract and convert IDs
            var classId =
                int.tryParse(firstItem['class_id']?.toString() ?? '0') ?? 0;
            var sectionId =
                int.tryParse(firstItem['section_id']?.toString() ?? '0') ?? 0;
            var studentId =
                int.tryParse(firstItem['student_id']?.toString() ?? '0') ?? 0;
            var subjectId =
                int.tryParse(firstItem['subject_id']?.toString() ?? '0') ?? 0;
            var teacherId =
                int.tryParse(firstItem['teacher_id']?.toString() ?? '0') ??
                    0; // Example
            var namadepan = firstItem['first_name']?.toString() ?? '';
            var namabelakang = firstItem['last_name']?.toString() ?? '';
            var matapelajaranId =
                firstItem['matapelajaran_id']?.toString() ?? ''; // Example
            var alamat = firstItem['alamat']?.toString() ?? ''; // Example
            var status = firstItem['status']?.toString() ?? ''; // Example
            var latId =
                double.tryParse(firstItem['latitude']?.toString() ?? '0.0') ??
                    0.0; // Use double for latitude
            var longId =
                double.tryParse(firstItem['longitude']?.toString() ?? '0.0') ??
                    0.0; // Use double for longitude
            var namalengkap =
                firstItem['first_name'] + ' ' + firstItem['last_name'];

            // Navigate to the OrtuPage and pass parameters
            Get.offAll(() => OrtuPage(
                  classId: classId,
                  sectionId: sectionId,
                  studentId: studentId,
                  subjectId: subjectId,
                  teacherId: teacherId,
                  matapelajaranId: matapelajaranId,
                  namadepan: namadepan,
                  namabelakang: namabelakang,
                  alamat: alamat,
                  status: status,
                  latId: latId,
                  longId: longId,
                  namalengkap: namalengkap,
                ));

            successResult();
          } else {
            Get.rawSnackbar(message: 'Data not found');
          }
        } else if (data['status'] == 'success') {
          // Login successful in parent table
          var user = data['user'] as Map<String, dynamic>;
          var allData =
              data['data'] as List<dynamic>?; // Safely cast to List<dynamic>
          if (allData != null && allData.isNotEmpty) {
            var firstItem = allData[0] as Map<String, dynamic>;

            // Extract and convert IDs
            var classId =
                int.tryParse(firstItem['class_id']?.toString() ?? '0') ?? 0;
            var sectionId =
                int.tryParse(firstItem['section_id']?.toString() ?? '0') ?? 0;
            var studentId =
                int.tryParse(firstItem['student_id']?.toString() ?? '0') ?? 0;
            var subjectId =
                int.tryParse(firstItem['subject_id']?.toString() ?? '0') ?? 0;
            var alamat = firstItem['alamat']?.toString() ?? ''; // Example
            var status = firstItem['status']?.toString() ?? ''; // Example
            var namalengkap =
                firstItem['first_name'] + ' ' + firstItem['last_name'];

            // Debug: Log extracted values

            // Navigate to the AbsenPage and pass parameters
            Get.offAll(() => DashboardPage(
                  classId: classId,
                  sectionId: sectionId,
                  studentId: studentId,
                  subjectId: subjectId,
                  alamat: alamat,
                  status: status,
                  namalengkap: namalengkap,
                ));

            successResult();
          } else {
            Get.rawSnackbar(message: 'Data not found');
          }
        } else {
          // Login failed
          errorResult();
          Get.rawSnackbar(message: 'Email atau password salah');
        }
      } else {
        Get.rawSnackbar(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      // HTTP request error
      print('Error: $e');
      errorResult();
      Get.rawSnackbar(
          message: 'Terjadi Kesalahan Saat Login. Silahkan Coba Lagi');
    }

    loading.value = false; // Set loading state to false
    update(); // Update UI to hide loading indicator
  }

  void checkSelectedSchool() {
    // Implement logic to check selected school if needed
  }

  void successResult() {
    // Handle successful login
  }

  void errorResult() {
    // Handle failed login
  }
}
