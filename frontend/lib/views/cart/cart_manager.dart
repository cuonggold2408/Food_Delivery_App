import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String itemId;
  final String restaurantId;
  final int quantity;
  final List<Map<String, String>> customizations;
  final Map<String, dynamic> itemData;

  CartItem({
    required this.itemId,
    required this.restaurantId,
    required this.quantity,
    required this.customizations,
    required this.itemData,
  });

  CartItem copyWith({
    int? quantity,
    List<Map<String, String>>? customizations,
  }) {
    return CartItem(
      itemId: itemId,
      restaurantId: restaurantId,
      itemData: itemData,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
    );
  }
  
  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'restaurant_id': restaurantId,
        'quantity': quantity,
        'customizations': customizations,
        'item_data': itemData,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        itemId: json['item_id']?.toString() ?? 'unknown', // Placeholder for missing item_id
        restaurantId: json['restaurant_id']?.toString() ?? 'unknown', // Placeholder for missing restaurant_id
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        customizations: (json['option_name']?.isNotEmpty == true)
            ? [
                {'option_id': 'option_${json['option_name'].hashCode}', 'name': json['option_name']}
              ]
            : [],
        itemData: {
          'item_image': json['image_dish'] ?? '',
          'item_name': json['name_dish'] ?? 'Unknown Dish',
          'item_price': ((double.tryParse(json['total_pay']?.toString() ?? '0') ?? 0) / (json['quantity'] ?? 1)).toString(),
          'options': json['option_name']?.isNotEmpty == true
              ? [
                  {
                    'option_category': {
                      'category_id': 'cat_${json['option_name'].hashCode}',
                      'category_name': 'Tùy chọn',
                      'option_dishes': [
                        {
                          'option_id': 'option_${json['option_name'].hashCode}',
                          'option_name': json['option_name'],
                          'option_price': '0',
                        }
                      ]
                    }
                  }
                ]
              : [],
          'message': json['message'] ?? '',
        },
      );
}
class CartManager {
  final Map<String, List<CartItem>> _carts = {};
  String? _currentRestaurantId;
  String? _authToken;

  CartManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadToken();
    await _loadCartFromPrefs();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');
  }

  Future<void> _loadCartFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_data');
      if (cartData != null) {
        final decoded = json.decode(cartData) as Map<String, dynamic>;
        _carts.clear();
        _carts.addAll(decoded.map((key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
                  .toList(),
            )));
        _currentRestaurantId = prefs.getString('current_restaurant_id');
      }
    } catch (e) {
      print('Error loading cart from prefs: $e');
      _carts.clear();
      _currentRestaurantId = null;
    }
  }

  Future<void> _saveCartToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _carts.map((key, value) => MapEntry(
            key,
            value.map((item) => item.toJson()).toList(),
          ));
      await prefs.setString('cart_data', json.encode(cartData));
      if (_currentRestaurantId != null) {
        await prefs.setString('current_restaurant_id', _currentRestaurantId!);
      } else {
        await prefs.remove('current_restaurant_id');
      }
    } catch (e) {
      print('Error saving cart to prefs: $e');
    }
  }

  Future<bool> addToCart({
    required String restaurantId,
    required String itemId,
    required int quantity,
    required List<Map<String, String>> customizations,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      // Update local cart
      _carts[restaurantId] ??= [];
      _currentRestaurantId = restaurantId;

      final existingItemIndex = _carts[restaurantId]!.indexWhere(
        (item) =>
            item.itemId == itemId &&
            _areCustomizationsEqual(item.customizations, customizations),
      );

      if (existingItemIndex != -1) {
        _carts[restaurantId]![existingItemIndex] = CartItem(
          itemId: itemId,
          restaurantId: restaurantId,
          quantity: _carts[restaurantId]![existingItemIndex].quantity + quantity,
          customizations: customizations,
          itemData: itemData,
        );
      } else {
        _carts[restaurantId]!.add(CartItem(
          itemId: itemId,
          restaurantId: restaurantId,
          quantity: quantity,
          customizations: customizations,
          itemData: itemData,
        ));
      }

      await _saveCartToPrefs();

      // Sync with backend
      if (_authToken == null) {
        print('No auth token found');
        return false;
      }

      final body = {
        'restaurant_id': restaurantId,
        'item_id': itemId,
        'quantity': quantity,
        'customizations': customizations,
      };

      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('Add to Cart API Status: ${response.statusCode}');
      print('Add to Cart API Request Body: ${json.encode(body)}');
      print('Add to Cart API Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to add to cart: ${response.statusCode}');
        // Revert local changes if API fails
        await _loadCartFromPrefs();
        return false;
      }
    } catch (e) {
      print('Error adding to cart: $e');
      await _loadCartFromPrefs();
      return false;
    }
  }

  
  Future<bool> updateCartItem({
    required String restaurantId,
    required String itemId,
    required int quantity,
    required List<Map<String, String>> customizations,
  }) async {
    try {
      if (!_carts.containsKey(restaurantId)) return false;

      final existingItemIndex = _carts[restaurantId]!.indexWhere(
        (item) =>
            item.itemId == itemId &&
            _areCustomizationsEqual(item.customizations, customizations),
      );

      if (existingItemIndex == -1) return false;

      final itemData = _carts[restaurantId]![existingItemIndex].itemData;

      if (quantity <= 0) {
        _carts[restaurantId]!.removeAt(existingItemIndex);
      } else {
        _carts[restaurantId]![existingItemIndex] = CartItem(
          itemId: itemId,
          restaurantId: restaurantId,
          quantity: quantity,
          customizations: customizations,
          itemData: itemData,
        );
      }

      if (_carts[restaurantId]!.isEmpty) {
        _carts.remove(restaurantId);
        if (_currentRestaurantId == restaurantId) _currentRestaurantId = null;
      }

      await _saveCartToPrefs();

      if (_authToken == null) {
        print('No auth token found');
        return false;
      }

      final body = {
        'restaurant_id': restaurantId,
        'item_id': itemId,
        'quantity': quantity,
        'message': itemData['message'] ?? '',
        'customizations': customizations,
      };

      final response = await http.patch(
        Uri.parse('https://api.df.nguyenquangcuong.pro/cart/item'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('Update Cart API Status: ${response.statusCode}');
      print('Update Cart API Request Body: ${json.encode(body)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update cart: ${response.statusCode}');
        await _loadCartFromPrefs();
        return false;
      }
    } catch (e) {
      print('Error updating cart item: $e');
      await _loadCartFromPrefs();
      return false;
    }
  }

  Future<bool> clearCart(String restaurantId) async {
  try {
    if (_authToken == null) {
      print('No auth token found');
      return false;
    }

    final response = await http.delete(
      Uri.parse('https://api.df.nguyenquangcuong.pro/cart/items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode({'restaurantId': restaurantId}),
    ).timeout(const Duration(seconds: 10));

    print('Clear Cart API Status: ${response.statusCode}');
    print('Clear Cart API Response: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['statusCode'] == 200) {
        _carts.remove(restaurantId);
        if (_currentRestaurantId == restaurantId) {
          _currentRestaurantId = null;
        }
        await _saveCartToPrefs();
        return true;
      }
    }

    print('Failed to clear cart: ${response.statusCode}');
    await _loadCartFromPrefs();
    return false;
  } catch (e) {
    print('Error clearing cart: $e');
    await _loadCartFromPrefs();
    return false;
  }
}
  
  bool _areCustomizationsEqual(
      List<Map<String, String>> c1, List<Map<String, String>> c2) {
    if (c1.length != c2.length) return false;
    for (int i = 0; i < c1.length; i++) {
      if (c1[i]['option_id'] != c2[i]['option_id']) return false;
    }
    return true;
  }

  Map<String, List<CartItem>> getCarts() => _carts;

  String? getCurrentRestaurantId() => _currentRestaurantId;

  void updateCart(String restaurantId, List<CartItem> cartItems) {
    _carts[restaurantId] = cartItems;
    _currentRestaurantId = restaurantId;
    _saveCartToPrefs();
  }
}