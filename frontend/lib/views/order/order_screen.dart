import 'package:flutter/material.dart';
import 'package:frontend/services/firebase_service.dart';
import 'package:frontend/views/order/payment_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:frontend/views/cart/cart_manager.dart';
import 'package:frontend/views/settings/add_address.dart';
import 'package:frontend/views/order/order_status_screen.dart';

import 'package:frontend/views/settings/address_screen.dart';

void main() {
  runApp(const MyApp(restaurantId: ''));
}

class MyApp extends StatelessWidget {
  final String restaurantId;

  const MyApp({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OrderScreen(restaurantId: restaurantId),
    );
  }
}

class OrderScreen extends StatefulWidget {
  final String restaurantId;

  const OrderScreen({super.key, required this.restaurantId});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Map<String, dynamic>? _cartData;
  bool _isLoading = true;
  String? _error;
  String? _authToken;
  final CartManager _cartManager = CartManager();
  String? _selectedAddress;
  String? _userAddress;
  final double _shippingFee = 15000; // Fixed shipping fee
  String? _userName;
  String? _userPhone;
  late int _orderId ;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchUserAddress();
  }
  
  Future<void> _initializeData() async {
    await _loadToken();
    if (widget.restaurantId.isEmpty) {
      setState(() {
        _error = 'Không chọn nhà hàng';
        _isLoading = false;
      });
      return;
    }
    if (_authToken == null) {
      setState(() {
        _error = 'Vui lòng đăng nhập để xem giỏ hàng';
        _isLoading = false;
      });
      return;
    }
    await _fetchCartData();
    await _loadAddress();
  }

  Future<void> _fetchUserAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? address = prefs.getString('user_address');
      setState(() {
        _userAddress = address ?? 'Unknown location';
      });
    } catch (e) {
      print('Error fetching address: $e');
      setState(() {
        _userAddress = 'Failed to load address';
      });
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('access_token');
    });
    print('Loaded token: $_authToken');
  }

  Future<void> _fetchCartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.df.nguyenquangcuong.pro/cart?restaurantId=${widget.restaurantId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 10));

      print('Cart API Status for restaurantId ${widget.restaurantId}: ${response.statusCode}');
      print('Cart API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['statusCode'] == 200 && jsonData['data'] != null) {
          setState(() {
            _cartData = jsonData['data'];
            _isLoading = false;
          });
          final cartItems = (jsonData['data']['items'] as List<dynamic>?)?.map((item) {
                return CartItem.fromJson({
                  ...item,
                  'restaurant_id': widget.restaurantId,
                  'item_id': item['item_id'] ?? item['name_dish'].hashCode.toString(),
                });
              }).toList() ?? [];
          _cartManager.updateCart(widget.restaurantId, cartItems);
        } else {
          throw Exception('Phản hồi API không hợp lệ: ${jsonData['message'] ?? 'Thiếu dữ liệu giỏ hàng'}');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Không thể tải giỏ hàng: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi lấy giỏ hàng: $e');
      setState(() {
        _error = 'Không thể tải giỏ hàng: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAddress() async {
    if (_authToken == null) {
      setState(() {
        _selectedAddress = 'Vui lòng đăng nhập để xem địa chỉ';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.df.nguyenquangcuong.pro/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 10));

      print('Profile API Status: ${response.statusCode}');
      print('Profile API Response: ${response.body}');
      _fetchUserAddress();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['statusCode'] == 200 && jsonData['data'] != null) {
          final phone = jsonData['data']['phone_number'] ?? 'Chưa có số điện thoại';
          final addressDetail = _userAddress ?? 'Chưa có địa chỉ';
          final name = jsonData['data']['name'] ?? 'Chưa có tên';
          setState(() {
            _selectedAddress = '$addressDetail\n$name $phone';
            _userName = name;
            _userPhone = phone;
            _isLoading = false;
          });
        } else {
          throw Exception('Phản hồi API không hợp lệ: ${jsonData['message'] ?? 'Thiếu dữ liệu địa chỉ'}');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _selectedAddress = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
          _isLoading = false;
        });
      } else {
        throw Exception('Không thể tải địa chỉ: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi lấy địa chỉ: $e');
      setState(() {
        _selectedAddress = 'Không thể tải địa chỉ: $e';
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _fetchProductData(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/restaurants/items/$itemId?restaurantId=${widget.restaurantId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 10));

      print('Product API Status for ID $itemId: ${response.statusCode}');
      print('Product API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] == null) {
          throw Exception('Phản hồi API không hợp lệ: Thiếu trường "data"');
        }
        return jsonData['data'];
      } else {
        throw Exception('Không thể tải thông tin sản phẩm: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin sản phẩm với ID $itemId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải thông tin sản phẩm: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _addToCart(String itemId, int quantity, Map<String, List<String>> selectedOptions) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, String>> customizations = [];
    selectedOptions.forEach((categoryId, optionIds) {
      for (var optionId in optionIds) {
        customizations.add({"option_id": optionId});
      }
    });

    final body = {
      "restaurant_id": widget.restaurantId,
      "item_id": itemId,
      "quantity": quantity,
      "customizations": customizations,
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('Cart API Status: ${response.statusCode}');
      print('Cart API Request Body: ${json.encode(body)}');
      print('Cart API Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào giỏ hàng thành công!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchCartData();
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Không thể thêm vào giỏ hàng: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi thêm vào giỏ hàng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: Không thể thêm vào giỏ hàng. Vui lòng thử lại.'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đặt đơn hàng.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userAddress == null || _userAddress == 'Unknown location' || _userAddress == 'Failed to load address') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cập nhật địa chỉ giao hàng.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userName == null || _userPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông tin người nhận không đầy đủ.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final subtotal = _calculateTotalPrice() - _shippingFee;
    final currentTime = DateTime.now().toUtc().toIso8601String();

    final body = {
      "receiver": {
        "name": _userName,
        "phone": _userPhone,
        "address": _userAddress,
      },
      "subtotal": "2000", // Use calculated subtotal
      "delivery_fee": "0",
      "discount": "0",
      "payment_method": "BANK_TRANSFER",
      "delivery_method": "STANDARD",
      "created_at": currentTime,
      "updated_at": currentTime,
      "restaurant_id": widget.restaurantId,
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('Order API Status: ${response.statusCode}');
      print('Order API Request Body: ${json.encode(body)}');
      print('Order API Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['statusCode'] == 201 && jsonData['data'] != null) {
          setState(() {
            _orderId = jsonData['data']['order_id'];
          });
          print('Order ID: $_orderId');
          final qrLink = jsonData['data']['qr_link'] ?? 'https://via.placeholder.com/300';
          final timeOut = jsonData['data']['time_out'];
          final now = DateTime.now();
          final remaining = DateTime.parse(timeOut).difference(now);
          final remainingSeconds = remaining.inSeconds;
          final remainingMinutes = (remainingSeconds / 60).floor();

          // Trigger system notification
          await FirebaseService.triggerPaymentSuccessNotification(_authToken!, _orderId);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                qrCodeUrl: qrLink,
                totalPrice: _calculateTotalPrice(),
                accessToken: _authToken!,
                timeOut: timeOut,
                orderId: _orderId,
              ),
            ),
          );
        } else {
          throw Exception('Phản hồi API không hợp lệ: ${jsonData['message'] ?? 'Thiếu dữ liệu QR link'}');
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Không thể đặt đơn hàng: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi đặt đơn hàng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: Không thể đặt đơn hàng. Vui lòng thử lại.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddItemBottomSheet(String itemId, int currentQuantity, List<String> initialCustomizations) async {
    final productData = await _fetchProductData(itemId);
    if (productData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AddItemBottomSheet(
          productData: productData,
          restaurantId: widget.restaurantId,
          itemId: itemId,
          cartManager: _cartManager,
          addToCart: _addToCart,
          initialQuantity: currentQuantity,
          initialCustomizations: initialCustomizations,
        );
      },
    ).then((_) {
      _fetchCartData();
    });
  }

  String _formatPrice(double price) {
    final intNumber = price.toInt();
    return '${(intNumber ~/ 1000)}.${intNumber % 1000 == 0 ? '000' : (intNumber % 1000).toString().padLeft(3, '0')}₫';
  }

  Widget _buildOptionSection(Map<String, dynamic> item) {
    final optionName = item['option_name'] ?? '';
    if (optionName.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          optionName,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () async {
        await _showAddItemBottomSheet(
          item['item_id'] ?? item['name_dish'].hashCode.toString(),
          item['quantity'] ?? 1,
          item['option_id']?.cast<String>() ?? [],
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image_dish']?.isNotEmpty == true ? item['image_dish'] : 'https://via.placeholder.com/60',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/default_shop.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name_dish'] ?? 'Món không xác định',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Số lượng: ${item['quantity'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    _buildOptionSection(item),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(double.tryParse(item['total_pay']?.toString() ?? '0') ?? 0),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final newQuantity = (item['quantity'] ?? 0) - 1;
                                if (newQuantity > 0) {
                                  final success = await _cartManager.updateCartItem(
                                    restaurantId: widget.restaurantId,
                                    itemId: item['item_id'] ?? item['name_dish'].hashCode.toString(),
                                    quantity: newQuantity,
                                    customizations: item['option_id']?.cast<String>() ?? [],
                                  );
                                  if (success) {
                                    await _fetchCartData();
                                  }
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item['quantity'] ?? 0}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final newQuantity = (item['quantity'] ?? 0) + 1;
                                final success = await _cartManager.updateCartItem(
                                  restaurantId: widget.restaurantId,
                                  itemId: item['item_id'] ?? item['name_dish'].hashCode.toString(),
                                  quantity: newQuantity,
                                  customizations: item['option_id']?.cast<String>() ?? [],
                                );
                                if (success) {
                                  await _fetchCartData();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalPrice() {
    final cartItems = _cartManager.getCarts()[widget.restaurantId] ?? [];
    double total = 0;
    for (var item in cartItems) {
      double basePrice = double.tryParse(item.itemData['item_price'] ?? '0') ?? 0;
      double optionsPrice = 0;
      if (item.customizations.isNotEmpty && item.itemData['options'] != null) {
        for (var customization in item.customizations) {
          String optionId = customization['option_id']!;
          for (var option in item.itemData['options']) {
            for (var dish in option['option_category']['option_dishes'] ?? []) {
              if (dish['option_id'] == optionId) {
                optionsPrice += double.tryParse(dish['option_price'] ?? '0') ?? 0;
              }
            }
          }
        }
      }
      total += (basePrice + optionsPrice) * item.quantity;
    }
    return total > 0 ? total + _shippingFee : _shippingFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Xác nhận đơn hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(_selectedAddress ?? 'Chưa có địa chỉ'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                if (_authToken == null) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Yêu cầu đăng nhập'),
                                      content: const Text(
                                        'Vui lòng đăng nhập để xem hoặc chỉnh sửa địa chỉ giao hàng.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.pushNamed(context, '/login').then((_) {
                                              _loadToken();
                                              _fetchUserAddress();
                                              _loadAddress();
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            'Đăng nhập',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  if (_userAddress == 'Unknown location' || _userAddress == 'Failed to load address') {
                                    Navigator.pushNamed(context, '/location');
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
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
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          var offsetAnimation = animation.drive(tween);
                                          return SlideTransition(position: offsetAnimation, child: child);
                                        },
                                        transitionDuration: const Duration(milliseconds: 300),
                                      ),
                                    );
                                    if (result != null && result is Address) {
                                      setState(() {
                                        _userAddress = result.addressName;
                                        _selectedAddress = '${result.addressName}\n ${result.phoneNumber}';
                                      });
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('user_address', result.addressName);
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Khách đã chọn món tại ${_cartData?['restaurant_name'] ?? 'Nhà hàng'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: _cartData?['items']?.map<Widget>((item) => _buildCartItem(item))?.toList() ?? [],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Chi tiết thanh toán',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tổng giá món (${_cartData?['quantity_item'] ?? 0} món)'),
                                  Text(_formatPrice(_calculateTotalPrice() - _shippingFee)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Phí giao hàng'),
                                  Text(_formatPrice(_shippingFee)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng thanh toán',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatPrice(_calculateTotalPrice()),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ],
                              ),
                              const Text(
                                'Đã bao gồm thuế',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              // TODO: Implement voucher addition
                            },
                            child: const Text('Thêm voucher'),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement voucher selection
                            },
                            child: const Text('Chọn voucher >'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.local_taxi),
                          SizedBox(width: 10),
                          Text('Thường cho Tài xế'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement no tip functionality
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Chưa...'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement 5K tip
                            },
                            child: const Text('5K'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement 10K tip
                            },
                            child: const Text('10K'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement 15K tip
                            },
                            child: const Text('15K'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              // TODO: Implement custom tip
                            },
                            child: const Text('Khác'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Card(
                        child: ListTile(
                          title: Text('ShopeePay · MB 300 Xu'),
                          trailing: Text('Tiến mát'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Đặt đơn - ${_formatPrice(_calculateTotalPrice())}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class AddItemBottomSheet extends StatefulWidget {
  final dynamic productData;
  final String restaurantId;
  final String itemId;
  final CartManager cartManager;
  final Future<void> Function(String, int, Map<String, List<String>>) addToCart;
  final int initialQuantity;
  final List<String> initialCustomizations;

  const AddItemBottomSheet({
    super.key,
    required this.productData,
    required this.restaurantId,
    required this.itemId,
    required this.cartManager,
    required this.addToCart,
    this.initialQuantity = 1,
    this.initialCustomizations = const [],
  });

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final Map<String, List<String>> _selectedOptions = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;

    // Initialize _selectedOptions for each category
    for (var option in widget.productData['options'] ?? []) {
      String categoryId = option['option_category']['category_id'];
      _selectedOptions[categoryId] = [];
    }

    // Pre-populate selected options from initialCustomizations
    for (var optionId in widget.initialCustomizations) {
      for (var option in widget.productData['options'] ?? []) {
        String categoryId = option['option_category']['category_id'];
        if (option['option_category']['option_dishes']?.any((dish) => dish['option_id'] == optionId) ?? false) {
          if (!_selectedOptions[categoryId]!.contains(optionId)) {
            _selectedOptions[categoryId]!.add(optionId);
          }
        }
      }
    }

    print('Initial _selectedOptions: $_selectedOptions');
  }

  String _formatPrice(double price) {
    final intNumber = price.toInt();
    return '${(intNumber ~/ 1000)}.${intNumber % 1000 == 0 ? '000' : (intNumber % 1000).toString().padLeft(3, '0')}₫';
  }

  double _calculateTotalPrice() {
    double basePrice = double.tryParse(widget.productData['item_price'] ?? '0') ?? 0;
    double optionsPrice = 0;

    if (widget.productData['options'] != null) {
      for (var option in widget.productData['options']) {
        String categoryId = option['option_category']['category_id'];
        List<String> selectedOptionIds = _selectedOptions[categoryId] ?? [];
        for (var dish in option['option_category']['option_dishes'] ?? []) {
          if (selectedOptionIds.contains(dish['option_id'])) {
            optionsPrice += double.tryParse(dish['option_price'] ?? '0') ?? 0;
          }
        }
      }
    }

    return (basePrice + optionsPrice) * _quantity;
  }

  Widget _buildOptionSection(String title, List<dynamic> dishes, String categoryId, int maxSelections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: dishes.map((dish) {
            bool isSelected = _selectedOptions[categoryId]?.contains(dish['option_id']) ?? false;
            return ChoiceChip(
              label: Text('${dish['option_name']} - ${_formatPrice(double.parse(dish['option_price'] ?? '0'))}'),
              selected: isSelected,
              onSelected: (bool value) {
                setState(() {
                  print('Selecting $title - ${dish['option_name']} (option_id: ${dish['option_id']}), value: $value');

                  if (value) {
                    if (maxSelections == 1) {
                      _selectedOptions[categoryId]!.clear();
                    }

                    if (_selectedOptions[categoryId]!.length < maxSelections) {
                      _selectedOptions[categoryId]!.add(dish['option_id']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bạn chỉ có thể chọn tối đa $maxSelections mục trong $title'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    _selectedOptions[categoryId]!.remove(dish['option_id']);
                  }

                  print('Updated _selectedOptions: $_selectedOptions');
                });
              },
              selectedColor: Colors.red[100],
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.red : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Colors.red : Colors.grey,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chỉnh sửa món',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.productData['item_image']?.isNotEmpty == true
                      ? widget.productData['item_image']
                      : 'https://via.placeholder.com/60',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/default_shop.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productData['item_name'] ?? 'Sản phẩm không xác định',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giá bao gồm 3000đ tiền hộp',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '200 đã bán | 8 lượt thích',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Còn $_quantity phần',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.productData['options'] != null) ...[
                    for (var option in widget.productData['options']) ...[
                      _buildOptionSection(
                        option['option_category']['category_name'],
                        option['option_category']['option_dishes'],
                        option['option_category']['category_id'],
                        option['option_category']['category_max_selections'],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
              Text(
                _formatPrice(_calculateTotalPrice()),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              onPressed: () async {
                bool canAddToCart = true;
                String? errorMessage;
                for (var option in widget.productData['options'] ?? []) {
                  String categoryId = option['option_category']['category_id'];
                  String categoryName = option['option_category']['category_name'];
                  int minSelections = option['option_category']['category_min_selections'] ?? 0;
                  int currentSelections = _selectedOptions[categoryId]?.length ?? 0;
                  if (currentSelections < minSelections) {
                    canAddToCart = false;
                    errorMessage = 'Vui lòng chọn ít nhất $minSelections $categoryName';
                    break;
                  }
                }

                if (!canAddToCart) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage ?? 'Vui lòng chọn đủ tùy chọn'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Chuyển đổi _selectedOptions thành List<Map<String, String>> cho CartManager
                List<Map<String, String>> customizations = [];
                _selectedOptions.forEach((categoryId, optionIds) {
                  for (var optionId in optionIds) {
                    customizations.add({"option_id": optionId});
                  }
                });

                // Sử dụng widget.productData làm itemData
                final itemData = widget.productData;

                // Gọi hàm addToCart từ CartManager
                final success = await widget.cartManager.addToCart(
                  restaurantId: widget.restaurantId,
                  itemId: widget.itemId,
                  quantity: _quantity,
                  customizations: customizations,
                  itemData: itemData,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật giỏ hàng thành công!'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể cập nhật giỏ hàng. Vui lòng thử lại.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Cập nhật giỏ hàng - ${_formatPrice(_calculateTotalPrice())}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}