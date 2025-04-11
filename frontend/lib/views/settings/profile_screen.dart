import 'package:flutter/material.dart';

// Các hằng số cho màu sắc, kích thước và khoảng cách
const double _avatarRadius = 40.0;
const double _infoIconRadius = 20.0;
const double _spacing = 16.0;
const double _smallSpacing = 4.0;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Thông tin người dùng (có thể lấy từ API hoặc provider sau này)
  static const String _fullName = 'Vishal Khadok';
  static const String _description = 'I love fast food';
  static const String _email = 'hello@halalab.co';
  static const String _phoneNumber = '408-841-0926';

  @override
  Widget build(BuildContext context) {
    // Sử dụng ThemeData để lấy màu sắc và kiểu chữ
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
          TextButton(
            onPressed: () {
              // Logic cho nút "EDIT" (có thể mở form chỉnh sửa)
            },
            child: const Text(
              'EDIT',
              style: TextStyle(
                color: Colors.orange,
                decoration: TextDecoration.underline,
                decorationColor: Colors.orange,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(_spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần Avatar và thông tin người dùng
            _buildUserInfoSection(textTheme),
            const SizedBox(height: _spacing * 2),
            // Phần thông tin chi tiết được bao quanh bởi container
            Container(
              padding: const EdgeInsets.all(_spacing),
              decoration: BoxDecoration(
                color: Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // Hiệu ứng bóng đổ
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'FULL NAME',
                    value: _fullName,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: _spacing),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'EMAIL',
                    value: _email,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: _spacing),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'PHONE NUMBER',
                    value: _phoneNumber,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị phần Avatar và thông tin người dùng
  Widget _buildUserInfoSection(TextTheme textTheme) {
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
              _fullName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _description,
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
