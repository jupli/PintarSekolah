import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:pintar_akademik/page/absen/camera_page.dart';
import 'package:camera/camera.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../dashboard/dashboard.dart';

class AbsenPage extends StatefulWidget {
  final XFile? image;
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final double latId;
  final double longId;
  final String namalengkap;

  const AbsenPage({
    Key? key,
    this.image,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.latId,
    required this.longId,
    required this.namalengkap,
  }) : super(key: key);

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  XFile? image;
  String strAlamat = "";
  String strDate = "";
  String strTime = "";
  String strStatus = "Absen Masuk";
  bool isLoading = false;
  double dLat = 0.0, dLong = 0.0;
  int dateHours = 0, dateMinutes = 0;
  final controllerName = TextEditingController();

  late StreamController<String> _timeController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    handleLocationPermission();
    setDateTime();
    image = widget.image; // Initialize image from widget parameter

    // Initialize StreamController and Timer for time updates
    _timeController = StreamController<String>();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());

    if (image != null) {
      setState(() {
        isLoading = true;
      });
      getGeoLocationPosition();
    }
  }

  @override
  void dispose() {
    _timeController.close();
    _timer.cancel();
    controllerName.dispose();
    super.dispose();
  }

  void _getTime() {
    var now = DateTime.now();
    var formattedTime = DateFormat('HH:mm:ss').format(now);
    var formattedDate =
        DateFormat('yyyy-MM-dd').format(now); // Update date format
    var timestamp = '$formattedDate $formattedTime'; // Combine date and time

    _timeController.sink.add('Tanggal & Waktu: $timestamp');
    // Debug print statements
    print('class_id: ${widget.classId}');
    print('section_id: ${widget.sectionId}');
    print('student_id: ${widget.studentId}');
    print('subject_id: ${widget.subjectId}');
    print('latitude: ${widget.latId}');
    print('longitude: ${widget.longId}');
  }

  // Get current location
  Future<void> getGeoLocationPosition() async {
    try {
      // Mendapatkan posisi saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Menyimpan latitude dan longitude
      setState(() {
        dLat = position.latitude;
        dLong = position.longitude;
        isLoading = false;
        // Mengambil alamat dari latitude dan longitude
        getAddressFromLongLat(position);
      });
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        isLoading = false; // Pastikan state loading diperbarui saat error
      });
    }
  }

  // Get address from latitude and longitude
  Future<void> getAddressFromLongLat(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    setState(() {
      dLat = double.parse('${position.latitude}');
      dLat = double.parse('${position.longitude}');
      strAlamat =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
    });
  }

  // Handle location permission
  Future<void> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 10),
              Text("Location services belum diset. set terlebih dahulu.",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          shape: StadiumBorder(),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off, color: Colors.white),
                SizedBox(width: 10),
                Text("Location permission denied.",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            shape: StadiumBorder(),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 10),
              Text("Location permission denied forever, we cannot access.",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          shape: StadiumBorder(),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
  }

  // Set date and time
  void setDateTime() {
    var dateNow = DateTime.now();
    var dateFormat = DateFormat('dd MMMM yyyy');
    var dateTimeFormat = DateFormat('HH:mm:ss');
    var dateHourFormat = DateFormat('HH');
    var dateMinuteFormat = DateFormat('mm');

    setState(() {
      strDate = dateFormat.format(dateNow);
      strTime = dateTimeFormat.format(dateNow);
      dateHours = int.parse(dateHourFormat.format(dateNow));
      dateMinutes = int.parse(dateMinuteFormat.format(dateNow));
      setStatusAbsen();
    });
  }

  // Set status of absent
  void setStatusAbsen() {
    if (dateHours < 8 || (dateHours == 8 && dateMinutes <= 30)) {
      strStatus = "Absen Masuk";
    } else if ((dateHours > 8 && dateHours < 18) ||
        (dateHours == 8 && dateMinutes >= 31)) {
      strStatus = "Absen Telat";
    } else {
      strStatus = "Absen Keluar";
    }
  }

// Fungsi untuk mengompres gambar
  Future<File> compressImage(File imageFile) async {
    final targetPath =
        imageFile.absolute.path.replaceAll('.jpg', '_compressed.jpg');

    var result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 70, // Ubah kualitas gambar jika diperlukan
    );

    return File(result!.path);
  }

  // Function to submit attendance data to the server
  Future<void> submitAbsen(
      String strAlamat, String nama, String status, File image) async {
    const String url =
        'https://api-pinakad.pintarkerja.com/submit_attendance.php';

    try {
      // Compress image before sending
      File compressedImage = await compressImage(image);
      print('Compressed image path: ${compressedImage.path}');
      int fileSize = await compressedImage.length();
      print('Compressed image size: $fileSize bytes');

      if (fileSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Gambar terlalu besar, coba gunakan gambar yang lebih kecil.')));
        return;
      }

      // Convert the image to base64 string
      String base64Image = base64Encode(compressedImage.readAsBytesSync());

      // Prepare the data to be sent as JSON
      Map<String, dynamic> data = {
        'class_id': widget.classId.toString(),
        'section_id': widget.sectionId.toString(),
        'student_id': widget.studentId.toString(),
        'subject_id': widget.subjectId.toString(),
        'lokasi': strAlamat,
        'timestamp':
            (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString(),
        'photo': base64Image, // Send the image as a base64-encoded string
      };

      // Send the data as JSON
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data), // Encode the Map as JSON
      );

      // Handle the response
      var responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Yeay! Absen berhasil!")));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                classId: widget.classId,
                sectionId: widget.sectionId,
                studentId: widget.studentId,
                subjectId: widget.subjectId,
                alamat: strAlamat,
                status: status,
                namalengkap: widget.namalengkap,
              ),
            ),
          );
        } else {
          throw Exception(
              'Failed to submit attendance: ${responseBody['message']}');
        }
      } else {
        throw Exception(
            'Failed to submit attendance with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 87, 230, 233),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Menu Absensi",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Card(
          color: Colors.white,
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 50,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  color: Color.fromARGB(255, 87, 230, 233),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 12),
                    Icon(Icons.face_retouching_natural_outlined,
                        color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Absen Foto Selfie yay!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 0, 20),
                child: Text(
                  "Ambil Foto",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  List<CameraDescription> cameras = await availableCameras();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraAbsenPage(
                        cameras: cameras,
                        classId:
                            widget.classId, // Replace with the actual classId
                        sectionId: widget
                            .sectionId, // Replace with the actual sectionId
                        studentId: widget
                            .studentId, // Replace with the actual studentId
                        subjectId: widget
                            .subjectId, // Replace with the actual subjectId
                        latId: widget.latId, // Replace with the actual latId
                        longId: widget.longId, // Replace with the actual longId
                        namalengkap: widget.namalengkap,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                  width: size.width,
                  height: 150,
                  child: DottedBorder(
                    radius: const Radius.circular(10),
                    borderType: BorderType.RRect,
                    color: const Color.fromARGB(255, 8, 10, 109),
                    strokeWidth: 1,
                    dashPattern: const [5, 5],
                    child: SizedBox.expand(
                      child: FittedBox(
                        child: image != null
                            ? Image.file(File(image!.path), fit: BoxFit.cover)
                            : const Icon(
                                Icons.camera_enhance_outlined,
                                color: Color.fromARGB(255, 8, 10, 109),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.text,
                  controller: controllerName,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    labelText: "Masukan Nama Anda",
                    hintText: "Nama Anda",
                    hintStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey),
                    labelStyle:
                        const TextStyle(fontSize: 14, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 8, 10, 109),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 8, 10, 109),
                      ),
                    ),
                  ),
                ),
              ),

              // StreamBuilder for displaying current date and time
              StreamBuilder<String>(
                stream: _timeController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    String timeData = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeData,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(); // Placeholder jika data belum tersedia
                  }
                },
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  "Lokasi Anda",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 8, 10, 109),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 5 * 24,
                        child: TextField(
                          enabled: false,
                          maxLines: 5,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 8, 10, 109),
                              ),
                            ),
                            hintText: strAlamat.isNotEmpty
                                ? strAlamat
                                : 'Lokasi Kamu',
                            hintStyle: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            fillColor: Colors.transparent,
                            filled: true,
                          ),
                        ),
                      ),
                    ),
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(30),
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: size.width,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 8, 10, 109),
                      child: InkWell(
                        splashColor: Colors.pink,
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          if (image == null || controllerName.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      "Ups, tidak boleh kosong!",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Color.fromARGB(255, 116, 243, 228),
                                shape: StadiumBorder(),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            submitAbsen(strAlamat, controllerName.text,
                                strStatus, File(image!.path));
                          }
                        },
                        child: const Center(
                          child: Text(
                            "Absen Sekarang",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
