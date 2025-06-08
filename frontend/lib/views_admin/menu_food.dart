import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/views_admin/edit_food.dart';

class FoodListScreen extends StatefulWidget {
  final String restaurantId;

  const FoodListScreen({super.key, required this.restaurantId});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  static const _primary = Color(0xFFFC6E2A);
  List<FoodItem> _items = [];
  bool _isLoading = true;
  String _restaurantName = '';

  @override
  void initState() {
    super.initState();
    _fetchFoods();
  }

  Future<void> _fetchFoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/${widget.restaurantId}',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      debugPrint(
        'Fetch foods response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> menuItems = jsonData['data']['menuItems'] ?? [];
        final String restaurantName =
            jsonData['data']['name'] ?? 'Nhà hàng không tên';

        debugPrint('Menu items count (raw): ${menuItems.length}');
        final filteredItems =
            menuItems.where((item) => item['is_available'] == true).toList();
        debugPrint('Menu items count (filtered): ${filteredItems.length}');
        for (var item in filteredItems) {
          debugPrint('Menu item: $item');
        }

        setState(() {
          _restaurantName = restaurantName;
          _items =
              filteredItems
                  .map(
                    (item) => FoodItem(
                      id: item['item_id'] ?? '',
                      name: item['name'] ?? 'Không rõ tên',
                      price: int.tryParse(item['price'].toString()) ?? 0,
                      details: item['description'] ?? '',
                      imageUrl: item['image_url'] ?? '',
                    ),
                  )
                  .toList();
          _isLoading = false;
        });
        debugPrint('Items after fetch: ${_items.map((e) => e.id).toList()}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tải danh sách món ăn thất bại: Status ${response.statusCode}',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách món ăn: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFoodItem(String itemId) async {
    if (itemId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không tìm thấy ID món ăn')));
      return;
    }

    debugPrint('Deleting item with ID: $itemId');
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http.delete(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/${widget.restaurantId}/food/$itemId',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      debugPrint('Delete response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xoá món ăn thành công')));
        await _fetchFoods();
        debugPrint('Items after delete: ${_items.map((e) => e.id).toList()}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Xoá món ăn thất bại: Status ${response.statusCode} - ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xoá món ăn: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 10),
              child: Row(
                children: [
                  _CircleIcon(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _restaurantName.isNotEmpty
                          ? '$_restaurantName'
                          : 'Danh sách món ăn',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.05, 14, w * 0.05, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tổng ${_items.length.toString().padLeft(2, '0')} món',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                      ? const Center(child: Text('Không có món ăn nào'))
                      : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder:
                            (ctx, i) => _FoodTile(
                              item: _items[i],
                              onEdit: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditFoodScreen(
                                          restaurantId: widget.restaurantId,
                                          foodItem: {
                                            'id': _items[i].id,
                                            'name': _items[i].name,
                                            'price': _items[i].price,
                                            'description': _items[i].details,
                                            'image_url': _items[i].imageUrl,
                                          },
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchFoods();
                                }
                              },
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Xác nhận xoá'),
                                        content: Text(
                                          'Bạn có chắc muốn xoá món "${_items[i].name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Huỷ'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text(
                                              'Xoá',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                debugPrint('Confirm: $confirm');
                                debugPrint('Item ID: ${_items[i].id}');
                                if (confirm == true &&
                                    _items[i].id.isNotEmpty) {
                                  await _deleteFoodItem(_items[i].id);
                                }
                              },
                            ),
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/add_new_item',
            arguments: widget.restaurantId,
          );
          if (result == true) {
            _fetchFoods();
          }
        },
        backgroundColor: _primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = MediaQuery.of(context).size.width * 0.11;
    return Material(
      color: const Color(0xFFEDEFF1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: d,
          height: d,
          child: Icon(icon, size: d * 0.5, color: const Color(0xFF424242)),
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final FoodItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: w * 0.20,
          height: w * 0.20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: item.imageUrl.isEmpty ? const Color(0xFF94A3B8) : null,
          ),
          child:
              item.imageUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Container(color: const Color(0xFF94A3B8)),
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${item.price}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [const SizedBox(height: 28)],
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(
                      Icons.edit,
                      color: _FoodListScreenState._primary,
                    ),
                    title: Text('Sửa món ăn'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Xoá món ăn'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
        ),
      ],
    );
  }
}

class FoodItem {
  final String id;
  final String name;
  final int price;
  final String details;
  final String imageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.details,
    required this.imageUrl,
  });
}
