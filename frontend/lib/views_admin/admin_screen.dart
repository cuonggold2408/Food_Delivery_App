import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_restaurant.dart'; // Giả sử file này tồn tại
import 'menu_food.dart'; // Giả sử file này tồn tại
import 'user_list_screen.dart';
import 'package:frontend/views_admin/dashboard.dart';

// Định nghĩa các hằng số màu và font toàn cục
const _primaryColor = Color(0xFFFC6E2A);
const _textColor = Color(0xFF676767);
const _fontFamily = 'Montserrat';
const goongApiKey = 'HnbVVYEre497owDt61e9wK2sFsvMLDWzXVx8QFA0';

// Định nghĩa lớp GoongPlace để lưu trữ thông tin gợi ý địa chỉ
class GoongPlace {
  final String description;
  final String placeId;

  GoongPlace({required this.description, required this.placeId});

  factory GoongPlace.fromJson(Map<String, dynamic> json) {
    return GoongPlace(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
    );
  }
}

// Hàm lấy chi tiết địa chỉ từ Goong Place Detail API
Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
  final url = Uri.parse(
    'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=$goongApiKey',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') {
        throw Exception(
          'Goong API error: ${data['error_message'] ?? 'Unknown'}',
        );
      }
      final result = data['result'];
      final geometry = result['geometry']['location'];
      return {'latitude': geometry['lat'], 'longitude': geometry['lng']};
    } else {
      print('Goong Place Detail API error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching Goong place details: $e');
    return null;
  }
}

// Hàm lấy địa chỉ từ tọa độ (reverse geocoding) sử dụng Goong Geocode API
Future<String?> getAddressFromCoordinates(
  double latitude,
  double longitude,
) async {
  final url = Uri.parse(
    'https://rsapi.goong.io/Geocode?latlng=$latitude,$longitude&api_key=$goongApiKey',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') {
        throw Exception(
          'Goong Geocode API error: ${data['error_message'] ?? 'Unknown'}',
        );
      }
      if (data['results'] != null && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'] ?? '';
      }
      return null;
    } else {
      print('Goong Geocode API error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching address from coordinates: $e');
    return null;
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final List<dynamic> _restaurants = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _canFetch = true;
  String _adminName = 'Admin';
  bool _isDeleting = false;
  int _selectedIndex = 0; // To track the selected bottom navigation item

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    _scrollController.addListener(_onScroll);
    _fetchAdminProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? adminName = prefs.getString('admin_name');
      setState(() {
        _adminName = adminName ?? 'Admin';
      });
    } catch (e) {
      print('Lỗi khi lấy thông tin admin: $e');
    }
  }

  Future<void> _fetchRestaurants() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(
        'https://api.df.nguyenquangcuong.pro/admin/restaurants?page=$_page&limit=10',
      );
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] == null ||
            jsonData['data']['restaurants'] == null) {
          throw Exception('Phản hồi API không hợp lệ');
        }

        List<dynamic> restaurantsList = jsonData['data']['restaurants'];
        if (restaurantsList.isNotEmpty) {
          setState(() {
            _restaurants.addAll(restaurantsList);
            _page++;
            _isLoading = false;
            if (restaurantsList.length < 10) {
              _hasMore = false;
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasMore = false;
          });
          if (_restaurants.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy nhà hàng nào')),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tải danh sách thất bại: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách: $e')));
    }
  }

  Future<void> _deleteRestaurant(String restaurantId) async {
    if (restaurantId.isEmpty) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.delete(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/$restaurantId',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _restaurants.removeWhere(
            (restaurant) => restaurant['restaurant_id'] == restaurantId,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa nhà hàng thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thất bại: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi xóa nhà hàng: $e')));
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _onScroll() {
    if (_canFetch &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _canFetch = false;
      _fetchRestaurants().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _canFetch = true;
        });
      });
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Restaurants (current screen, no navigation needed)
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserListScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRestaurantScreen()),
        ).then((value) {
          if (value == true) {
            setState(() {
              _restaurants.clear();
              _page = 1;
              _hasMore = true;
              _fetchRestaurants();
            });
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nhà hàng - $_adminName'),
        backgroundColor: _primaryColor,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nhà hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Thêm quán'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _restaurants.clear();
            _page = 1;
            _hasMore = true;
            _isLoading = false;
          });
          await _fetchRestaurants();
        },
        child: Stack(
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
                          SizedBox(height: screenHeight * 0.02),
                          _buildSectionHeader('Danh sách nhà hàng'),
                          SizedBox(height: screenHeight * 0.01),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (_restaurants.isEmpty && _isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (index < _restaurants.length) {
                          final restaurant = _restaurants[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: screenHeight * 0.02,
                            ),
                            child: _buildRestaurantCard(
                              screenWidth,
                              screenHeight,
                              restaurant['name'] ?? 'Không rõ tên',
                              restaurant['shop_image_url'] ?? '',
                              restaurant,
                            ),
                          );
                        }
                        if (!_hasMore && _restaurants.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Không tìm thấy nhà hàng nào'),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }, childCount: _restaurants.length + (_hasMore ? 1 : 0)),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading && _restaurants.isNotEmpty)
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isDeleting)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: _fontFamily,
      ),
    );
  }

  Widget _buildRestaurantCard(
    double screenWidth,
    double screenHeight,
    String restaurantName,
    String shopImage,
    dynamic restaurant,
  ) {
    final restaurantId = restaurant['restaurant_id'];
    final isActive = restaurant['is_active'] ?? false;
    final city = restaurant['city'] ?? 'Không rõ thành phố';
    final createdAt =
        restaurant['created_at'] != null
            ? DateTime.parse(
              restaurant['created_at'],
            ).toLocal().toString().split(' ')[0]
            : 'Không rõ';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodListScreen(restaurantId: restaurantId),
          ),
        );
      },
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
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurantName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: _fontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Hoạt động' : 'Không hoạt động',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: isActive ? Colors.green : Colors.red,
                            fontFamily: _fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '$city • Tạo ngày: $createdAt',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  _buildRestaurantInfoRow(
                    screenWidth,
                    restaurant['rating']?.toString() ?? '0.0',
                    restaurantId,
                    restaurantName,
                    restaurant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoRow(
    double screenWidth,
    String rating,
    String? restaurantId,
    String restaurantName,
    dynamic restaurant,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildInfoItem(
              Icons.star,
              rating,
              screenWidth,
              color: Colors.orange,
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: _primaryColor, size: 20),
              onPressed:
                  restaurantId != null
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditRestaurantScreen(
                                  restaurant: restaurant,
                                ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            setState(() {
                              _restaurants.clear();
                              _page = 1;
                              _hasMore = true;
                              _fetchRestaurants();
                            });
                          }
                        });
                      }
                      : null,
              tooltip: 'Chỉnh sửa nhà hàng',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed:
                  restaurantId != null
                      ? () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: Text(
                                  'Bạn có chắc muốn xóa nhà hàng "$restaurantName"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteRestaurant(restaurantId);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      }
                      : null,
              tooltip: 'Xóa nhà hàng',
            ),
          ],
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
    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.04),
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

class EditRestaurantScreen extends StatefulWidget {
  final dynamic restaurant;

  const EditRestaurantScreen({super.key, required this.restaurant});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  static const _primaryColor = Color(0xFFFC6E2A);
  static const _textColor = Color(0xFF676767);
  static const _fontFamily = 'Montserrat';
  static const _spacing = 16.0;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtr;
  late TextEditingController _cityCtr;
  late TextEditingController _addressCtr;
  File? _selectedImage;
  String? _fileName;
  String? _fileExt;
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  bool _isActive = true;

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('access_token');

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _textColor),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _primaryColor),
      borderRadius: BorderRadius.circular(10),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;

    _fileName = p.basename(img.path);
    _fileExt = p.extension(img.path).replaceFirst('.', '').toLowerCase();

    setState(() => _selectedImage = File(img.path));
  }

  Future<Map<String, String>> _createPresignedUrl() async {
    final tkn = await _token();
    if (tkn == null) throw Exception('No access token');

    final res = await http.post(
      Uri.parse(
        'https://api.df.nguyenquangcuong.pro/media/images/upload/presigned-url',
      ),
      headers: {
        'Authorization': 'Bearer $tkn',
        'Content-Type': 'application/json',
      },
      body: json.encode({'fileName': _fileName}),
    );

    if (res.statusCode != 201) {
      throw Exception('Presigned-URL error ${res.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(res.body);
    final Map<String, dynamic> inner = body['data'] as Map<String, dynamic>;

    final String uploadUrl = inner['presignedUrl'] as String;
    final String publicUrl = inner['url'] as String;

    return {'upload_url': uploadUrl, 'public_url': publicUrl};
  }

  Future<String?> _uploadImageToS3() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploading = true);

    try {
      final presigned = await _createPresignedUrl();
      final putUrl = presigned['upload_url']!;
      final publicUrl = presigned['public_url']!;
      final bytes = await _selectedImage!.readAsBytes();
      final mimeType =
          lookupMimeType(_selectedImage!.path) ?? 'application/octet-stream';

      final res = await http.put(
        Uri.parse(putUrl),
        headers: {'Content-Type': mimeType},
        body: bytes,
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return publicUrl;
      }
      throw Exception('S3 upload fail ${res.statusCode}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _fetchInitialAddressAndCoords() async {
    if (_latitude != null && _longitude != null && _addressCtr.text.isEmpty) {
      final address = await getAddressFromCoordinates(_latitude!, _longitude!);
      if (address != null && mounted) {
        setState(() {
          _addressCtr.text = address;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy địa chỉ từ tọa độ')),
        );
      }
    } else if (_addressCtr.text.isNotEmpty &&
        (_latitude == null || _longitude == null)) {
      try {
        final response = await http.get(
          Uri.parse(
            'https://rsapi.goong.io/Place/AutoComplete?input=${Uri.encodeComponent(_addressCtr.text)}&location=21.0285,105.8542&api_key=$goongApiKey',
          ),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] != 'OK') {
            throw Exception(
              'Goong API error: ${data['error_message'] ?? 'Unknown'}',
            );
          }
          if (data['predictions'] != null && data['predictions'].isNotEmpty) {
            final placeId = data['predictions'][0]['place_id'];
            final coords = await getPlaceDetails(placeId);
            if (coords != null && mounted) {
              setState(() {
                _latitude = coords['latitude'];
                _longitude = coords['longitude'];
              });
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi lấy tọa độ từ địa chỉ cũ: $e')),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.restaurant['name'] ?? '');
    _cityCtr = TextEditingController(text: widget.restaurant['city'] ?? '');
    _addressCtr = TextEditingController(
      text: widget.restaurant['address'] ?? '',
    );
    _latitude = double.tryParse(
      widget.restaurant['latitude']?.toString() ?? '',
    );
    _longitude = double.tryParse(
      widget.restaurant['longitude']?.toString() ?? '',
    );
    _isActive = widget.restaurant['is_active'] ?? true;
    if (widget.restaurant['shop_image_url'] != null &&
        widget.restaurant['shop_image_url'].isNotEmpty) {
      _fileName = p.basename(widget.restaurant['shop_image_url']);
      _fileExt =
          p
              .extension(widget.restaurant['shop_image_url'])
              .replaceFirst('.', '')
              .toLowerCase();
    }
    _fetchInitialAddressAndCoords();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_addressCtr.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa chỉ')));
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn một địa chỉ từ gợi ý hoặc đảm bảo tọa độ hợp lệ',
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imgUrl = await _uploadImageToS3();
      final tkn = await _token();
      if (tkn == null) throw Exception('No access token');

      final body = json.encode({
        'name': _nameCtr.text,
        'city': _cityCtr.text,
        'address': _addressCtr.text,
        'shop_image_url': imgUrl ?? widget.restaurant['shop_image_url'] ?? '',
        'latitude': _latitude,
        'longitude': _longitude,
        'is_active': _isActive,
      });

      final response = await http.put(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/${widget.restaurant['restaurant_id']}',
        ),
        headers: {
          'Authorization': 'Bearer $tkn',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật nhà hàng thành công')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _cityCtr.dispose();
    _addressCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa quán',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Quay lại trang Admin',
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.05,
                vertical: _spacing,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameCtr,
                        decoration: _decor('Tên quán'),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vui lòng nhập tên quán';
                          }
                          if (v.length > 100) {
                            return 'Tên không được vượt quá 100 ký tự';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _spacing),
                      TextFormField(
                        controller: _cityCtr,
                        decoration: _decor('Thành phố'),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vui lòng nhập thành phố';
                          }
                          if (v.length > 50) {
                            return 'Thành phố không được vượt quá 50 ký tự';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _spacing),
                      AddressField(
                        controller: _addressCtr,
                        latitude: _latitude,
                        longitude: _longitude,
                        onPlaceSelected: (GoongPlace place) async {
                          final coords = await getPlaceDetails(place.placeId);
                          if (coords != null) {
                            setState(() {
                              _latitude = coords['latitude'];
                              _longitude = coords['longitude'];
                              _addressCtr.text = place.description;
                            });
                          } else {
                            setState(() {
                              _latitude = null;
                              _longitude = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không thể lấy tọa độ từ địa chỉ',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: _spacing),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fileName == null
                                  ? 'Chưa chọn hình ảnh'
                                  : 'Đã chọn: $_fileName ($_fileExt)',
                              style: const TextStyle(
                                fontSize: 16,
                                color: _textColor,
                                fontFamily: _fontFamily,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Chọn Hình ảnh'),
                          ),
                        ],
                      ),
                      if (_selectedImage != null)
                        Padding(
                          padding: EdgeInsets.only(top: _spacing),
                          child: Image.file(
                            _selectedImage!,
                            height: sh * 0.20,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (widget.restaurant['shop_image_url'] != null &&
                          widget.restaurant['shop_image_url'].isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: _spacing),
                          child: Image.network(
                            widget.restaurant['shop_image_url'],
                            height: sh * 0.20,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Text('Không thể tải hình ảnh'),
                          ),
                        ),
                      SizedBox(height: _spacing),
                      SwitchListTile(
                        title: const Text('Trạng thái hoạt động'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeColor: _primaryColor,
                      ),
                      SizedBox(height: _spacing * 2),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.10,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child:
                              _isUploading
                                  ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                  : const Text('Cập nhật quán'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddressField extends StatefulWidget {
  final TextEditingController controller;
  final double? latitude;
  final double? longitude;
  final Function(GoongPlace) onPlaceSelected;

  const AddressField({
    super.key,
    required this.controller,
    required this.latitude,
    required this.longitude,
    required this.onPlaceSelected,
  });

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  bool _isSubmitted = false;
  String _lastSubmittedText = '';
  final _debouncer = Debouncer();

  Future<List<GoongPlace>> _fetchGoongSuggestions(String input) async {
    if (input.isEmpty) return [];

    final completer = Completer<List<GoongPlace>>();

    _debouncer.debounce(
      duration: const Duration(milliseconds: 500),
      onDebounce: () async {
        final url = Uri.parse(
          'https://rsapi.goong.io/Place/AutoComplete?input=${Uri.encodeComponent(input)}&location=21.0285,105.8542&api_key=$goongApiKey',
        );
        try {
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] != 'OK') {
              throw Exception(
                'Goong API error: ${data['error_message'] ?? 'Unknown'}',
              );
            }
            final predictions = data['predictions'] as List<dynamic>;
            completer.complete(
              predictions
                  .map((prediction) => GoongPlace.fromJson(prediction))
                  .toList(),
            );
          } else {
            completer.complete([]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi API: ${response.statusCode}')),
              );
            }
          }
        } catch (e) {
          completer.complete([]);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
          }
        }
      },
    );

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _lastSubmittedText = widget.controller.text;
    _isSubmitted = widget.controller.text.isNotEmpty;
    widget.controller.addListener(() {
      if (widget.controller.text != _lastSubmittedText) {
        setState(() {
          _isSubmitted = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Autocomplete<GoongPlace>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            return await _fetchGoongSuggestions(textEditingValue.text.trim());
          },
          displayStringForOption: (GoongPlace option) => option.description,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            textEditingController.text = widget.controller.text;
            textEditingController.addListener(() {
              if (textEditingController.text != widget.controller.text) {
                widget.controller.text = textEditingController.text;
              }
            });
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: _EditRestaurantScreenState()
                  ._decor('Nhập địa chỉ')
                  .copyWith(
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                    ),
                    hintText: 'Nhập địa chỉ',
                    hintStyle: const TextStyle(color: Colors.grey),
                    suffixIcon:
                        widget.controller.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  widget.controller.clear();
                                  textEditingController.clear();
                                  _isSubmitted = false;
                                  _lastSubmittedText = '';
                                  widget.onPlaceSelected(
                                    GoongPlace(description: '', placeId: ''),
                                  );
                                });
                              },
                            )
                            : null,
                  ),
              onChanged: (value) {
                if (value != _lastSubmittedText) {
                  setState(() {
                    _isSubmitted = false;
                  });
                }
              },
              onSubmitted: (value) {
                setState(() {
                  _isSubmitted = true;
                  _lastSubmittedText = value;
                });
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<GoongPlace> onSelected,
            Iterable<GoongPlace> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final GoongPlace option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            option.description,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (GoongPlace place) {
            setState(() {
              widget.controller.text = place.description;
              _isSubmitted = true;
              _lastSubmittedText = place.description;
            });
            widget.onPlaceSelected(place);
          },
        ),
        SizedBox(height: _EditRestaurantScreenState._spacing),
        Text(
          'Tọa độ: ${widget.latitude != null && widget.longitude != null ? 'Vĩ độ: ${widget.latitude!.toStringAsFixed(6)}, Kinh độ: ${widget.longitude!.toStringAsFixed(6)}' : 'Chưa có tọa độ'}',
          style: const TextStyle(
            fontSize: 14,
            color: _textColor,
            fontFamily: _fontFamily,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}
