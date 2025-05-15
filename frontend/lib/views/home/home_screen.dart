import 'package:flutter/material.dart';
import 'package:frontend/views/home/product_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:frontend/views/settings/menu.dart';
import 'package:frontend/views/settings/address_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


class RestaurantScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantScreen({super.key, required this.restaurantId});


  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Guest';
  String _userAddress = 'Loading address...';
  bool _isLoggedIn = false;
  final Set<String> _selectedCategories = {'ALL'};
  final List<dynamic> _shops = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _canFetch = true;
  late Future<List<String>> _categoriesFuture;

  // Constants for styling

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

    _categoriesFuture = _fetchCategories();
    _fetchShops();
    _scrollController.addListener(_onScroll);
    _checkLoginStatus();
    _fetchUserProfile();
    _fetchUserAddress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm lấy địa chỉ từ SharedPreferences
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

  // Hàm kiểm tra trạng thái đăng nhập
  Future<void> _checkLoginStatus() async {
    final accessToken = await _getAccessToken();
    setState(() {
      _isLoggedIn = accessToken != null;
    });
  }

  // Hàm lấy accessToken từ SharedPreferences
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Hàm tiện ích để viết hoa chữ cái đầu mỗi từ
  String capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text
        .split('-')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
        )
        .join(' ');
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

  Future<List<String>> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/restaurants/categories/'),
      );
      print('Categories API Status: ${response.statusCode}');
      print('Categories API Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categories =
            (jsonData['data']['categories'] as List)
                .map((category) => category['category_name'] as String)
                .map((category) => capitalizeEachWord(category))
                .toList();
        return ['ALL', ...categories];
      } else {
        throw Exception(
          'Failed to load categories: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Error fetching categories: $e');
    }

    _fetchRestaurantData();

  }

  Future<void> _fetchRestaurantData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoryQuery =
          _selectedCategories.isNotEmpty && !_selectedCategories.contains('ALL')
              ? '&category=${_selectedCategories.map((category) => category.toLowerCase().replaceAll(' ', '-')).join(',')}'
              : '';
      final uri = Uri.parse(
        'http://10.0.2.2:3000/restaurants?page=$_page&limit=10$categoryQuery',
      );
      print('Fetching shops with URL: $uri');
      final response = await http.get(uri).timeout(Duration(seconds: 10));

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


        List<dynamic> shopsList = [];
        final data = jsonData['data'];

        if (data is List) {
          shopsList = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final innerData = data['data'];
            if (innerData is List) {
              shopsList = innerData;
            } else if (innerData is Map<String, dynamic>) {
              if (innerData.containsKey('shops') &&
                  innerData['shops'] is List) {
                shopsList = innerData['shops'];
              } else if (innerData.containsKey('restaurants') &&
                  innerData['restaurants'] is List) {
                shopsList = innerData['restaurants'];
              } else {
                print('Available keys in data[\'data\']: ${innerData.keys}');
                throw Exception(
                  'Invalid API response: Expected a list of shops in data[\'data\'], got a Map with keys: ${innerData.keys}',
                );
              }
            } else {
              throw Exception(
                'Invalid API response: Expected a list or map in data[\'data\'], got ${innerData.runtimeType}',
              );
            }
          } else if (data.containsKey('shops') && data['shops'] is List) {
            shopsList = data['shops'];
          } else if (data.containsKey('restaurants') &&
              data['restaurants'] is List) {
            shopsList = data['restaurants'];
          } else {
            print('Available keys in data: ${data.keys}');
            throw Exception(
              'Invalid API response: Expected a list of shops, got a Map with keys: ${data.keys}',
            );
          }
        } else {
          throw Exception(
            'Invalid API response: Expected a list or map, got ${data.runtimeType}',
          );
        }

        print('Extracted shop data: $shopsList');
        if (shopsList.isNotEmpty) {
          setState(() {
            _shops.addAll(shopsList);
            _page++;
            _isLoading = false;
            print('Shops added: ${_shops.length}');
            if (shopsList.length < 10) {
              _hasMore = false;
            }
          });
        } else {
          print('No shops found in response');
          setState(() {
            _isLoading = false;
            _hasMore = false;
          });
          if (_shops.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No restaurants found for selected categories'),
              ),
            );
          }
        }
      } else {
        print('Request failed with status: ${response.statusCode}');


        setState(() {
          _restaurantData = jsonData['data'];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load restaurants: Status ${response.statusCode}',
            ),
          ),
        );

      } else {
        throw Exception('Failed to load restaurant: Status ${response.statusCode}');

      }
    } catch (e) {
      print('Error fetching restaurant with ID ${widget.restaurantId}: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load restaurant: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load restaurants: $e')));


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

                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < _shops.length) {
                        final shop = _shops[index];
                        print(
                          'Rendering shop: ${shop['shop_name']} with ID: ${shop['id']}',
                        );
                        return Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                          child: _buildRestaurantCard(
                            screenWidth,
                            screenHeight,
                            shop['shop_name'] ?? 'Unknown',
                            shop['shop_image'] ?? '',
                            shop,
                          ),
                        );
                      }
                      if (_isLoading && _shops.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      if (!_hasMore && _shops.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No restaurants found'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }, childCount: _shops.length + (_hasMore ? 1 : 0)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      backgroundColor: Colors.white.withOpacity(0.2),

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
                          // City
                          Text(
                            _restaurantData['city'] ?? 'Unknown City',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          // Rating and placeholders for delivery info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    _restaurantData['rating']?.toString() ?? 'N/A',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.delivery_dining, color: Colors.grey, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Free', // Placeholder
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '20 min', // Placeholder
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                                      backgroundColor: _selectedCategoryIndex == index
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
                                        color: _selectedCategoryIndex == index
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
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemCount: _restaurantData['menuCategories']
                                          [_selectedCategoryIndex]['items']
                                      .length,
                                  itemBuilder: (context, index) {
                                    final item = _restaurantData['menuCategories']
                                        [_selectedCategoryIndex]['items'][index];
                                    return _buildMenuItem(
                                      screenWidth,
                                      item,
                                      _restaurantData['name'] ?? 'Restaurant',
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


  Widget _buildRestaurantsSectionHeader() {
    return _buildSectionHeader('OPEN RESTAURANTS', 'SEE ALL');
  }

  Widget _buildHeader(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildCircularIcon(
              screenWidth,
              icon: Image.asset('assets/images/menu.png'),
            ),
            SizedBox(width: screenWidth * 0.02),
            GestureDetector(
              onTap: () {
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
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVER TO',
                    style: TextStyle(
                      fontSize: 12,
                      color: _primaryColor,
                      fontFamily: _fontFamily,
                    ),
                  ),
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.5,
                        ),
                        child: Text(
                          _isLoggedIn ? _userAddress : 'Not logged in',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: _fontFamily,
                            color: _textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (_isLoggedIn) _buildNotificationIcon(),
            if (!_isLoggedIn)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login').then((_) {
                    _checkLoginStatus();
                    _fetchUserProfile();
                    _fetchUserAddress();
                  });
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularIcon(double screenWidth, {required Widget icon}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const Menu(),
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

              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),

  Widget _buildMenuItem(
  double screenWidth,
  Map<String, dynamic> item, // Change to accept the full item object
  String restaurantName,
) {
  final name = item['product_name'] ?? 'Menu Item';
  final imageUrl = item['product_image']?.isNotEmpty == true
      ? item['product_image']
      : 'https://mms.img.susercontent.com/vn-11134259-7ra0g-m7dhzfyifri4bd@resize_ss280x175!@crop_w280_h175_cT';
  final price = _formatPrice(item['product_price'] ?? '0');
  final isAvailable = true; // Assume available as JSON doesn't provide this

  return GestureDetector(
    onTap: isAvailable
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  itemId: item['product_id'], // Use product_id from item
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

        ),
      ],
    );
  }

  Widget _buildGreeting(double screenWidth) {
    return Text(
      'Hey $_userName, Good Afternoon!',
      style: TextStyle(
        fontSize: screenWidth * 0.06,
        fontWeight: FontWeight.bold,
        fontFamily: _fontFamily,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search dishes, restaurants',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildCategoriesSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ALL CATEGORIES', 'SEE ALL'),
        SizedBox(height: screenHeight * 0.01),
        FutureBuilder<List<String>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to load categories: ${snapshot.error}',
                    ),
                  ),
                );
              });
              return const Center(child: Text('Failed to load categories'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No categories available'));
            }

            final categories = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    categories.map<Widget>((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.02),
                        child: _buildCategoryChip(
                          category,
                          screenWidth,
                          screenHeight,
                        ),
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
        TextButton(onPressed: () {}, child: Text(actionText)),
      ],
    );
  }

  Widget _buildCategoryChip(
    String label,
    double screenWidth,
    double screenHeight,
  ) {
    final isSelected = _selectedCategories.contains(label);
    final imagePath = _getImagePathForCategory(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'ALL') {
            _selectedCategories.clear();
            _selectedCategories.add('ALL');
          } else {
            _selectedCategories.remove('ALL');
            if (isSelected) {
              _selectedCategories.remove(label);
              if (_selectedCategories.isEmpty) {
                _selectedCategories.add('ALL');
              }
            } else {
              _selectedCategories.add(label);
            }
          }

          print('Selected categories: $_selectedCategories');
          _shops.clear();
          _page = 1;
          _hasMore = true;
          _isLoading = false;
          print('Calling _fetchShops from category chip');
          _fetchShops();
        });
      },
      child: Container(
        padding: _chipPadding,
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : Colors.grey[300],
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: screenWidth * 0.05,
              backgroundColor: Colors.grey[400],
              backgroundImage: AssetImage(imagePath),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[600],
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImagePathForCategory(String label) {
    switch (label.toLowerCase()) {
      case 'cake pastry':
        return 'assets/images/cake_pastry.png';
      case 'vegetarian':
        return 'assets/images/vegetarian.png';
      case 'drink':
        return 'assets/images/drink.png';
      case 'hotpot':
        return 'assets/images/hotpot.png';
      case 'food':
        return 'assets/images/food.png';
      case 'all':
        return 'assets/images/all_categories.png';
      default:
        return 'assets/images/default_category.png';
    }
  }

  Widget _buildRestaurantCard(
    double screenWidth,
    double screenHeight,
    String shopName,
    String shopImage,
    dynamic shop,
  ) {
    final restaurantId = shop['shop_id']?.toString();
    if (restaurantId == null) {
      print('Warning: No ID found for shop: $shopName');
    } else {
      print('Navigating to RestaurantScreen with ID: $restaurantId');
    }

    return GestureDetector(
      onTap:
          restaurantId != null
              ? () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            RestaurantScreen(restaurantId: restaurantId),
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
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              }
              : null,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenHeight * 0.15,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                image: DecorationImage(
                  image:
                      shopImage.isNotEmpty
                          ? NetworkImage(shopImage)
                          : const AssetImage('assets/images/default_shop.png')
                              as ImageProvider,
                  fit: BoxFit.cover,

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

    ),
  );
}
}

