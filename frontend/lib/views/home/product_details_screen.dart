import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  bool _isLoading = true;
  String? _errorMessage;
  int _quantity = 1;
  Map<String, List<String>> _selectedOptions = {};
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _fetchProductData();
    _loadToken();
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
      final response = await http
          .get(
            Uri.parse(
              'https://api.df.nguyenquangcuong.pro/restaurants/items/${widget.itemId}?restaurantId=${widget.restaurantId}',
            ),
          )
          .timeout(const Duration(seconds: 10));

      print(
        'Product API Status for ID ${widget.itemId}: ${response.statusCode}',
      );
      print('Product API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] == null) {
          throw Exception('Phản hồi API không hợp lệ: Thiếu trường "data"');
        }
        setState(() {
          _productData = jsonData['data'];
          _isLoading = false;
          _selectedOptions = {};
          for (var option in _productData['options']) {
            String categoryId = option['option_category']['category_id'];
            _selectedOptions[categoryId] = [];
          }
        });
      } else {
        throw Exception(
          'Không thể tải thông tin sản phẩm: Mã trạng thái ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin sản phẩm với ID ${widget.itemId}: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải thông tin sản phẩm: $e';
      });
    }
  }

  String _formatPrice(String price) {
    try {
      final number = double.parse(price);
      final intNumber = number.toInt();
      return '${(intNumber ~/ 1000)}.${intNumber % 1000 == 0 ? '000' : (intNumber % 1000).toString().padLeft(3, '0')}₫';
    } catch (e) {
      return '$price₫';
    }
  }

  double _calculateTotalPrice() {
    double basePrice = double.tryParse(_productData?['item_price'] ?? '0') ?? 0;
    double optionsPrice = 0;

    if (_productData != null && _productData['options'] != null) {
      for (var option in _productData['options']) {
        String categoryId = option['option_category']['category_id'];
        List<String> selectedOptionIds = _selectedOptions[categoryId] ?? [];
        for (var dish in option['option_category']['option_dishes']) {
          if (selectedOptionIds.contains(dish['option_id'])) {
            optionsPrice += double.tryParse(dish['option_price'] ?? '0') ?? 0;
          }
        }
      }
    }

    return (basePrice + optionsPrice) * _quantity;
  }

  Future<void> _addToCart() async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      // TODO: Chuyển hướng đến màn hình đăng nhập
      // Navigator.pushNamed(context, '/login');
      return;
    }

    List<Map<String, String>> customizations = [];
    _selectedOptions.forEach((categoryId, optionIds) {
      for (var optionId in optionIds) {
        customizations.add({"option_id": optionId});
      }
    });

    final body = {
      "restaurant_id": widget.restaurantId,
      "item_id": widget.itemId,
      "quantity": _quantity,
      "customizations": customizations,
    };

    try {
      final response = await http
          .post(
            Uri.parse('https://api.df.nguyenquangcuong.pro/cart'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

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
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        // TODO: Chuyển hướng đến màn hình đăng nhập
        // Navigator.pushNamed(context, '/login');
      } else {
        throw Exception(
          'Không thể thêm vào giỏ hàng: Mã trạng thái ${response.statusCode}',
        );
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
          errorBuilder:
              (context, error, stackTrace) => Image.asset(
                'assets/images/default_shop.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Text(
      'Nhà hàng không xác định',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      _productData?['item_name'] ?? 'Sản phẩm không xác định',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        const Text('N/A', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Miễn phí',
            style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          '20 phút',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return const Row(
      children: [
        Icon(Icons.delivery_dining, color: Colors.grey),
        SizedBox(width: 8),
        Text('Miễn phí giao hàng cho đơn từ \$10 trở lên'),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SỐ LƯỢNG',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap:
                  _quantity > 1
                      ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                      : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _quantity > 1 ? Colors.white : Colors.grey[200],
                  border: Border.all(
                    color: _quantity > 1 ? Colors.orange : Colors.grey[400]!,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.remove,
                  color: _quantity > 1 ? Colors.orange : Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _quantity++;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.orange, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.orange, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsSelector() {
    if (_productData == null ||
        _productData['options'] == null ||
        _productData['options'].isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TÙY CHỌN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._productData['options'].map((option) {
          var category = option['option_category'];
          String categoryId = category['category_id'];
          String categoryName = category['category_name'];
          int minSelections = category['category_min_selections'];
          int maxSelections = category['category_max_selections'];
          List<dynamic> dishes = category['option_dishes'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$categoryName${minSelections > 0 ? ' (Bắt buộc, chọn tối thiểu $minSelections)' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    dishes.map((dish) {
                      String optionId = dish['option_id'];
                      String optionName = dish['option_name'];
                      String optionPrice = dish['option_price'];
                      bool isSelected =
                          _selectedOptions[categoryId]?.contains(optionId) ??
                          false;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            List<String> currentSelections =
                                _selectedOptions[categoryId] ?? [];

                            if (isSelected) {
                              if (currentSelections.length > minSelections) {
                                currentSelections.remove(optionId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Phải chọn ít nhất $minSelections $categoryName',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                            } else {
                              if (currentSelections.length < maxSelections) {
                                currentSelections.add(optionId);
                              } else if (maxSelections == 1) {
                                currentSelections = [optionId];
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Chỉ được chọn tối đa $maxSelections $categoryName',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                            }

                            _selectedOptions[categoryId] = currentSelections;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.white,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.orange
                                      : Colors.grey[400]!,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '$optionName${optionPrice != '0.00' ? ' (+${_formatPrice(optionPrice)})' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected ? Colors.orange : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THÀNH PHẦN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          _productData?['item_desc']?.isNotEmpty == true
              ? _productData['item_desc']
              : 'Không có mô tả thành phần.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPriceAndAddButton() {
    final totalPrice = _calculateTotalPrice();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          bool canAddToCart = true;
          String? errorMessage;
          for (var option in _productData['options']) {
            String categoryId = option['option_category']['category_id'];
            String categoryName = option['option_category']['category_name'];
            int minSelections =
                option['option_category']['category_min_selections'];
            int currentSelections = _selectedOptions[categoryId]?.length ?? 0;
            if (currentSelections < minSelections) {
              canAddToCart = false;
              errorMessage =
                  'Vui lòng chọn ít nhất $minSelections $categoryName';
              break;
            }
          }

          if (canAddToCart) {
            await _addToCart();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage ?? 'Vui lòng chọn đủ tùy chọn'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Text(
          'Thêm vào giỏ - ${_formatPrice(totalPrice.toStringAsFixed(0))}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchProductData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 80,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProductImage(),
                              const SizedBox(height: 16),
                              _buildStoreHeader(),
                              const SizedBox(height: 8),
                              _buildProductTitle(),
                              const SizedBox(height: 16),
                              _buildRatingRow(),
                              const SizedBox(height: 16),
                              _buildDeliveryInfo(),
                              const SizedBox(height: 24),
                              _buildOptionsSelector(),
                              const SizedBox(height: 24),
                              _buildQuantitySelector(),
                              const SizedBox(height: 24),
                              _buildIngredientsSection(),
                            ],
                          ),
                        ),
                      ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: SafeArea(top: false, child: _buildPriceAndAddButton()),
          ),
        ],
      ),
    );
  }
}
