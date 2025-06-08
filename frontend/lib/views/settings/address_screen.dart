import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/views/settings/add_address.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Address {
  final int id;
  final String addressName;
  final String streetAddress;
  final String? apartment;
  final String recipientName;
  final String phoneNumber;
  final String latitude;
  final String longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IconData icon;
  final Color iconColor;
  final String label;

  Address({
    required this.id,
    required this.addressName,
    required this.streetAddress,
    this.apartment,
    required this.recipientName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['address_id'],
      addressName: json['address_name'],
      streetAddress: json['street_address'],
      apartment: json['apartment'],
      recipientName: json['recipient_name'],
      phoneNumber: json['phone_number'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      label: json['label'],
      icon:
          json['label'].toLowerCase().contains('home')
              ? Icons.home
              : Icons.work,
      iconColor:
          json['label'].toLowerCase().contains('home')
              ? Colors.blue
              : Colors.purple,
    );
  }
}

// Các hằng số
const double _spacing = 24.0;

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  _AddressesScreenState createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  // Hàm gọi API lấy danh sách địa chỉ
  Future<List<Address>> _fetchAddresses() async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('https://api.df.nguyenquangcuong.pro/user/address'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((json) => Address.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load addresses: ${response.statusCode}');
    }
  }

  // Hàm xóa địa chỉ
  Future<void> _deleteAddress(int addressId) async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.delete(
      Uri.parse('https://api.df.nguyenquangcuong.pro/user/address/$addressId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete address: ${response.statusCode}');
    }
  }

  // Hàm lưu địa chỉ được chọn vào SharedPreferences và chuyển hướng về HomeScreen
  Future<void> _selectAddress(Address address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lưu thông tin địa chỉ vào SharedPreferences
      await prefs.setString('user_address', address.addressName);
      await prefs.setString('user_latitude', address.latitude);
      await prefs.setString('user_longitude', address.longitude);

      // Chuyển hướng về trang trước đó
      Navigator.pop(context, address);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to select address: $e')));
    }
  }

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
        child: FutureBuilder<List<Address>>(
          future: _fetchAddresses(),
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
            final addresses = snapshot.data ?? [];
            return Column(
              children: [
                // Danh sách địa chỉ
                Expanded(
                  child:
                      addresses.isEmpty
                          ? const Center(child: Text('No addresses found'))
                          : ListView.separated(
                            itemCount: addresses.length,
                            separatorBuilder:
                                (context, index) =>
                                    const SizedBox(height: _spacing),
                            itemBuilder:
                                (context, index) => _buildAddressCard(
                                  addresses[index],
                                  textTheme,
                                ),
                          ),
                ),
                // Nút "Add New Address"
                _buildAddButton(context),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget hiển thị một card địa chỉ
  Widget _buildAddressCard(Address address, TextTheme textTheme) {
    return GestureDetector(
      onTap: () => _selectAddress(address), // Chọn địa chỉ và chuyển hướng
      child: Container(
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
            // Icon địa chỉ với vòng tròn bao quanh
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(address.icon, color: address.iconColor, size: 24.0),
            ),
            const SizedBox(width: _spacing),
            // Thông tin địa chỉ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.label), // Sử dụng label thay vì hardcode 'Home'
                  const SizedBox(height: 4.0),
                  Text(
                    '${address.addressName}',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Nút chỉnh sửa
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAddressScreen(address: address),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
            // Nút xóa
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.orange),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Address'),
                        content: const Text(
                          'Are you sure you want to delete this address?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  try {
                    await _deleteAddress(address.id);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address deleted successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete address: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị nút "Add New Address"
  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          ).then((_) => setState(() {}));
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

// Extension để tạo màu xám nhạt với opacity 0.1
extension ColorExtension on Color {
  static Color get grey10 => Colors.grey.withOpacity(0.1);
}
