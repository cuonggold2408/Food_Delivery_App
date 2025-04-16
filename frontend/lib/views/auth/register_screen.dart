import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/views/auth/otp_verification_screen.dart';
import 'package:frontend/conponents/custom_snack_bar.dart';
import 'package:frontend/conponents/top_snack_bar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  bool isPasswordValid(String password) {
    return password.length >= 8;
  }

  void _showErrorSnackbar(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
    );
  }

  void _showSuccessSnackbar(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(message: message),
    );
  }

  void _register() async {
    try {
      if (!mounted) return;

      final String name = nameController.text.trim();
      final String email = emailController.text.trim();
      final String password = passwordController.text;
      final String confirmPassword = confirmPasswordController.text;

      // Validate inputs
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        _showErrorSnackbar('Vui lòng điền đầy đủ thông tin');
        return;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _showErrorSnackbar('Email không hợp lệ');
        return;
      }

      if (!isPasswordValid(password)) {
        _showErrorSnackbar('Mật khẩu phải có ít nhất 8 ký tự');
        return;
      }

      if (password != confirmPassword) {
        _showErrorSnackbar('Mật khẩu không khớp');
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call API
      final response = await ApiService.sendOtp(email: email);
      print("OTP Response: $response");

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (response['success'] == true) {
        // Navigate to OTP page
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OtpVerificationPage(
                  email: email,
                  type: "REGISTER",
                  onOtpVerified: (otp) async {
                    final registerResponse = await ApiService.register(
                      name,
                      email,
                      password,
                      confirmPassword,
                      otp,
                    );

                    if (!mounted) return;
                    if (registerResponse['success'] == true) {
                      _showSuccessSnackbar('Đăng ký thành công!');
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      _showErrorSnackbar(
                        registerResponse['error'] ?? 'Đăng ký thất bại',
                      );
                    }
                  },
                ),
          ),
        );
      } else {
        _showErrorSnackbar(response['error'] ?? 'Gửi OTP thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading nếu có lỗi
      _showErrorSnackbar('Có lỗi xảy ra: ${e.toString()}');
      print("Registration error: $e");
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      isConfirmPasswordVisible = !isConfirmPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Màu nền toàn màn hình là đen than
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF121212),
        elevation: 0, // Bỏ bóng của AppBar để đồng nhất với nền
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40),
              color: Color(0xFF121212), // Màu đen than cho khung chứa "SIGN UP"
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Create a new account',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
              margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAME',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'John Doe',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'EMAIL',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'example@gmail.com',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'PASSWORD',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: '********',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'CONFIRM PASSWORD',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: '********',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.black),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'LOG IN',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
