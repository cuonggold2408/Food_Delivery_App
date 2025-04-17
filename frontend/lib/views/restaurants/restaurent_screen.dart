import 'package:flutter/material.dart';
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
        Uri.parse('http://10.0.2.2:3000/restaurants/${widget.restaurantId}'),
      ).timeout(const Duration(seconds: 10));

      print('Restaurant API Status for ID ${widget.restaurantId}: ${response.statusCode}');
      print('Restaurant API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] == null) {
          throw Exception('Invalid API response: "data" field is missing');
        }
        setState(() {
          _restaurantData = jsonData['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load restaurant: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurant with ID ${widget.restaurantId}: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load restaurant: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: _isLoading
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
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                                icon: const Icon(Icons.more_horiz, color: Colors.black),
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
                              _restaurantData['shop_image_url']?.isNotEmpty == true
                                  ? _restaurantData['shop_image_url']
                                  : 'https://mms.img.susercontent.com/vn-11134259-7ra0g-m7dhzfyifri4bd@resize_ss280x175!@crop_w280_h175_cT',
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
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
                          // Address
                          Text(
                            '${_restaurantData['street_address'] ?? 'Unknown Address'}, ${_restaurantData['city'] ?? 'Unknown City'}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          // Description
                          Text(
                            _restaurantData['product_desc']?.isNotEmpty == true
                                ? _restaurantData['product_desc']
                                : 'No description available.',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          // Rating, Delivery Info, and Time (placeholders as API doesn't provide)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.7', // API doesn't provide rating
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.delivery_dining, color: Colors.grey, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Free', // API doesn't provide delivery fee
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '20 min', // API doesn't provide delivery time
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Tabs (hardcoded as API doesn't provide categories)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Menu",
                                  style: TextStyle(color: Colors.white, fontFamily: _fontFamily),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Sandwich",
                                  style: TextStyle(color: Colors.black, fontFamily: _fontFamily),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Pizza",
                                  style: TextStyle(color: Colors.black, fontFamily: _fontFamily),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Sanwii",
                                  style: TextStyle(color: Colors.black, fontFamily: _fontFamily),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Menu Section Title
                          Text(
                            "Menu (${_restaurantData['menuItems']?.length ?? 0})",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: _fontFamily,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Menu Items
                          _restaurantData['menuItems']?.isNotEmpty == true
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemCount: _restaurantData['menuItems'].length,
                                  itemBuilder: (context, index) {
                                    final item = _restaurantData['menuItems'][index];
                                    return _buildMenuItem(
                                      screenWidth,
                                      item['product_name'] ?? 'Menu Item',
                                      item['product_image']?.isNotEmpty == true
                                          ? item['product_image']
                                          : 'https://mms.img.susercontent.com/vn-11134259-7ra0g-m7dhzfyifri4bd@resize_ss280x175!@crop_w280_h175_cT',
                                      _restaurantData['name'] ?? 'Restaurant',
                                      item['product_price'] ?? '0đ',
                                      item['product_is_available'] == true,
                                    );
                                  },
                                )
                              : const Text(
                                  'No menu items available',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
    String name,
    String imageUrl,
    String restaurantName,
    String price,
    bool isAvailable,
  ) {
    return SizedBox(
      width: (screenWidth - 48) / 2, // Adjust for padding and spacing
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
                  errorBuilder: (context, error, stackTrace) => Image.asset(
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
                icon: const Icon(Icons.add_circle, color: _primaryColor, size: 30),
                onPressed: isAvailable
                    ? () {
                        // Implement add to cart functionality
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}