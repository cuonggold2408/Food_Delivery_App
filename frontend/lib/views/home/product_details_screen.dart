import 'package:flutter/material.dart';
import 'package:frontend/views/order/order_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:frontend/views/cart/cart_manager.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String itemId;
  final String restaurantId;

  const ProductDetailsScreen({
    super.key,
    required this.itemId,
    required this.restaurantId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  dynamic _productData;
  dynamic _reviewData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken;
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadToken();
    await Future.wait([_fetchProductData(), _fetchReviewData()]);
    if (_authToken != null) {
      await _fetchCartData();
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('access_token');
    });
    print('Loaded token: $_authToken');
  }

  Future<void> _fetchProductData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/restaurants/items/${widget.itemId}?restaurantId=${widget.restaurantId}',
        ),
      ).timeout(const Duration(seconds: 10));

      print('Product API Status for ID ${widget.itemId}: ${response.statusCode}');
      print('Product API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] == null) {
          throw Exception('Phản hồi API không hợp lệ: Thiếu trường "data"');
        }
        setState(() {
          _productData = jsonData['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Không thể tải thông tin sản phẩm: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin sản phẩm với ID ${widget.itemId}: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải thông tin sản phẩm: $e';
      });
    }
  }

  Future<void> _fetchReviewData() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await http.get(
      Uri.parse(
        'https://api.df.nguyenquangcuong.pro/reviews/products/${widget.itemId}?page=1&limit=5',
      ),
    ).timeout(const Duration(seconds: 10));

    print('Review API Status for ID ${widget.itemId}: ${response.statusCode}');
    print('Review API Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['data'] == null || jsonData['data']['data'] == null) {
        throw Exception('Phản hồi API không hợp lệ: Thiếu trường "data.data"');
      }
      setState(() {
        _reviewData = jsonData['data']['data'] is List ? jsonData['data']['data'] : [];
        _isLoading = false;
      });
    } else {
      throw Exception('Không thể tải đánh giá: Mã trạng thái ${response.statusCode}');
    }
  } catch (e) {
    print('Lỗi khi lấy đánh giá với ID ${widget.itemId}: $e');
    setState(() {
      _isLoading = false;
      _errorMessage = 'Không thể tải đánh giá: $e';
    });
  }
}


  Future<void> _fetchCartData() async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để xem giỏ hàng'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data']['items'] != null) {
          final cartItems = (jsonData['data']['items'] as List<dynamic>)
              .map((item) => CartItem.fromJson({
                    ...item,
                    'restaurant_id': widget.restaurantId,
                    'item_id': item['name_dish'].hashCode.toString(),
                  }))
              .toList();
          _cartManager.updateCart(widget.restaurantId, cartItems);
        } else if (jsonData['data'] != null && jsonData['data']['items'] == null) {
          _cartManager.updateCart(widget.restaurantId, []);
        }
        setState(() {});
      } else {
        throw Exception('Không thể tải giỏ hàng: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi lấy giỏ hàng: $e');
      setState(() {
        _errorMessage = 'Không thể tải giỏ hàng: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    final intNumber = price.toInt();
    return '${(intNumber ~/ 1000)}.${intNumber % 1000 == 0 ? '000' : (intNumber % 1000).toString().padLeft(3, '0')}₫';
  }

  double _calculateTotalPrice() {
    double total = 0;
    final cartItems = _cartManager.getCarts()[widget.restaurantId] ?? [];
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
    return total > 0 ? total : 0;
  }

  bool _isCartEmpty() {
    final cartItems = _cartManager.getCarts()[widget.restaurantId] ?? [];
    return cartItems.isEmpty;
  }

  Future<void> _showAddItemBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AddItemBottomSheet(
          productData: _productData,
          restaurantId: widget.restaurantId,
          itemId: widget.itemId,
          cartManager: _cartManager,
          addToCart: _addToCart,
        );
      },
    ).then((_) {
      _fetchCartData();
    });
  }

  Future<void> _showCartBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CartBottomSheet(
          cartManager: _cartManager,
          restaurantId: widget.restaurantId,
          onQuantityChanged: () {
            _fetchCartData();
          },
        );
      },
    );
  }

  Future<void> _addToCart(int quantity, Map<String, List<String>> selectedOptions) async {
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
      "item_id": widget.itemId,
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
        Navigator.pop(context);
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
  Widget _buildStarRating(int rating) {
  return Row(
    children: List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 20,
      );
    }),
  );
}

  Widget _buildProductImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Image.network(
          _productData?['item_image']?.isNotEmpty == true
              ? _productData['item_image']
              : 'https://englishwithlucy.com/wp-content/uploads/2022/12/AdobeStock_142101192-1536x1024.jpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/default_shop.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        ),
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      _productData?['item_name'] ?? 'Sản phẩm không xác định',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProductInfo() {
    return Row(
      children: [
        Text(
          'Giá bao gồm 3000đ tiền hộp | ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          '200 đã bán | 8 lượt thích',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPriceAndAddButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () async {
            if (_productData != null) {
              await _showAddItemBottomSheet();
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    if (_isCartEmpty()) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              _showCartBottomSheet();
            },
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Giỏ hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                _formatPrice(_calculateTotalPrice()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderScreen(restaurantId: widget.restaurantId)),
                  );
                },
                child: const Text(
                  'Giao hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _formatDate(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return dateStr;
  }
}

 Widget _buildReviewSection() {
  if (_reviewData == null || _reviewData.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text('Chưa có đánh giá nào.'),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviewData.length,
          itemBuilder: (context, index) {
            final review = _reviewData[index];
            if (review == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        child: Text(review['user']?['name']?.substring(0, 1) ?? '?'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review['user']?['name'] ?? 'Người dùng ẩn',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                _buildStarRating(review['rating'] ?? 0),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review['content'] ?? 'Không có bình luận',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(review['createdAt']),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (review['medias'] != null && review['medias'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: review['medias'].length,
                        itemBuilder: (context, mediaIndex) {
                          final media = review['medias'][mediaIndex];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                media['url'] ?? '',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 16),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
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
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductImage(),
                        const SizedBox(height: 16),
                        _buildProductTitle(),
                        const SizedBox(height: 8),
                        _buildProductInfo(),
                        const SizedBox(height: 16),
                        _buildPriceAndAddButton(),
                        _buildReviewSection(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

class AddItemBottomSheet extends StatefulWidget {
  final dynamic productData;
  final String restaurantId;
  final String itemId;
  final CartManager cartManager;
  final Future<void> Function(int, Map<String, List<String>>) addToCart;

  const AddItemBottomSheet({
    super.key,
    required this.productData,
    required this.restaurantId,
    required this.itemId,
    required this.cartManager,
    required this.addToCart,
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
    for (var option in widget.productData['options'] ?? []) {
      String categoryId = option['option_category']['category_id'];
      _selectedOptions[categoryId] = [];
    }
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
                  if (value && !_selectedOptions[categoryId]!.contains(dish['option_id'])) {
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
                  } else if (!value) {
                    _selectedOptions[categoryId]!.remove(dish['option_id']);
                  }
                });
              },
              selectedColor: Colors.red[100],
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.red : Colors.black54,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isSelected ? Colors.red : Colors.grey),
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
                'Thêm món mới',
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
                      : 'https://englishwithlucy.com/wp-content/uploads/2022/12/AdobeStock_142101192-1536x1024.jpeg',
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

                await widget.addToCart(_quantity, _selectedOptions);
              },
              child: Text(
                'Thêm vào giỏ hàng - ${_formatPrice(_calculateTotalPrice())}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartBottomSheet extends StatefulWidget {
  final CartManager cartManager;
  final String restaurantId;
  final VoidCallback onQuantityChanged;

  const CartBottomSheet({
    super.key,
    required this.cartManager,
    required this.restaurantId,
    required this.onQuantityChanged,
  });

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  String _formatPrice(double price) {
    final intNumber = price.toInt();
    return '${(intNumber ~/ 1000)}.${intNumber % 1000 == 0 ? '000' : (intNumber % 1000).toString().padLeft(3, '0')}₫';
  }

  double _calculateItemPrice(CartItem item) {
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
    return (basePrice + optionsPrice) * item.quantity;
  }

  double _calculateTotalPrice() {
    double total = 0;
    final cartItems = widget.cartManager.getCarts()[widget.restaurantId] ?? [];
    for (var item in cartItems) {
      total += _calculateItemPrice(item);
    }
    return total;
  }

  Widget _buildOptionSection(String title, List<Map<String, String>> customizations, Map<String, dynamic> itemData) {
    if (customizations.isEmpty) return const SizedBox.shrink();

    List<Widget> optionWidgets = [];
    for (var customization in customizations) {
      String optionId = customization['option_id']!;
      for (var option in itemData['options'] ?? []) {
        String categoryName = option['option_category']['category_name'];
        for (var dish in option['option_category']['option_dishes'] ?? []) {
          if (dish['option_id'] == optionId) {
            optionWidgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${dish['option_name']} ($categoryName)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            );
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        ...optionWidgets,
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
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
            if (item.itemData['item_image']?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.itemData['item_image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemData['item_name'] ?? 'Sản phẩm không xác định',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Còn ${item.quantity} phần',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  _buildOptionSection('Tùy chọn', item.customizations, item.itemData),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrice(_calculateItemPrice(item)),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final newQuantity = item.quantity - 1;
                              if (newQuantity > 0) {
                                final success = await widget.cartManager.updateCartItem(
                                  restaurantId: widget.restaurantId,
                                  itemId: item.itemId,
                                  quantity: newQuantity,
                                  customizations: item.customizations,
                                );
                                if (success) {
                                  setState(() {});
                                  widget.onQuantityChanged();
                                }
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final newQuantity = item.quantity + 1;
                              final success = await widget.cartManager.updateCartItem(
                                restaurantId: widget.restaurantId,
                                itemId: item.itemId,
                                quantity: newQuantity,
                                customizations: item.customizations,
                              );
                              if (success) {
                                setState(() {});
                                widget.onQuantityChanged();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cartManager.getCarts()[widget.restaurantId] ?? [];
    final double totalWithDelivery = _calculateTotalPrice();

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
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
                'Giỏ hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () async {
                  final success = await widget.cartManager.clearCart(widget.restaurantId);
                  if (success) {
                    setState(() {});
                    widget.onQuantityChanged();
                  }
                },
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text(
                      'Giỏ hàng đang rỗng',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: cartItems.map((item) => _buildCartItem(item)).toList(),
                    ),
                  ),
          ),
          if (cartItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    _formatPrice(totalWithDelivery),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
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
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderScreen(restaurantId: widget.restaurantId)),
                  );
                },
                child: Text(
                  'Giao hàng - ${_formatPrice(totalWithDelivery)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}