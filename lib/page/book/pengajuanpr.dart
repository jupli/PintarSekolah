import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker untuk memilih gambar
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';

class CustomPrPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String homework_code;

  const CustomPrPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
    required this.homework_code,
  }) : super(key: key);

  @override
  _CustomPageprState createState() => _CustomPageprState();
}

class _CustomPageprState extends State<CustomPrPage> {
  DateTime? _startDate;
  String? _selectedFile; // Untuk menyimpan path atau nama file yang diupload
  String? _selectedImage; // Untuk menyimpan path gambar yang dipilih
  String _fileType =
      'file'; // Menyimpan jenis file yang dipilih (data atau gambar)

  // Fungsi untuk menampilkan DatePicker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate =
        isStartDate ? DateTime.now() : _startDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        }
      });
    }
  }

  // File selection function (Camera, Gallery, or File Picker)
  // Future<void> _pickFileWithPermission(BuildContext context) async {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Container(
  //         height: 200,
  //         child: Column(
  //           children: [
  //             ListTile(
  //               leading: Icon(Icons.camera_alt),
  //               title: Text("Ambil Foto (Camera)"),
  //               onTap: () async {
  //                 final picker = ImagePicker();
  //                 final pickedFile = await picker.pickImage(
  //                   source: ImageSource.camera, // Capture image via camera
  //                 );
  //                 if (pickedFile != null) {
  //                   setState(() {
  //                     _selectedImage = pickedFile.path; // Save image path
  //                     _selectedFile = null; // Reset file if image is selected
  //                   });
  //                 }
  //                 Navigator.pop(context); // Close bottom sheet
  //               },
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.photo),
  //               title: Text("Pilih dari Galeri"),
  //               onTap: () async {
  //                 final picker = ImagePicker();
  //                 final pickedFile = await picker.pickImage(
  //                   source: ImageSource.gallery, // Choose image from gallery
  //                 );
  //                 if (pickedFile != null) {
  //                   setState(() {
  //                     _selectedImage = pickedFile.path; // Save image path
  //                     _selectedFile = null; // Reset file if image is selected
  //                   });
  //                 }
  //                 Navigator.pop(context); // Close bottom sheet
  //               },
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.attach_file),
  //               title: Text("Pilih File"),
  //               onTap: () async {
  //                 FilePickerResult? result =
  //                     await FilePicker.platform.pickFiles();
  //                 if (result != null) {
  //                   File file = File(result.files.single.path!);
  //                   if (await file.exists()) {
  //                     setState(() {
  //                       _selectedFile = file.path;
  //                       _selectedImage = null; // Reset if a file is selected
  //                     });
  //                   }
  //                 }
  //                 Navigator.pop(context); // Close bottom sheet
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> _pickFileWithPermission(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Ambil Foto (Camera)"),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (pickedFile != null) {
                    // Compress image before uploading
                    File originalFile = File(pickedFile.path);
                    var result = await FlutterImageCompress.compressWithFile(
                      originalFile.path,
                      minWidth: 800,
                      minHeight: 600,
                      quality: 80, // Set the quality as per your need
                      rotate: 0,
                    );

                    // Save compressed image to a new file
                    File compressedFile = File(pickedFile.path)
                      ..writeAsBytesSync(result!);

                    int fileSize = await compressedFile.length();
                    if (fileSize > 5 * 1024 * 1024) {
                      // 5MB
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("File size should not exceed 5MB.")),
                      );
                      return;
                    }

                    setState(() {
                      _selectedImage =
                          compressedFile.path; // Save compressed image path
                      _selectedFile = null; // Reset file if image is selected
                    });
                  }
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Pilih dari Galeri"),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery, // Choose image from gallery
                  );
                  if (pickedFile != null) {
                    // Check file size
                    File file = File(pickedFile.path);
                    int fileSize = await file.length();
                    if (fileSize > 5 * 1024 * 1024) {
                      // 5MB
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("File size should not exceed 5MB.")),
                      );
                      return; // Exit the method without setting the file
                    }

                    setState(() {
                      _selectedImage = pickedFile.path; // Save image path
                      _selectedFile = null; // Reset file if image is selected
                    });
                  }
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file),
                title: Text("Pilih File"),
                onTap: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null) {
                    File file = File(result.files.single.path!);
                    int fileSize = await file.length();
                    if (fileSize > 5 * 1024 * 1024) {
                      // 5MB
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("File size should not exceed 5MB.")),
                      );
                      return; // Exit the method without setting the file
                    }

                    setState(() {
                      _selectedFile = file.path;
                      _selectedImage = null; // Reset if a file is selected
                    });
                  }
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Submit form logic
  Future<void> submitForm(BuildContext context) async {
    // Format dates inside submitForm
    String formattedStartDate = _startDate != null
        ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}"
        : "";

    // API endpoint
    var uri = Uri.parse("https://api-pinakad.pintarkerja.com/pengajuan2.php");

    // Create multipart request
    var request = http.MultipartRequest('POST', uri);

    // Adding form fields
    request.fields['student_id'] = widget.studentId.toString();
    request.fields['class_id'] = widget.classId.toString();
    request.fields['start_date'] = formattedStartDate;
    request.fields['status'] = '2'; // Change status if needed
    request.fields['deliver'] = '2';
    request.fields['homework_code'] = widget.homework_code;

    // Check if a file is selected using file_picker
    if (_selectedFile != null || _selectedImage != null) {
      String filePath = _selectedFile ?? _selectedImage!;
      print('File path: $filePath'); // Make sure the path is correct

      // Add the file to the request
      var file = await http.MultipartFile.fromPath('file', filePath,
          contentType: MediaType('image', 'jpeg'));
      request.files.add(file);
    }

    try {
      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print("Response: $responseData");

        // Show success message with custom left and right margin
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Form submitted successfully!',
              style: TextStyle(
                fontSize: 16, // Customize text size
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Makes the SnackBar floating
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Customize corners
            ),
            margin: EdgeInsets.only(
              left: 30, // Custom left margin
              right: 30, // Custom right margin
              bottom: 20, // Optional bottom margin
            ),
            padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24), // Custom padding for height and width
          ),
        );

        // Go back to the previous screen (pop the current screen)
        Navigator.pop(context);
      } else {
        // If the request failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit the form. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");

      // Show error message in case of exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report PR')),
      body: SingleChildScrollView(
        // <-- Wrap Column with SingleChildScrollView
        child: Center(
          child: Container(
            width: 320,
            height: 411,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 21,
                  child: Container(
                    width: 320,
                    height: 590,
                    decoration: ShapeDecoration(
                      color: Color(0xFF748A9C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 17,
                  top: 54,
                  child: SizedBox(
                    width: 225,
                    height: 16,
                    child: Text(
                      'Tanggal Selesai :',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 127,
                  top: 50,
                  child: Container(
                    width: 119,
                    height: 35,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(
                        _startDate != null
                            ? '${_startDate?.day}/${_startDate?.month}/${_startDate?.year}'
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 17,
                  top: 117,
                  child: SizedBox(
                    width: 225,
                    height: 16,
                    child: Text(
                      'Upload file atau gambar :',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 130,
                  top: 140,
                  child: Container(
                    width: 171,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => _pickFileWithPermission(
                          context), // Pilih file atau gambar
                      child: Text(
                        _selectedFile != null
                            ? 'File: $_selectedFile'
                            : (_selectedImage != null
                                ? 'Gambar: $_selectedImage'
                                : 'Pilih file/gambar'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Positioned(
                  left: 13,
                  top: 140, // Sesuaikan posisi tombol
                  child: SizedBox(
                    width: 100,
                    height: 50, // Lebih tinggi agar tombol lebih mudah diakses
                    child: TextButton(
                      onPressed: () => submitForm(
                          context), // Mengirimkan data ketika tombol ditekan
                      style: TextButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 239, 239, 240),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Ajukan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
