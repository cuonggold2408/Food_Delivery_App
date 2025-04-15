import 'package:flutter/material.dart';
import 'address_screen.dart'; // Import màn hình Addresses

// Các hằng số cho màu sắc, kích thước và khoảng cách
const double _avatarRadius = 40.0;
const double _spacing = 16.0;

class Menu extends StatelessWidget {
  const Menu({super.key});

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
        physics: const ClampingScrollPhysics(), // Tắt hiệu ứng kéo dãn
        clipBehavior: Clip.hardEdge, // Cắt nội dung dư thừa
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
                    onTap: () {
                      // Điều hướng đến màn hình Personal Info
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.location_on,
                    title: 'Addresses',
                    onTap: () {
                      // Điều hướng đến màn hình Addresses với hiệu ứng trượt từ trái sang
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
                            const begin = Offset(
                              1.0,
                              0.0,
                            ); // Bắt đầu từ bên trái
                            const end = Offset.zero; // Kết thúc ở giữa màn hình
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
                          ), // Thời gian chuyển trang
                        ),
                      );
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
                    onTap: () {
                      // Logic cho nút Log Out
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
              'Vishal Khadok',
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
        color: const Color(0xFFF6F8FA), // Màu nền giống như trong code trước
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
