import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:pintar_akademik/page/absen/camera_page.dart';
import 'package:camera/camera.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.latId,
        widget.longId,
      );

      // Define acceptable range in meters
      double acceptableRange = 100.0;

      if (distanceInMeters <= acceptableRange) {
        setState(() {
          dLat = position.latitude;
          dLong = position.longitude;
          isLoading = false;
          getAddressFromLongLat(position);
        });
      } else {
        setState(() {
          isLoading = false;
          print('Location is outside the acceptable range.');
          // Optionally show a message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda berada di luar jangkauan yang diizinkan.'),
            ),
          );
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        isLoading = false; // Ensure loading state is updated on error
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

  // Function to submit attendance data to the server
  Future<void> submitAbsen(
      String strAlamat, String nama, String status, XFile? image) async {
    const String url =
        'http://api-pinakad.pintarkerja.com/submit_attendance.php'; // Replace with your server URL

    final now = DateTime.now();
    final timestamp = now.toIso8601String();

    final Map<String, dynamic> data = {
      'class_id': widget.classId,
      'section_id': widget.sectionId,
      'student_id': widget.studentId,
      'subject_id': widget.subjectId,
      'lokasi': strAlamat,
      'namalengkap': widget.namalengkap,
      'photo': image != null ? base64Encode(await image.readAsBytes()) : null,
      'timestamp': timestamp,
    };

    print('Data yang dikirim: ${jsonEncode(data)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Yeay! Absen berhasil!",
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: Colors.green,
              shape: StadiumBorder(),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to DashboardPage
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
          throw Exception('Failed to submit attendance');
        }
      } else {
        throw Exception('Failed to submit attendance');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text("Gagal mengirim absensi: $e",
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          shape: const StadiumBorder(),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 8, 10, 109),
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
                  color: Color.fromARGB(255, 8, 10, 109),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 12),
                    Icon(Icons.face_retouching_natural_outlined,
                        color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Absen Foto Selfie ya!",
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
                        longId: widget.longId,
                        namalengkap: widget
                            .namalengkap, // Replace with the actual longId
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
                                      "Ups, foto dan inputan tidak boleh kosong!",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.redAccent,
                                shape: StadiumBorder(),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            submitAbsen(strAlamat, controllerName.text,
                                strStatus, image);
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
