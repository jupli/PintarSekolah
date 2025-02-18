import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller_ortu.dart';

class LoginOrtuScreen extends StatelessWidget {
  const LoginOrtuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final LoginControllerOrtu controller =
        Get.find(); // Get instance of the controller

    bool inputFailed = false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Container with Positioned elements
          Container(
            width: 360,
            height: 800,
            decoration: BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                Positioned(
                  left: -118,
                  top: 288,
                  child: Container(
                    width: 595,
                    height: 608,
                    decoration: ShapeDecoration(
                      color: Color(0xFF00C1FF),
                      shape: OvalBorder(),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/corner1.png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 277,
                  top: 20,
                  child: Container(
                    width: 69,
                    height: 69,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/star1.png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Formulir untuk input data
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: formKey,
                autovalidateMode: inputFailed
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Tambahkan gambar baru di atas gambar siswa1.png
                    Image.asset('assets/images/logoutama.png'),
                    const SizedBox(height: 30),
                    Image.asset('assets/images/ortu1.png'),

                    const SizedBox(height: 20),
                    // Username Field
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Field can't be empty";
                        }
                        return null;
                      },
                      onSaved: (value) => controller.username.value = value!,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 14),
                    // Password Field
                    Obx(
                      () => TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(controller.obscurePassword.value
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              // Toggle password visibility
                              controller.obscurePassword.value =
                                  !controller.obscurePassword.value;
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Field can't be empty";
                          }
                          return null;
                        },
                        onSaved: (value) => controller.password.value = value!,
                        obscureText: controller.obscurePassword.value,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Login Button
                    SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            controller.loginortu();
                          } else {
                            inputFailed = true;
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              const Color(0xff4CBCBD)),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 14)),
                        ),
                        child: GetBuilder<LoginControllerOrtu>(
                          builder: (controller) {
                            if (controller.loading.value) {
                              return const CircularProgressIndicator(
                                color: Colors.white,
                              );
                            } else {
                              return const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cancel Button
                    SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(); // Navigate back
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 14)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
