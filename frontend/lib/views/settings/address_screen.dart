import 'package:flutter/material.dart';
import 'package:frontend/views/settings/add_address.dart'; // Import màn hình AddAddressScreen

// Các hằng số cho màu sắc, kích thước và khoảng cách
const double _spacing = 24.0;

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  // Danh sách địa chỉ mẫu (có thể thay thế bằng dữ liệu từ API sau này)
  static const List<_AddressData> _addresses = [
    _AddressData(
      type: 'HOME',
      address: '2464 Royal Ln. Mesa, New Jersey 45463',
      icon: Icons.home,
      iconColor: Colors.blue,
    ),
    _AddressData(
      type: 'WORK',
      address: '3891 Ranchview Dr. Richardson, California 62639',
      icon: Icons.work,
      iconColor: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Address', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(_spacing),
        child: Column(
          children: [
            // Danh sách địa chỉ
            Expanded(
              child: ListView.separated(
                itemCount: _addresses.length,
                separatorBuilder:
                    (context, index) => const SizedBox(
                      height: _spacing,
                    ), // Khoảng cách giữa các card
                itemBuilder:
                    (context, index) =>
                        _buildAddressCard(_addresses[index], textTheme),
              ),
            ),
            // Nút "Add New Address"
            _buildAddButton(context), // Truyền context vào _buildAddButton
          ],
        ),
      ),
    );
  }

  // Widget hiển thị một card địa chỉ
  Widget _buildAddressCard(_AddressData address, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(_spacing),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FA),
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 158, 158, 158),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon địa chỉ
          Icon(address.icon, color: address.iconColor),
          const SizedBox(width: _spacing),
          // Thông tin địa chỉ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.type,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  address.address,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          // Nút chỉnh sửa
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () {}, // Để trống logic chỉnh sửa
          ),
          // Nút xóa
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.orange),
            onPressed: () {}, // Để trống logic xóa
          ),
        ],
      ),
    );
  }

  // Widget hiển thị nút "Add New Address"
  Widget _buildAddButton(BuildContext context) {
    // Thêm tham số context
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Điều hướng đến màn hình AddAddressScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: _spacing),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
        child: const Text(
          'ADD NEW ADDRESS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Class để lưu trữ dữ liệu của một địa chỉ
class _AddressData {
  final String type;
  final String address;
  final IconData icon;
  final Color iconColor;

  const _AddressData({
    required this.type,
    required this.address,
    required this.icon,
    required this.iconColor,
  });
}

// Extension để tạo màu xám nhạt với opacity 0.1
extension ColorExtension on Color {
  static Color get grey10 => Colors.grey.withOpacity(0.1);
}
