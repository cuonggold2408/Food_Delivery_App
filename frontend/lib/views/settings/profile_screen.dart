import 'package:flutter/material.dart';
import 'package:frontend/views/settings/edit_profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/views/settings/user_profile_data.dart'; // Import UserProfile

// Các hằng số cho màu sắc, kích thước và khoảng cách
const double _avatarRadius = 40.0;
const double _infoIconRadius = 20.0;
const double _spacing = 16.0;
const double _smallSpacing = 4.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Hàm gọi API để lấy thông tin hồ sơ người dùng
  Future<UserProfile> _fetchUserProfile() async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final Map<String, dynamic> data = jsonResponse['data'] ?? jsonResponse;
      return UserProfile.fromJson(data);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
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
          'Personal Info',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          FutureBuilder<UserProfile>(
            future: _fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError) {
                // Ẩn nút "EDIT" khi đang tải hoặc có lỗi
                return const SizedBox.shrink();
              }
              final userProfile = snapshot.data!;
              return TextButton(
                onPressed: () {
                  // Điều hướng sang màn hình EditProfileScreen với userProfile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              EditProfileScreen(userProfile: userProfile),
                    ),
                  ).then((result) {
                    if (result == true) {
                      setState(() {}); // Làm mới dữ liệu sau khi chỉnh sửa
                    }
                  });
                },
                child: const Text(
                  'EDIT',
                  style: TextStyle(
                    color: Colors.orange,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.orange,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final userProfile = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(_spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phần Avatar và thông tin người dùng
                _buildUserInfoSection(textTheme, userProfile),
                const SizedBox(height: _spacing * 2),
                // Phần thông tin chi tiết được bao quanh bởi container
                Container(
                  padding: const EdgeInsets.all(_spacing),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.person,
                        label: 'FULL NAME',
                        value: userProfile.fullName,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: _spacing),
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'EMAIL',
                        value: userProfile.email,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: _spacing),
                      _buildInfoRow(
                        icon: Icons.phone,
                        label: 'PHONE NUMBER',
                        value: userProfile.phoneNumber,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget hiển thị phần Avatar và thông tin người dùng
  Widget _buildUserInfoSection(TextTheme textTheme, UserProfile userProfile) {
    return Row(
      children: [
        CircleAvatar(
          radius: _avatarRadius,
          backgroundColor: Colors.orange[100],
          // Có thể thêm ảnh: backgroundImage: NetworkImage('url_to_image'),
        ),
        const SizedBox(width: _spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userProfile.fullName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userProfile.bio,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // Widget hiển thị một hàng thông tin (icon, label, value)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: _infoIconRadius,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: _spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: _smallSpacing),
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
