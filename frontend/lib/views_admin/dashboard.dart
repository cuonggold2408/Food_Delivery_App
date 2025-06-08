import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Để định dạng số
import 'package:frontend/views_admin/review_restaurant_screen.dart';

// Các lớp Order, Receiver, OrderItem, Dish, Restaurant, Payment
class Order {
  final int orderId;
  final Receiver receiver;
  final List<OrderItem> items;
  final String orderStatus;
  final String subtotal;
  final String deliveryFee;
  final String discount;
  final String totalAmount;
  final String paymentMethod;
  final String? estimatedDeliveryTime;
  final String deliveryMethod;
  final String createdAt;
  final String updatedAt;
  final Restaurant restaurant;
  final Payment payment;

  Order({
    required this.orderId,
    required this.receiver,
    required this.items,
    required this.orderStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    this.estimatedDeliveryTime,
    required this.deliveryMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.restaurant,
    required this.payment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? 0,
      receiver: Receiver.fromJson(json['receiver'] ?? {}),
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map((item) => OrderItem.fromJson(item))
              .toList(),
      orderStatus: json['order_status'] ?? '',
      subtotal: json['subtotal'] ?? '0',
      deliveryFee: json['delivery_fee'] ?? '0',
      discount: json['discount'] ?? '0',
      totalAmount: json['total_amount'] ?? '0',
      paymentMethod: json['payment_method'] ?? '',
      estimatedDeliveryTime: json['estimated_delivery_time'],
      deliveryMethod: json['delivery_method'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      restaurant: Restaurant.fromJson(json['restaurant'] ?? {}),
      payment: Payment.fromJson(json['payment'] ?? {}),
    );
  }
}

class Receiver {
  final String name;
  final String phone;
  final String address;

  Receiver({required this.name, required this.phone, required this.address});

  factory Receiver.fromJson(Map<String, dynamic> json) {
    return Receiver(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class OrderItem {
  final Dish dish;
  final String? message;
  final int quantity;
  final String totalPay;

  OrderItem({
    required this.dish,
    this.message,
    required this.quantity,
    required this.totalPay,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dish: Dish.fromJson(json['dish'] ?? {}),
      message: json['message'],
      quantity: json['quantity'] ?? 0,
      totalPay: json['total_pay'] ?? '0',
    );
  }
}

class Dish {
  final String name;
  final String image;
  final String price;
  final String dishId;
  final List<dynamic> options;

  Dish({
    required this.name,
    required this.image,
    required this.price,
    required this.dishId,
    required this.options,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: json['price'] ?? '0',
      dishId: json['dish_id'] ?? '',
      options: json['options'] ?? [],
    );
  }
}

class Restaurant {
  final String restaurantId;
  final String name;
  final String city;
  final String shopImageUrl;
  final bool isActive;
  final String latitude;
  final String longitude;
  final double rating;
  final String createdAt;
  final String updatedAt;

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.city,
    required this.shopImageUrl,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      restaurantId: json['restaurant_id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      shopImageUrl: json['shop_image_url'] ?? '',
      isActive: json['is_active'] ?? false,
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Payment {
  final int paymentId;
  final String paymentStatus;
  final String createdAt;
  final String updatedAt;

  Payment({
    required this.paymentId,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['payment_id'] ?? 0,
      paymentStatus: json['payment_status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.05),
                        shape: const CircleBorder(),
                      ),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: screenWidth * 0.06,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'DashBoard',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: DashboardScreen._primaryColor,
                        fontFamily: DashboardScreen._fontFamily,
                      ),
                    ),
                    const SizedBox(width: 48), // Placeholder để cân bằng layout
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: screenHeight * 0.03),
                  _RunningOrdersCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    primaryColor: DashboardScreen._primaryColor,
                    textGray: DashboardScreen._textGray,
                    fontFamily: DashboardScreen._fontFamily,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _RevenueCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    primaryColor: DashboardScreen._primaryColor,
                    textGray: DashboardScreen._textGray,
                    fontFamily: DashboardScreen._fontFamily,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _ReviewsCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    primaryColor: DashboardScreen._primaryColor,
                    fontFamily: DashboardScreen._fontFamily,
                  ),
                  SizedBox(height: screenHeight * 0.15),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Các widget con không thay đổi
class _RunningOrdersCard extends StatefulWidget {
  const _RunningOrdersCard({
    required this.screenWidth,
    required this.screenHeight,
    required this.primaryColor,
    required this.textGray,
    required this.fontFamily,
  });

  final double screenWidth;
  final double screenHeight;
  final Color primaryColor;
  final Color textGray;
  final String fontFamily;

  @override
  State<_RunningOrdersCard> createState() => _RunningOrdersCardState();
}

class _RunningOrdersCardState extends State<_RunningOrdersCard> {
  bool isExpanded = false;
  List<Order> orders = [];
  bool isLoading = true;
  String? errorMessage;
  Set<int> completedOrders = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
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
          'https://api.df.nguyenquangcuong.pro/admin/orders?page=1&limit=1000',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> orderData = jsonData['data']['orders'] ?? [];
        setState(() {
          orders = orderData.map((item) => Order.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Tải danh sách đơn hàng thất bại: Status ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải danh sách đơn hàng: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _markOrderDone(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http.put(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/orders/$orderId/done',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          completedOrders.add(orderId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đơn hàng đã hoàn thành')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: Không thể hoàn thành đơn hàng. Status ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(DashboardScreen._cardBorderRadius),
        ),
        boxShadow: [DashboardScreen._cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${orders.length} Đơn hàng',
                  style: TextStyle(
                    fontSize: widget.screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    fontFamily: widget.fontFamily,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: widget.screenWidth * 0.045,
                  color: widget.primaryColor,
                ),
              ],
            ),
          ),
          if (isExpanded)
            Dismissible(
              key: const Key('running_orders_list'),
              direction: DismissDirection.down,
              onDismissed: (_) {
                setState(() {
                  isExpanded = false;
                });
              },
              child: Column(
                children: [
                  SizedBox(height: widget.screenHeight * 0.02),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: widget.screenHeight * 0.02,
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: widget.screenWidth * 0.035,
                          fontFamily: widget.fontFamily,
                        ),
                      ),
                    )
                  else if (orders.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: widget.screenHeight * 0.02,
                      ),
                      child: Text(
                        'Không có đơn hàng nào',
                        style: TextStyle(
                          fontSize: widget.screenWidth * 0.035,
                          fontFamily: widget.fontFamily,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: widget.screenHeight * 0.25,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        order.items.isNotEmpty &&
                                                order
                                                    .items[0]
                                                    .dish
                                                    .image
                                                    .isNotEmpty
                                            ? Image.network(
                                              order.items[0].dish.image,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 64,
                                                    height: 64,
                                                    color: const Color(
                                                      0xFF9AA3AF,
                                                    ),
                                                  ),
                                            )
                                            : Container(
                                              width: 64,
                                              height: 64,
                                              color: const Color(0xFF9AA3AF),
                                            ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          '#${order.orderStatus.toLowerCase().replaceAll('_', ' ')}',
                                          style: TextStyle(
                                            fontSize: widget.screenWidth * 0.03,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFFF6B35),
                                            fontFamily: widget.fontFamily,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          order.items.isNotEmpty
                                              ? order.items[0].dish.name
                                              : 'Món không xác định',
                                          style: TextStyle(
                                            fontSize: widget.screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontFamily: widget.fontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'ID: ${order.orderId}',
                                          style: TextStyle(
                                            fontSize: widget.screenWidth * 0.03,
                                            color: widget.textGray,
                                            fontFamily: widget.fontFamily,
                                          ),
                                        ),
                                        Text(
                                          '${order.items.isNotEmpty ? order.items[0].totalPay.replaceAll('.00', '') : '0'} VNĐ',
                                          style: TextStyle(
                                            fontSize:
                                                widget.screenWidth * 0.035,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                            fontFamily: widget.fontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child:
                                          completedOrders.contains(
                                                order.orderId,
                                              )
                                              ? Container(
                                                width: 48,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF4CAF50,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              )
                                              : ElevatedButton(
                                                onPressed:
                                                    () => _markOrderDone(
                                                      order.orderId,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFFF6B35,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size(
                                                    48,
                                                    20,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  'Done',
                                                  style: TextStyle(
                                                    fontSize:
                                                        widget.screenWidth *
                                                        0.03,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        widget.fontFamily,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatefulWidget {
  const _RevenueCard({
    required this.screenWidth,
    required this.screenHeight,
    required this.primaryColor,
    required this.textGray,
    required this.fontFamily,
  });

  final double screenWidth;
  final double screenHeight;
  final Color primaryColor;
  final Color textGray;
  final String fontFamily;

  @override
  State<_RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<_RevenueCard> {
  bool isLoading = true;
  String? errorMessage;
  double totalRevenue = 0;
  List<Map<String, dynamic>> revenueByMonth = [];
  String selectedTimeFrame = 'Hàng tháng';

  @override
  void initState() {
    super.initState();
    _fetchRevenue();
  }

  Future<void> _fetchRevenue() async {
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
        Uri.parse('https://api.df.nguyenquangcuong.pro/admin/report'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'];
        setState(() {
          totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
          revenueByMonth = List<Map<String, dynamic>>.from(
            data['totalRevenueByMonth'] ?? [],
          );
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Tải dữ liệu doanh thu thất bại: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải dữ liệu doanh thu: $e';
        isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return '${formatter.format(amount)} VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(DashboardScreen._cardBorderRadius),
        ),
        boxShadow: [DashboardScreen._cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng doanh thu',
                    style: TextStyle(
                      fontSize: widget.screenWidth * 0.035,
                      color: widget.textGray,
                      fontFamily: widget.fontFamily,
                    ),
                  ),
                  SizedBox(height: widget.screenHeight * 0.005),
                  isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                        _formatCurrency(totalRevenue),
                        style: TextStyle(
                          fontSize: widget.screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          fontFamily: widget.fontFamily,
                        ),
                      ),
                ],
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: selectedTimeFrame,
                    padding: EdgeInsets.zero,
                    underline: const SizedBox(),
                    items:
                        ['Hàng tháng']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedTimeFrame = value;
                        });
                      }
                    },
                    style: TextStyle(
                      fontSize: widget.screenWidth * 0.035,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: widget.screenHeight * 0.02),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: widget.screenHeight * 0.02,
              ),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: widget.screenWidth * 0.035,
                  fontFamily: widget.fontFamily,
                ),
              ),
            )
          else
            SizedBox(
              height: widget.screenHeight * 0.2,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 1 || value.toInt() > 12) {
                            return const SizedBox();
                          }
                          return Text(
                            'T${value.toInt()}',
                            style: TextStyle(
                              fontSize: widget.screenWidth * 0.03,
                              color: widget.textGray,
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCurrency(value).replaceAll(' VNĐ', ''),
                            style: TextStyle(
                              fontSize: widget.screenWidth * 0.03,
                              color: widget.textGray,
                            ),
                          );
                        },
                        interval: totalRevenue / 5,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: totalRevenue / 5,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                    getDrawingVerticalLine:
                        (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          revenueByMonth.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble() + 1,
                              (entry.value['revenue'] ?? 0).toDouble(),
                            );
                          }).toList(),
                      isCurved: true,
                      barWidth: 3,
                      color: widget.primaryColor,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryColor.withOpacity(0.3),
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minX: 1,
                  maxX: 12,
                  minY: 0,
                  maxY:
                      revenueByMonth
                          .map((e) => (e['revenue'] ?? 0).toDouble())
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: totalRevenue,
                        color: Colors.red.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (_) => _formatCurrency(totalRevenue),
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: widget.screenWidth * 0.035,
                          ),
                          alignment: Alignment.topRight,
                          padding: EdgeInsets.only(
                            left: widget.screenWidth * 0.02,
                            top: widget.screenHeight * 0.01,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatefulWidget {
  const _ReviewsCard({
    required this.screenWidth,
    required this.screenHeight,
    required this.primaryColor,
    required this.fontFamily,
  });

  final double screenWidth;
  final double screenHeight;
  final Color primaryColor;
  final String fontFamily;

  @override
  State<_ReviewsCard> createState() => _ReviewsCardState();
}

class _ReviewsCardState extends State<_ReviewsCard> {
  int totalReviews = 0;
  double averageRating = 0.0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
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
        final List<dynamic> reviews = jsonData['data'] ?? [];

        // Tính tổng số đánh giá và điểm trung bình
        final totalReviews = reviews.length;
        final totalRating = reviews.fold<double>(
          0,
          (sum, review) => sum + (review['rating'] as num).toDouble(),
        );
        final averageRating =
            totalReviews > 0 ? totalRating / totalReviews : 0.0;

        setState(() {
          this.totalReviews = totalReviews;
          this.averageRating = double.parse(averageRating.toStringAsFixed(1));
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
    return Container(
      padding: EdgeInsets.all(widget.screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(DashboardScreen._cardBorderRadius),
        ),
        boxShadow: [DashboardScreen._cardShadow],
      ),
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: widget.screenWidth * 0.035,
                  fontFamily: widget.fontFamily,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: widget.primaryColor,
                        size: widget.screenWidth * 0.06,
                      ),
                      SizedBox(width: widget.screenWidth * 0.02),
                      Text(
                        averageRating.toString(),
                        style: TextStyle(
                          fontSize: widget.screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          fontFamily: widget.fontFamily,
                        ),
                      ),
                      SizedBox(width: widget.screenWidth * 0.02),
                      Text(
                        'Tổng $totalReviews đánh giá',
                        style: TextStyle(
                          fontSize: widget.screenWidth * 0.035,
                          fontFamily: widget.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReviewRestaurantScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Xem tất cả đánh giá',
                      style: TextStyle(
                        fontSize: widget.screenWidth * 0.035,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
