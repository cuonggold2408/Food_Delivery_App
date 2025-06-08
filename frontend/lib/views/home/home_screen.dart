import 'package:flutter/material.dart';
import 'package:frontend/views/restaurants/restaurant_screen.dart';
import 'package:frontend/views/settings/address_screen.dart' as address_screen;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/views/settings/menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/views/settings/menu.dart';
import 'package:frontend/views/settings/add_address.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Guest';
  bool _isLoggedIn = false;
  final Set<String> _selectedCategories = {'ALL'};
  final List<dynamic> _shops = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _canFetch = true;
  late Future<List<String>> _categoriesFuture;
  final int _cartItemCount = 2;

  static const _primaryColor = Color(0xFFFC6E2A);
  static const _textColor = Color(0xFF676767);
  static const _fontFamily = 'San Francisco';
  static const _chipPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  static const _defaultChipColor = Color(0xFFECF0F4);

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
    _fetchShops();
    _scrollController.addListener(_onScroll);
    _checkLoginStatus();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _checkLoginStatus() async {
    final accessToken = await _getAccessToken();
    setState(() {
      _isLoggedIn = accessToken != null;
    });
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  String capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text
        .split('-')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
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
        Uri.parse('https://api.df.nguyenquangcuong.pro/user/profile'),
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
          SnackBar(content: Text('Failed to load profile: Status ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
    }
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/restaurants/categories/',
        ),
      );
      print('Categories API Status: ${response.statusCode}');
      print('Categories API Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categories = (jsonData['data']['categories'] as List)
            .map((category) => category['category_name'] as String)
            .map((category) => capitalizeEachWord(category))
            .toList();
        return ['ALL', ...categories];
      } else {
        throw Exception('Failed to load categories: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<void> _fetchShops() async {
    print('Starting _fetchShops with categories: $_selectedCategories');
    if (_isLoading || !_hasMore) {
      print('Blocked _fetchShops: isLoading=$_isLoading, hasMore=$_hasMore');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryQuery = _selectedCategories.isNotEmpty &&
              !_selectedCategories.contains('ALL')
          ? '&category=${_selectedCategories.map((category) => category.toLowerCase().replaceAll(' ', '-')).join(',')}'
          : '';
      final uri = Uri.parse(
        'https://api.df.nguyenquangcuong.pro/restaurants?page=$_page&limit=10$categoryQuery&latitude=21.0278&longitude=105.8342',
      );
      print('Fetching shops with URL: $uri');
      final response = await http.get(uri).timeout(Duration(seconds: 10));

      print('Shops API Status: ${response.statusCode}');
      print('Shops API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Parsed JSON data: $jsonData');

        if (jsonData['data'] == null || jsonData['data']['data'] == null) {
          throw Exception(
            'Invalid API response: "data" or "data.data" field is missing',
          );
          throw Exception('Invalid API response: "data" or "data.data" field is missing');
        }

        List<dynamic> shopsList = jsonData['data']['data'];
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
              SnackBar(content: Text('No restaurants found for selected categories')),
            );
          }
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurants: Status ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching shops: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load restaurants: $e')));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load restaurants: $e')),
      );
    }
  }

  void _onScroll() {
    if (_canFetch &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _canFetch = false;
      print('Scroll triggered _fetchShops');
      _fetchShops().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _canFetch = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(screenWidth),
                        SizedBox(height: screenHeight * 0.02),
                        _buildGreeting(screenWidth),
                        SizedBox(height: screenHeight * 0.02),
                        _buildSearchBar(),
                        SizedBox(height: screenHeight * 0.02),
                        _buildCategoriesSection(screenWidth, screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        _buildRestaurantsSectionHeader(),
                        SizedBox(height: screenHeight * 0.01),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < _shops.length) {
                        final shop = _shops[index];
                        print(
                          'Rendering shop: ${shop['name']} with ID: ${shop['restaurant_id']}',
                        );
                        return Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                          child: _buildRestaurantCard(
                            screenWidth,
                            screenHeight,
                            shop['name'] ?? 'Unknown',
                            shop['shop_image_url'] ?? '',
                            shop,
                          ),
                        );
                      }
                      if (_isLoading && _shops.isNotEmpty) {
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _shops.length) {
                          final shop = _shops[index];
                          print('Rendering shop: ${shop['name']} with ID: ${shop['restaurant_id']}');
                          return Padding(
                            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                            child: _buildRestaurantCard(
                              screenWidth,
                              screenHeight,
                              shop['name'] ?? 'Unknown',
                              shop['shop_image_url'] ?? '',
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
                      },
                      childCount: _shops.length + (_hasMore ? 1 : 0),
                    ),
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
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                if (!_isLoggedIn) {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
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
                                Navigator.pushNamed(context, '/login').then((
                                  _,
                                ) {
                                  _checkLoginStatus();
                                  _fetchUserProfile();
                                  _fetchUserAddress();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
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
                  if (_userAddress == 'Unknown location' ||
                      _userAddress == 'Failed to load address') {
                    Navigator.pushNamed(context, '/location');
                  } else {
                    Navigator.push(
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AddAddressScreen(),
                    transitionsBuilder: (
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const address_screen.AddressesScreen(),
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
                    ).then((result) {
                      if (result != null && result is address_screen.Address) {
                        setState(() {
                          _userAddress = result.addressName;
                        });
                        _shops.clear();
                        _page = 1;
                        _hasMore = true;
                        _fetchShops();
                      }
                    });
                  }
                }
              },
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                          _userAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: _fontFamily,
                            color: _textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                      Text(
                        'Halal Lab office',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: _fontFamily,
                          color: _textColor,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (!_isLoggedIn)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login').then((_) {
                    _checkLoginStatus();
                    _fetchUserProfile();
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
            SizedBox(width: screenWidth * 0.02),
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/draft');
                  },
                  icon: Icon(
                    Icons.shopping_cart,
                    size: 28,
                    color: _primaryColor,
                  ),
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
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
            pageBuilder: (context, animation, secondaryAnimation) => const Menu(),
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
          ),
        ).then((result) {
          if (result != null && result is address_screen.Address) {
            setState(() {
              _userAddress = result.addressName;
            });
            _shops.clear();
            _page = 1;
            _hasMore = true;
            _fetchShops();
          }
        });
      },
      borderRadius: BorderRadius.circular(screenWidth * 0.06),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.06),
        child: Container(
          color: _defaultChipColor,
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          child: icon,
        ),
      ),
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
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/search');
      },
      child: AbsorbPointer(
        child: TextField(
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
        ),
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
                  SnackBar(content: Text('Failed to load categories: ${snapshot.error}')),
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
                children: categories.map<Widget>((category) {
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
    final restaurantId = shop['restaurant_id']?.toString();
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
      onTap: restaurantId != null
          ? () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
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
                  image: shopImage.isNotEmpty
                      ? NetworkImage(shopImage)
                      : const AssetImage('assets/images/default_shop.png')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: _fontFamily,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Beverages • Snacks', // Có thể thay bằng category từ API nếu cần
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  _buildRestaurantInfoRow(
                    screenWidth,
                    shop['rating']?.toString() ?? '0.0',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoRow(double screenWidth, String rating) {
    return Row(
      children: [
        _buildInfoItem(Icons.star, rating, screenWidth, color: Colors.orange),
        _buildInfoItem(Icons.local_shipping, 'Free', screenWidth),
        _buildInfoItem(
          Icons.timer,
          '20 min',
          screenWidth,
          color: Colors.orange,
        ),
      ],
    );
  }

                  _buildRestaurantInfoRow(screenWidth, shop['rating']?.toString() ?? '0.0'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoRow(double screenWidth, String rating) {
    return Row(
      children: [
        _buildInfoItem(Icons.star, rating, screenWidth, color: Colors.orange),
        _buildInfoItem(Icons.local_shipping, 'Free', screenWidth),
        _buildInfoItem(
          Icons.timer,
          '20 min',
          screenWidth,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String text,
    double screenWidth, {
    Color? color,
  }) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: screenWidth * 0.01),
          Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
