import 'package:flutter/material.dart';
import 'package:frontend/views/home/product_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RestaurantScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  static const _primaryColor = Color(0xFFFC6E2A);
  static const _fontFamily = 'San Francisco';
  dynamic _restaurantData;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

      final response = await http.get(
        Uri.parse('https://api.df.nguyenquangcuong.pro/restaurants/${widget.restaurantId}'),
      ).timeout(const Duration(seconds: 10));


      print(
        'Restaurant API Status for ID ${widget.restaurantId}: ${response.statusCode}',
      );
      print('Restaurant API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] == null) {
          throw Exception('Invalid API response: "data" field is missing');
        }
        print(jsonData['data']);
        setState(() {
          _restaurantData = jsonData['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load restaurant: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching restaurant with ID ${widget.restaurantId}: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load restaurant: $e';
      });
    }
  }

  String _formatPrice(String price) {
    try {
      final number = int.parse(price);
      return '${(number ~/ 1000)}.${number % 1000 == 0 ? '000' : (number % 1000).toString().padLeft(3, '0')}₫';
    } catch (e) {
      return '$price₫';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        bottom: false,
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
                        onPressed: _fetchRestaurantData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button and more options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                _restaurantData['name'] ?? 'Restaurant',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: _fontFamily,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                // Implement more options functionality
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Image banner
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _restaurantData['shop_image_url']?.isNotEmpty ==
                                    true
                                ? _restaurantData['shop_image_url']
                                : 'https://mms.img.susercontent.com/vn-11134259-7ra0g-m7dhzfyifri4bd@resize_ss280x175!@crop_w280_h175_cT',
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                                  'assets/images/default_shop.png',
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Restaurant name
                        Text(
                          _restaurantData['name'] ?? 'Restaurant',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: _fontFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // City
                        Text(
                          _restaurantData['city'] ?? 'Unknown City',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Rating and placeholders for delivery info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _restaurantData['rating']?.toString() ??
                                      'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.delivery_dining,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Free', // Placeholder
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '20 min', // Placeholder
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Category Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              _restaurantData['menuCategories']?.length ?? 0,
                              (index) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategoryIndex = index;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _selectedCategoryIndex == index
                                            ? _primaryColor
                                            : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    _restaurantData['menuCategories'][index]['category_name'] ??
                                        'Category',
                                    style: TextStyle(
                                      color:
                                          _selectedCategoryIndex == index
                                              ? Colors.white
                                              : Colors.black,
                                      fontFamily: _fontFamily,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Menu Section Title
                        Text(
                          "${_restaurantData['menuCategories']?[_selectedCategoryIndex]['category_name'] ?? 'Menu'} (${_restaurantData['menuCategories']?[_selectedCategoryIndex]['items']?.length ?? 0})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: _fontFamily,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Menu Items
                        _restaurantData['menuCategories']?[_selectedCategoryIndex]['items']
                                    ?.isNotEmpty ==
                                true
                            ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount:
                                  _restaurantData['menuCategories'][_selectedCategoryIndex]['items']
                                      .length,
                              itemBuilder: (context, index) {
                                final item =
                                    _restaurantData['menuCategories'][_selectedCategoryIndex]['items'][index];
                                return _buildMenuItem(
                                  screenWidth,
                                  item,
                                  _restaurantData['name'] ?? 'Restaurant',
                                );
                              },
                            )
                            : const Text(
                              'No menu items available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildMenuItem(
    double screenWidth,
    Map<String, dynamic> item, // Change to accept the full item object
    String restaurantName,
  ) {
    final name = item['product_name'] ?? 'Menu Item';
    final imageUrl =
        item['product_image']?.isNotEmpty == true
            ? item['product_image']
            : 'https://mms.img.susercontent.com/vn-11134259-7ra0g-m7dhzfyifri4bd@resize_ss280x175!@crop_w280_h175_cT';
    final price = _formatPrice(item['product_price'] ?? '0');
    final isAvailable = true; // Assume available as JSON doesn't provide this

    return GestureDetector(
      onTap:
          isAvailable
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProductDetailsScreen(
                          itemId:
                              item['product_id'], // Use product_id from item
                          restaurantId: _restaurantData['restaurant_id'],
                        ),
                  ),
                );
              }
              : null,
      child: SizedBox(
        width: (screenWidth - 48) / 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Image.asset(
                          'assets/images/default_shop.png',
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                  ),
                ),
                if (!isAvailable)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Text(
                          'Unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: _fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: _fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              restaurantName,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: _fontFamily,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: _primaryColor,
                    size: 30,
                  ),
                  onPressed:
                      isAvailable
                          ? () {
                            // Implement add to cart functionality
                          }
                          : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
