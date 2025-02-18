import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:image_picker/image_picker.dart'; // Import image_picker untuk memilih gambar
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';

class CustomPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final int parentId;
  final int subjectId;
  final String alamat;
  final String status;
  final String namalengkap;

  const CustomPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.parentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
    required this.namalengkap,
  }) : super(key: key);

  @override
  _CustomPageState createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  String _selectedPengajuan = 'Izin';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedFile; // Untuk menyimpan path atau nama file yang diupload
  String? _selectedImage; // Untuk menyimpan path gambar yang dipilih
  String _alasanKetidakhadiran = ''; // Untuk alasan ketidakhadiran siswa
  String _fileType =
      'file'; // Menyimpan jenis file yang dipilih (data atau gambar)

  // Fungsi untuk menampilkan DatePicker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate =
        isStartDate ? DateTime.now() : _endDate ?? DateTime.now();
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
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  // Fungsi untuk memilih file menggunakan file_picker
  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      if (await file.exists()) {
        setState(() {
          _selectedFile = file.path;
          _selectedImage = null; // Reset if a file is selected
        });
      } else {
        // Use BuildContext for the ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("File tidak ditemukan."),
          backgroundColor: Colors.red,
        ));
      }
    }

    // Jika memilih gambar
    else if (_fileType == 'image') {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery); // Pilih gambar dari galeri
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile.path; // Menyimpan path gambar
          _selectedFile = null; // Reset file jika gambar dipilih
        });
      }
    }
  }

  Future<void> submitForm(BuildContext context) async {
    // Format dates inside submitForm
    String formattedStartDate = _startDate != null
        ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}"
        : "";

    String formattedEndDate = _endDate != null
        ? "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}"
        : formattedStartDate; // Use start date if endDate is null

    String description = _alasanKetidakhadiran; // Reason for absence
    String title = _selectedPengajuan; // Submission type

    // API endpoint
    var uri = Uri.parse("https://api-pinakad.pintarkerja.com/pengajuan.php");

    // Create multipart request
    var request = http.MultipartRequest('POST', uri);

    // Adding form fields
    request.fields['student_id'] = widget.studentId.toString();
    request.fields['parent_id'] = widget.parentId.toString();
    request.fields['class_id'] = widget.classId.toString();
    request.fields['start_date'] = formattedStartDate;
    request.fields['end_date'] = formattedEndDate;
    request.fields['status'] = '2'; // Change status if needed
    request.fields['description'] = description;
    request.fields['title'] = title;

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
      appBar: AppBar(title: Text('Pengajuan Izin')),
      body: Center(
        child: Container(
          width: 320,
          height: 611,
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
              // Dropdown Pengajuan
              Positioned(
                left: 17,
                top: 65,
                child: Container(
                  width: 286,
                  height: 60,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButton<String>(
                      value: _selectedPengajuan,
                      icon: Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      underline: SizedBox(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPengajuan = newValue!;
                        });
                      },
                      items: <String>['Izin', 'Sakit', 'Cuti']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              // Alasan Ketidakhadiran
              Positioned(
                left: 17,
                top: 157,
                child: Container(
                  width: 286,
                  height: 203,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    maxLines: 15,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Masukkan alasan ketidakhadiran",
                      fillColor: Color(0xffF1F0F5),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _alasanKetidakhadiran = value;
                      });
                      print("Alasan Ketidakhadiran: $_alasanKetidakhadiran");
                    },
                  ),
                ),
              ),
              // Pilih Tanggal
              Positioned(
                left: 17,
                top: 374,
                child: SizedBox(
                  width: 225,
                  height: 16,
                  child: Text(
                    'Mulai tanggal :',
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
                left: 17,
                top: 393,
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
                left: 184,
                top: 374,
                child: SizedBox(
                  width: 225,
                  height: 16,
                  child: Text(
                    'Hingga tanggal :',
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
                left: 184,
                top: 393,
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
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      _endDate != null
                          ? '${_endDate?.day}/${_endDate?.month}/${_endDate?.year}'
                          : 'Pilih Tanggal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              // Pilih File (Data atau Gambar)
              Positioned(
                left: 17,
                top: 442,
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
                left: 136,
                top: 487,
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
                    onPressed: () =>
                        _pickFile(context), // Pilih file atau gambar
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
              // Button Ajukan
              Positioned(
                left: 13,
                top: 485, // Sesuaikan posisi tombol
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
    );
  }
}
