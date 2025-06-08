import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/views/settings/user_profile_data.dart'; // Import UserProfile

// Các hằng số cho màu sắc, kích thước và khoảng cách (tái sử dụng từ profile_screen.dart)
const double _avatarRadius = 40.0;
const double _spacing = 16.0;
const double _smallSpacing = 4.0;

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile; // Nhận dữ liệu UserProfile

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controller để quản lý dữ liệu nhập liệu
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  bool _isSaving = false; // Biến trạng thái để hiển thị loading

  @override
  void initState() {
    super.initState();
    // Khởi tạo các controller với dữ liệu từ userProfile
    _fullNameController = TextEditingController(
      text: widget.userProfile.fullName,
    );
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneController = TextEditingController(
      text: widget.userProfile.phoneNumber,
    );
    _bioController = TextEditingController(text: widget.userProfile.bio);
  }

  @override
  void dispose() {
    // Giải phóng các controller khi widget bị hủy
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Hàm gọi API để cập nhật hồ sơ người dùng
  Future<void> _updateUserProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.put(
        Uri.parse('https://api.df.nguyenquangcuong.pro/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _fullNameController.text,
          'bio': _bioController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Profile updated successfully')),
        // );
        Navigator.pop(
          context,
          true,
        ); // Quay lại và báo hiệu cập nhật thành công
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Phần ảnh đại diện
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: _avatarRadius,
                  backgroundColor: Colors.orange[100],
                  // Có thể thêm ảnh: backgroundImage: NetworkImage('url_to_image'),
                ),
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.orange,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 15, color: Colors.white),
                    onPressed: () {
                      // Logic chọn ảnh (có thể dùng package image_picker)
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacing * 2),
            // Trường nhập Full Name
            _buildTextField(
              controller: _fullNameController,
              label: 'FULL NAME',
              textTheme: textTheme,
            ),
            const SizedBox(height: _spacing),
            // Trường nhập Email
            _buildTextField(
              controller: _emailController,
              label: 'EMAIL',
              textTheme: textTheme,
            ),
            const SizedBox(height: _spacing),
            // Trường nhập Phone Number
            _buildTextField(
              controller: _phoneController,
              label: 'PHONE NUMBER',
              textTheme: textTheme,
            ),
            const SizedBox(height: _spacing),
            // Trường nhập Bio
            _buildTextField(
              controller: _bioController,
              label: 'BIO',
              textTheme: textTheme,
              maxLines: 3,
            ),
            const SizedBox(height: _spacing * 2),
            // Nút Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget để xây dựng các trường nhập liệu
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextTheme textTheme,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: _smallSpacing),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
