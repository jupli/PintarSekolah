import 'dart:io';

import 'package:pintar_akademik/page/absen/absen_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:lottie/lottie.dart';

class CameraAbsenPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final int classId;
  final int sectionId;
  final int studentId;
  final int subjectId;
  final double latId;
  final double longId;
  final String namalengkap;

  const CameraAbsenPage({
    Key? key,
    required this.cameras,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.latId,
    required this.longId,
    required this.namalengkap,
  }) : super(key: key);

  @override
  State<CameraAbsenPage> createState() => _CameraAbsenPageState();
}

class _CameraAbsenPageState extends State<CameraAbsenPage>
    with TickerProviderStateMixin {
  late FaceDetector faceDetector;
  late List<CameraDescription> cameras;
  CameraController? controller;
  XFile? image;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    loadCamera();
    faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: true,
        enableLandmarks: true,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    faceDetector.close();
    super.dispose();
  }

  Future<void> loadCamera() async {
    cameras = await availableCameras();
    CameraDescription? frontCamera;

    // Find the front camera
    for (CameraDescription camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera != null) {
      controller = CameraController(frontCamera, ResolutionPreset.max);
      await controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } else {
      _showSnackbar(
        "Ups, kamera depan tidak ditemukan!",
        Colors.redAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 87, 230, 233),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Foto Selfie",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (controller == null || !controller!.value.isInitialized)
            const Center(child: CircularProgressIndicator())
          else
            CameraPreview(controller!),
          Positioned(
            top: 40,
            width: size.width,
            child: Lottie.asset(
              "assets/raw/face_id_ring.json",
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: size.width,
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Pastikan Anda berada di tempat terang, agar wajah terlihat jelas.",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ClipOval(
                      child: Material(
                        color: Colors.pinkAccent,
                        child: InkWell(
                          splashColor: Colors.pink,
                          onTap: () => takePicture(),
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              Icons.camera_enhance_outlined,
                              color: Colors.white,
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
        ],
      ),
    );
  }

  Future<void> takePicture() async {
    final hasPermission = await handleLocationPermission();
    if (hasPermission &&
        controller != null &&
        controller!.value.isInitialized) {
      try {
        controller!.setFlashMode(FlashMode.off);
        image = await controller!.takePicture();
        _showLoaderDialog(context);
        final inputImage = InputImage.fromFilePath(image!.path);
        processImage(inputImage);
      } catch (e) {
        _showSnackbar("Ups, $e", Colors.redAccent);
      }
    }
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar(
          "Location services are disabled. Please enable the services.",
          Colors.redAccent);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar("Location permission denied.", Colors.redAccent);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar("Location permission denied forever, we cannot access.",
          Colors.redAccent);
      return false;
    }
    return true;
  }

  void _showLoaderDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
              SizedBox(width: 20),
              Text("Sedang memeriksa data..."),
            ],
          ),
        );
      },
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);
    isBusy = false;

    if (faces.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AbsenPage(
            image: image,
            classId: widget.classId,
            sectionId: widget.sectionId,
            studentId: widget.studentId,
            subjectId: widget.subjectId,
            latId: widget.latId,
            longId: widget.longId,
            namalengkap: widget.namalengkap,
          ),
        ),
      );
    } else {
      _showSnackbar("Ups, wajah harus jelas terlihat!", Colors.redAccent);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
