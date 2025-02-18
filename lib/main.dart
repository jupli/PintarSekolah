import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX package
import 'package:pintar_akademik/page/loginguru.dart';
import 'package:pintar_akademik/page/loginsiswa.dart';
import 'package:pintar_akademik/page/loginortu.dart';
import 'controllers/login_controller_guru.dart';
import 'controllers/login_controller_murid.dart';
import 'controllers/login_controller_ortu.dart'; // Import the controller

void main() {
  // Register the controller globally
// This registers the controller so it can be accessed via GetX
  Get.put(LoginControllerGuru());
  Get.put(LoginControllerMurid());
  Get.put(LoginControllerOrtu());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Gantilah MaterialApp dengan GetMaterialApp
      title: 'Pintar Sekolah',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String label;
  final Image imageAsset;
  final VoidCallback onTap;

  const CustomCard({
    Key? key,
    required this.label,
    required this.imageAsset,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap to navigate
      child: Container(
        width: 265,
        height: 99.45,
        margin: EdgeInsets.only(bottom: 20), // Add margin to avoid overlapping
        decoration: BoxDecoration(
          color: Color(0xFF00C1FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xFF2EA0FC), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 120,
                height: 91,
                child: imageAsset, // Use the Image widget directly
              ),
            ),
            Positioned(
              left: 133,
              top: 38,
              child: SizedBox(
                width: 120,
                height: 23,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Container with Positioned elements
          Container(
            width: 360,
            height: 800,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                // Oval-shaped background
                Positioned(
                  left: 0,
                  top: 598,
                  child: Container(
                    width: 69,
                    height: 69,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            "assets/images/star1.png"), // Image in the top-left corner
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 277,
                  top: 598,
                  child: Container(
                    width: 83,
                    height: 83,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            "assets/images/corner2.png"), // Image in the top-left corner
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                // Top-left corner image
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            "assets/images/corner1.png"), // Image in the top-left corner
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                // Top-right corner image
                Positioned(
                  left: 277,
                  top: 20,
                  child: Container(
                    width: 69,
                    height: 69,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            "assets/images/star1.png"), // Image in the top-right corner
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Positioning the Logo at the top center
          Positioned(
            top: 30, // Adjusted to move it to the top
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/logoutama.png"), // Logo
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),

          // Adjusted Text positioning to avoid overlap
          Positioned(
            left: 72,
            top: 170, // Adjusted to give space from the top
            child: SizedBox(
              width: 215,
              height: 46,
              child: Text(
                'Selamat Datang !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF00C1FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            left: 102,
            top: 200, // Adjusted to give space from "Selamat Datang"
            child: SizedBox(
              width: 156,
              height: 26,
              child: Text(
                'Login sebagai :',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF748A9C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Positioning the Cards further below the texts
          Positioned(
            left: 47,
            top: 250, // Adjusted to give space from "Login sebagai"
            child: CustomCard(
              label: 'Guru',
              imageAsset: Image.asset("assets/images/tombolguru.png"),
              onTap: () {
                Get.to(
                    () => const LoginGuruScreen()); // Navigate to LoginScreen
              },
            ),
          ),
          Positioned(
            left: 47,
            top: 370, // Adjusted to give space from the first card
            child: CustomCard(
              label: 'Orang Tua',
              imageAsset: Image.asset("assets/images/tombolortu.png"),
              onTap: () {
                Get.to(
                    () => const LoginOrtuScreen()); // Navigate to LoginScreen
              },
            ),
          ),
          Positioned(
            left: 47,
            top: 490, // Adjusted to give space from the second card
            child: CustomCard(
              label: 'Siswa',
              imageAsset: Image.asset("assets/images/tombolmurid.png"),
              onTap: () {
                Get.to(
                    () => const LoginSiswaScreen()); // Navigate to LoginScreen
              },
            ),
          ),
        ],
      ),
    );
  }
}
