import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/views/restaurants/restaurant_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final double latitude;
  final double longitude;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _openRestaurants = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  late double _latitude;
  late double _longitude;
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  bool _canFetch = true;
  int _page = 1;
  int _limit = 15;

  // Biến lưu các giá trị lọc
  double _minRating = 1.0;
  double _searchRadius = 5000.0;
  double _minPrice = 0.0;
  double _maxPrice = 1000000.0;
  final TextEditingController _radiusController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _searchNearYou = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _latitude = widget.latitude;
    _longitude = widget.longitude;
    _radiusController.text = _searchRadius.toStringAsFixed(0);
    _minPriceController.text = _minPrice.toStringAsFixed(0);
    _maxPriceController.text = _maxPrice.toStringAsFixed(0);
    print('Received location in SearchResultsScreen:');
    print('Latitude: $_latitude');
    print('Longitude: $_longitude');
    _scrollController.addListener(_onScroll);
    _fetchRestaurants(widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _radiusController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm tính khoảng cách sử dụng Geolocator
  Future<double> calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) async {
    return await Geolocator.distanceBetween(
          startLat,
          startLon,
          endLat,
          endLon,
        ) /
        1000; // Trả về km
  }

  // Hàm gọi API để tìm kiếm nhà hàng
  Future<void> _fetchRestaurants(String query) async {
    if (query.isEmpty || _isLoading || !_hasMore) {
      print(
        'Blocked _fetchRestaurants: query=$query, isLoading=$_isLoading, hasMore=$_hasMore',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/search?'
          'latitude=$_latitude&'
          'longitude=$_longitude&'
          'query=$query&'
          'page=$_page&'
          'limit=$_limit&'
          'minRating=${_minRating.toStringAsFixed(1)}&'
          'radius=${_searchRadius.toStringAsFixed(1)}&'
          'minPrice=${_minPrice.toStringAsFixed(0)}&'
          'maxPrice=${_maxPrice.toStringAsFixed(0)}&'
          'nearMe=$_searchNearYou',
        ),
      );

      print('Search API Status: ${response.statusCode}');
      print('Search API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> restaurants =
            jsonData['data']['restaurants']['data'] ?? [];

        List<Map<String, dynamic>> newRestaurants = [];
        for (var restaurant in restaurants) {
          double endLat =
              restaurant['latitude'] is String
                  ? double.parse(restaurant['latitude'])
                  : (restaurant['latitude']?.toDouble() ?? 0.0);
          double endLon =
              restaurant['longitude'] is String
                  ? double.parse(restaurant['longitude'])
                  : (restaurant['longitude']?.toDouble() ?? 0.0);

          double distance = await calculateDistance(
            _latitude,
            _longitude,
            endLat,
            endLon,
          );
          newRestaurants.add({
            'restaurant_id': restaurant['restaurant_id']?.toString(),
            'name': restaurant['name'] ?? 'Unknown',
            'rating': restaurant['rating']?.toDouble() ?? 0.0,
            'distance': distance.toStringAsFixed(2),
            'deliveryTime': restaurant['delivery_time']?.toString() ?? '30',
            'image': restaurant['shop_image_url'] ?? '',
          });
        }

        setState(() {
          _openRestaurants.addAll(newRestaurants);
          _page++;
          _isLoading = false;
          if (newRestaurants.length < _limit) {
            _hasMore = false;
          }
        });

        if (_openRestaurants.isEmpty && !_isLoading) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No restaurants found')));
        }
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm xử lý cuộn để tải thêm dữ liệu
  void _onScroll() {
    if (_canFetch &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _canFetch = false;
      print('Scroll triggered _fetchRestaurants');
      _fetchRestaurants(_searchController.text).then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _canFetch = true;
        });
      });
    }
  }

  // Hàm debounce cho tìm kiếm
  void _debounceSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _openRestaurants.clear();
        _page = 1;
        _hasMore = true;
      });
      _fetchRestaurants(query);
    });
  }

  // Hàm hiển thị dialog lọc
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Filter Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: _minRating,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4,
                      label: _minRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _minRating = value;
                        });
                      },
                    ),
                    Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
                    TextField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Search Radius (meters)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = double.tryParse(value) ?? 5000.0;
                          _radiusController.text = _searchRadius
                              .toStringAsFixed(0);
                          _radiusController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _radiusController.text.length),
                          );
                        });
                      },
                    ),
                    TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Price (VND)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _minPrice = double.tryParse(value) ?? 0.0;
                          _minPriceController.text = _minPrice.toStringAsFixed(
                            0,
                          );
                          _minPriceController
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _minPriceController.text.length,
                            ),
                          );
                        });
                      },
                    ),
                    TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Price (VND)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _maxPrice = double.tryParse(value) ?? 1000000.0;
                          _maxPriceController.text = _maxPrice.toStringAsFixed(
                            0,
                          );
                          _maxPriceController
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _maxPriceController.text.length,
                            ),
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Search Near You'),
                      value: _searchNearYou,
                      onChanged: (value) {
                        setState(() {
                          _searchNearYou = value;
                          _searchRadius = value ? 1000.0 : 5000.0;
                          _radiusController.text = _searchRadius
                              .toStringAsFixed(0);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _openRestaurants.clear();
                      _page = 1;
                      _hasMore = true;
                    });
                    _fetchRestaurants(_searchController.text);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            padding: const EdgeInsets.all(8.0),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          _searchController.clear();
                          _debounceSearch('');
                        },
                      )
                      : null,
            ),
            style: const TextStyle(color: Colors.black, fontSize: 16),
            onChanged: (value) {
              _debounceSearch(value);
            },
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/filter.png',
              width: 28,
              height: 28,
            ),
            onPressed: _showFilterDialog,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.orange,
                  child: const Text(
                    '2',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < _openRestaurants.length) {
                    final restaurant = _openRestaurants[index];
                    final restaurantId = restaurant['restaurant_id'];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: GestureDetector(
                        onTap:
                            restaurantId != null
                                ? () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => RestaurantScreen(
                                            restaurantId: restaurantId,
                                          ),
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
                                        var offsetAnimation = animation.drive(
                                          tween,
                                        );
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                    ),
                                  );
                                }
                                : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Invalid restaurant ID for ${restaurant['name']}',
                                      ),
                                    ),
                                  );
                                },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 150,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child:
                                    restaurant['image'].isNotEmpty
                                        ? ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Image.network(
                                            restaurant['image'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 150,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Image.asset(
                                                'assets/images/default_shop.png',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 150,
                                              );
                                            },
                                          ),
                                        )
                                        : Image.asset(
                                          'assets/images/default_shop.png',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 150,
                                        ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        Text(
                                          restaurant['rating'].toString(),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          '${restaurant['distance']} km',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        Text(
                                          '${restaurant['deliveryTime']} min',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
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
                  if (_isLoading && _openRestaurants.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!_hasMore && _openRestaurants.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No restaurants found')),
                    );
                  }
                  return const SizedBox.shrink();
                }, childCount: _openRestaurants.length + (_hasMore ? 1 : 0)),
              ),
            ],
          ),
          if (_isLoading && _openRestaurants.isEmpty)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
