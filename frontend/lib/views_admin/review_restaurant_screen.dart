import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:frontend/views_admin/review_screen.dart';

class ReviewRestaurantScreen extends StatefulWidget {
  const ReviewRestaurantScreen({super.key});

  @override
  State<ReviewRestaurantScreen> createState() => _ReviewRestaurantScreenState();
}

class _ReviewRestaurantScreenState extends State<ReviewRestaurantScreen> {
  static const _primaryColor = Color(0xFFFC6E2A);
  static const _textGray = Color(0xFF676767);
  static const _fontFamily = 'San Francisco';
  static const _cardBorderRadius = 12.0;
  static const _cardShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 6,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantReviews();
  }

  Future<void> _fetchRestaurantReviews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/reviews',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Kiểm tra nếu jsonData là Map và lấy danh sách từ trường 'data'
        final List<dynamic> reviews =
            jsonData is Map<String, dynamic> && jsonData['data'] != null
                ? jsonData['data']
                : jsonData is List<dynamic>
                ? jsonData
                : [];

        // Nhóm đánh giá theo nhà hàng
        Map<String, Map<String, dynamic>> restaurantMap = {};
        for (var review in reviews) {
          final restaurant = review['order']?['restaurant'] ?? {};
          final restaurantId = restaurant['restaurant_id']?.toString() ?? '';
          final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;

          if (restaurantId.isNotEmpty) {
            if (!restaurantMap.containsKey(restaurantId)) {
              restaurantMap[restaurantId] = {
                'restaurant_id': restaurantId,
                'name': restaurant['name'] ?? 'Không xác định',
                'shop_image_url': restaurant['shop_image_url'] ?? '',
                'city': restaurant['city'] ?? '',
                'total_reviews': 0,
                'total_rating': 0.0,
              };
            }
            restaurantMap[restaurantId]!['total_reviews'] += 1;
            restaurantMap[restaurantId]!['total_rating'] += rating;
          }
        }

        // Tính điểm trung bình và tạo danh sách nhà hàng
        final restaurantList =
            restaurantMap.values.map((restaurant) {
              final totalReviews = restaurant['total_reviews'] as int;
              final totalRating = restaurant['total_rating'] as double;
              return {
                'restaurant_id': restaurant['restaurant_id'],
                'name': restaurant['name'],
                'shop_image_url': restaurant['shop_image_url'],
                'city': restaurant['city'],
                'total_reviews': totalReviews,
                'average_rating':
                    totalReviews > 0
                        ? double.parse(
                          (totalRating / totalReviews).toStringAsFixed(1),
                        )
                        : 0.0,
              };
            }).toList();

        setState(() {
          restaurants = restaurantList;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Tải đánh giá thất bại: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải đánh giá: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Đánh giá nhà hàng',
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            fontFamily: _fontFamily,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenWidth * 0.04,
                          fontFamily: _fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      ElevatedButton(
                        onPressed: _fetchRestaurantReviews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Thử lại',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontFamily: _fontFamily,
                          ),
                        ),
                      ),
                    ],
                  )
                  : restaurants.isEmpty
                  ? Center(
                    child: Text(
                      'Không có nhà hàng nào được đánh giá',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontFamily: _fontFamily,
                        color: _textGray,
                      ),
                    ),
                  )
                  : ListView.separated(
                    itemCount: restaurants.length,
                    separatorBuilder:
                        (_, __) => SizedBox(height: screenHeight * 0.02),
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ReviewsScreen(
                                    restaurantId: restaurant['restaurant_id'],
                                    restaurantName: restaurant['name'],
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(_cardBorderRadius),
                            ),
                            boxShadow: [_cardShadow],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    restaurant['shop_image_url'].isNotEmpty
                                        ? Image.network(
                                          restaurant['shop_image_url'],
                                          width: screenWidth * 0.2,
                                          height: screenWidth * 0.2,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: screenWidth * 0.2,
                                                    height: screenWidth * 0.2,
                                                    color: _textGray,
                                                    child: const Icon(
                                                      Icons.restaurant,
                                                      color: Colors.white,
                                                      size: 32,
                                                    ),
                                                  ),
                                        )
                                        : Container(
                                          width: screenWidth * 0.2,
                                          height: screenWidth * 0.2,
                                          color: _textGray,
                                          child: const Icon(
                                            Icons.restaurant,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant['name'],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: _fontFamily,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      restaurant['city'],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: _textGray,
                                        fontFamily: _fontFamily,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: _primaryColor,
                                          size: screenWidth * 0.05,
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        Text(
                                          '${restaurant['average_rating']}',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: _fontFamily,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          '(${restaurant['total_reviews']} đánh giá)',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: _textGray,
                                            fontFamily: _fontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'Điểm nhà hàng: ${restaurant['restaurant_rating']}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: _textGray,
                                        fontFamily: _fontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
