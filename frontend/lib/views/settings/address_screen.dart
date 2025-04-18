import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/views/settings/add_address.dart';
import 'package:frontend/services/api_service.dart';

class Address {
  final int id;
  final String addressName;
  final String streetAddress;
  final String? apartment;
  final String recipientName;
  final String phoneNumber;
  final String postalCode;
  final bool isDefault;
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
    required this.postalCode,
    required this.isDefault,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.icon,
    required this.iconColor,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['address_id'],
      addressName: json['address_name'],
      streetAddress: json['street_address'],
      apartment: json['apartment'],
      recipientName: json['recipient_name'],
      phoneNumber: json['phone_number'],
      postalCode: json['postal_code'],
      isDefault: json['is_default'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Sử dụng address_name thay vì label tĩnh để xác định icon
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
      Uri.parse('http://10.0.2.2:3000/user/address'),
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
      Uri.parse('http://10.0.2.2:3000/user/address/$addressId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete address: ${response.statusCode}');
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
          // Icon địa chỉ với vòng tròn bao quanh
          Container(
            padding: const EdgeInsets.all(
              8.0,
            ), // Khoảng cách bên trong vòng tròn
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Màu nền vòng tròn
            ),
            child: Icon(
              address.icon,
              color: address.iconColor,
              size: 24.0, // Kích thước icon
            ),
          ),
          const SizedBox(width: _spacing),
          // Thông tin địa chỉ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home'),
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
              ).then((_) => setState(() {})); // Refresh sau khi chỉnh sửa
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
                  setState(() {}); // Refresh danh sách
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
          ).then((_) => setState(() {})); // Refresh sau khi thêm
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
