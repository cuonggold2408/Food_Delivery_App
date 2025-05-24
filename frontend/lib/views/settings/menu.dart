import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/views/settings/profile_screen.dart';
import 'package:frontend/views/settings/address_screen.dart'; // Import màn hình Addresses
import 'package:frontend/conponents/custom_snack_bar.dart';
import 'package:frontend/conponents/top_snack_bar.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import ApiService

// Các hằng số cho màu sắc, kích thước và khoảng cách
const double _avatarRadius = 40.0;
const double _spacing = 16.0;

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String _userName = 'Guest'; // Tên người dùng mặc định

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Gọi API để lấy thông tin người dùng khi khởi tạo
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _fetchUserProfile() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        print('No access token found');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/user/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Profile API Status: ${response.statusCode}');
      print('Profile API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final userName = jsonData['data']['name'] ?? 'Guest';
        setState(() {
          _userName = userName;
        });
      } else {
        print('Failed to fetch profile: Status ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile: Status ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error fetching profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    void showSuccessSnackbar(String message) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(message: message),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Logic cho nút menu (nếu cần)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(_spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần Avatar và thông tin người dùng
              _buildUserInfoSection(textTheme),
              const SizedBox(height: _spacing * 2),
              // Nhóm 1: Personal Info, Addresses
              _buildGroupedMenuItems(
                items: [
                  _MenuItemData(
                    icon: Icons.person,
                    title: 'Personal Info',
                    onTap: () async {
                      final accessToken = await _getAccessToken();
                      if (accessToken == null) {
                        // Chưa đăng nhập: Hiển thị popup yêu cầu đăng nhập
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Yêu cầu đăng nhập'),
                                content: const Text(
                                  'Vui lòng đăng nhập để xem thông tin cá nhân.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/login');
                                    },
                                    child: const Text('Đăng nhập'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: const Text('Đăng ký'),
                                  ),
                                ],
                              ),
                        );
                      } else {
                        // Đã đăng nhập: Điều hướng đến ProfileScreen
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ProfileScreen(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.location_on,
                    title: 'Addresses',
                    onTap: () async {
                      final accessToken = await _getAccessToken();
                      if (accessToken == null) {
                        // Chưa đăng nhập: Hiển thị popup yêu cầu đăng nhập
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Yêu cầu đăng nhập'),
                                content: const Text(
                                  'Vui lòng đăng nhập để quản lý địa chỉ.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/login');
                                    },
                                    child: const Text('Đăng nhập'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: const Text('Đăng ký'),
                                  ),
                                ],
                              ),
                        );
                      } else {
                        // Đã đăng nhập: Điều hướng đến AddressesScreen
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const AddressesScreen(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: _spacing),
              // Nhóm 2: Cart, Favourite, Notifications, Payment Method
              _buildGroupedMenuItems(
                items: [
                  _MenuItemData(
                    icon: Icons.shopping_cart,
                    title: 'Cart',
                    onTap: () {},
                  ),
                  _MenuItemData(
                    icon: Icons.favorite,
                    title: 'Favourite',
                    onTap: () {},
                  ),
                  _MenuItemData(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _MenuItemData(
                    icon: Icons.payment,
                    title: 'Payment Method',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: _spacing),
              // Nhóm 3: FAQs, User Reviews, Settings
              _buildGroupedMenuItems(
                items: [
                  _MenuItemData(
                    icon: Icons.help,
                    title: 'FAQs',
                    iconColor: Colors.orange,
                    onTap: () {},
                  ),
                  _MenuItemData(
                    icon: Icons.reviews,
                    title: 'User Reviews',
                    onTap: () {},
                  ),
                  _MenuItemData(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: _spacing),
              // Nhóm 4: Log Out
              _buildGroupedMenuItems(
                items: [
                  _MenuItemData(
                    icon: Icons.logout,
                    title: 'Log Out',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () async {
                      await ApiService.logout();
                      showSuccessSnackbar('Đăng xuất thành công!');
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                ],
              ),
            ],
          ),
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
              _userName, // Hiển thị tên người dùng từ trạng thái
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'I love fast food',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // Widget hiển thị một nhóm các mục trong container
  Widget _buildGroupedMenuItems({required List<_MenuItemData> items}) {
    return Container(
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
        children:
            items.map((item) {
              return _buildMenuItem(
                icon: item.icon,
                title: item.title,
                iconColor: item.iconColor,
                textColor: item.textColor,
                onTap: item.onTap,
              );
            }).toList(),
      ),
    );
  }

  // Widget hiển thị một mục trong danh sách
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _spacing),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.blue),
            const SizedBox(width: _spacing),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Class để lưu trữ dữ liệu của một mục trong danh sách
class _MenuItemData {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });
}
