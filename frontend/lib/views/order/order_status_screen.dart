import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  String? _authToken;
  bool _isLoading = true;
  String? _error;
  List<dynamic>? _orders = []; // Initialize as empty list to avoid null

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadToken();
    if (_authToken == null) {
      setState(() {
        _error = 'Vui lòng đăng nhập để xem đơn hàng';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để xem đơn hàng'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _fetchOrders();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('access_token');
    });
    print('Loaded token: $_authToken');
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.df.nguyenquangcuong.pro/orders/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 10));

      print('Orders API Status: ${response.statusCode}');
      print('Orders API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['statusCode'] == 200) {
          setState(() {
            _orders = data['data'] ?? [];
            // Log the structure of the first order for debugging
            if (_orders != null && _orders!.isNotEmpty) {
              print('First order items: ${jsonEncode(_orders![0]['items'])}');
              if (_orders![0]['items'].isNotEmpty) {
                print('Dish keys: ${(_orders![0]['items'][0]['dish'] as Map).keys}');
              }
            }
            _isLoading = false;
          });
        } else {
          throw Exception('Phản hồi API không hợp lệ: ${data['message'] ?? 'Thiếu dữ liệu đơn hàng'}');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Không thể tải đơn hàng: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _error = 'Không thể tải đơn hàng: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building with _orders: $_orders'); // Debug log
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ongoing',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement history view
                            },
                            child: const Text('History', style: TextStyle(fontSize: 16, color: Colors.orange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _orders == null || _orders!.isEmpty
                            ? const Center(child: Text('No orders found'))
                            : ListView.builder(
                                itemCount: _orders!.length,
                                itemBuilder: (context, index) {
                                  final order = _orders![index];
                                  final items = order['items'] as List<dynamic>? ?? [];
                                  final vendor = items.isNotEmpty ? items[0]['dish']['name'] ?? 'Unknown' : 'Unknown';
                                  final price = '\$${order['total_amount'] ?? 0}';
                                  final itemCount = '${items.length} Items';
                                  final orderId = order['order_id'] is int
                                      ? order['order_id']
                                      : int.tryParse(order['order_id'].toString()) ?? 0;
                                  final orderStatus = order['order_status'] ?? 'Unknown';
                                  final imageUrl = items.isNotEmpty ? items[0]['dish']['image'] ?? '' : '';
                                  // Try multiple possible keys for itemId
                                  final itemId = items.isNotEmpty
                                      ? (items[0]['dish']['dish_id']?.toString() ??
                                         items[0]['dish']['id']?.toString() ??
                                         items[0]['dish']['item_id']?.toString() ??
                                         items[0]['dish']['product_id']?.toString() ??
                                         '0')
                                      : '0';
                                  print('Item ID for order #$orderId: $itemId');
                                  if (itemId == '0') {
                                    print('Warning: itemId is 0, check dish structure: ${jsonEncode(items[0]['dish'])}');
                                  }
                                  return Column(
                                    children: [
                                      _buildOrderItem(vendor, price, itemCount, orderId, orderStatus, imageUrl, itemId, context),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderItem(String vendor, String price, String items, int orderId, String orderStatus, String imageUrl, String itemId, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.fastfood, color: Colors.grey)),
                ),
              ),
            ),
            title: Text(vendor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Text('$price | $items | #$orderId', style: const TextStyle(fontSize: 14)),
            trailing: orderStatus == 'DELIVERED'
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (itemId == '0') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể đánh giá: ID sản phẩm không hợp lệ')),
                        );
                        return;
                      }
                      _showRatingDialog(context, orderId, itemId);
                    },
                    child: const Text('Rate Order', style: TextStyle(color: Colors.white)),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  void _showRatingDialog(BuildContext context, int orderId, String itemId) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(orderId: orderId, itemId: itemId, authToken: _authToken),
    );
  }
}

class RatingDialog extends StatefulWidget {
  final int orderId;
  final String itemId;
  final String? authToken;

  const RatingDialog({super.key, required this.orderId, required this.itemId, this.authToken});

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  bool _isAnonymous = false;
  final List<File> _images = [];
  final List<String> _fileNames = [];
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    if (_images.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được tải lên tối đa 2 ảnh')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileName = p.basename(pickedFile.path);
      setState(() {
        _images.add(File(pickedFile.path));
        _fileNames.add(fileName);
      });
      print('🖼️  File: $fileName');
    }
  }

  Future<Map<String, String>> _createPresignedUrl(String fileName) async {
    final tkn = widget.authToken;
    if (tkn == null) throw Exception('No access token');

    final res = await http.post(
      Uri.parse('https://api.df.nguyenquangcuong.pro/media/images/upload/presigned-url'),
      headers: {
        'Authorization': 'Bearer $tkn',
        'Content-Type': 'application/json',
      },
      body: json.encode({'fileName': fileName}),
    );

    if (res.statusCode != 201) {
      throw Exception('Presigned-URL error ${res.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(res.body);
    final Map<String, dynamic> inner = body['data'] as Map<String, dynamic>;

    final String uploadUrl = inner['presignedUrl'] as String;
    final String publicUrl = inner['url'] as String;

    print('presignedUrl: $uploadUrl');
    print('publicUrl   : $publicUrl');

    return {'upload_url': uploadUrl, 'public_url': publicUrl};
  }

  Future<List<Map<String, String>>> _uploadImagesToS3() async {
    final List<Map<String, String>> mediaList = [];
    for (int i = 0; i < _images.length; i++) {
      final image = _images[i];
      final fileName = _fileNames[i];
      try {
        final presigned = await _createPresignedUrl(fileName);
        final putUrl = presigned['upload_url']!;
        final publicUrl = presigned['public_url']!;
        final bytes = await image.readAsBytes();
        final mimeType = lookupMimeType(image.path) ?? 'application/octet-stream';

        final res = await http.put(
          Uri.parse(putUrl),
          headers: {'Content-Type': mimeType},
          body: bytes,
        );

        if (res.statusCode == 200 || res.statusCode == 204) {
          print('✅ S3 upload OK for $fileName');
          mediaList.add({'url': publicUrl, 'type': 'IMAGE'});
        } else {
          throw Exception('S3 upload fail for $fileName: ${res.statusCode}');
        }
      } catch (e) {
        print('Error uploading image $fileName: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh $fileName: $e')),
        );
      }
    }
    return mediaList;
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá và chọn rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final mediaList = await _uploadImagesToS3();
        print('Review API Payload: ${jsonEncode({
          'content': _reviewController.text,
          'rating': _rating.toInt(),
          'itemId': widget.itemId,
          'orderId': widget.orderId,
          'medias': mediaList.isEmpty ? [] : mediaList,
          'isAnonymous': _isAnonymous,
        })}');
        final response = await http.post(
          Uri.parse('https://api.df.nguyenquangcuong.pro/reviews'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.authToken}',
          },
          body: jsonEncode({
            'content': _reviewController.text,
            'rating': _rating.toInt(),
            'itemId': widget.itemId,
            'orderId': widget.orderId,
            'medias': mediaList.isEmpty ? [] : mediaList,
            'isAnonymous': _isAnonymous,
          }),
        );

        print('Review API Status: ${response.statusCode}');
        print('Review API Response: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đánh giá đã được gửi')),
          );
          Navigator.of(context).pop();
          return;
        } else {
          throw Exception('Lỗi khi gửi đánh giá: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } finally {
        if (attempt == maxRetries) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đánh giá đơn hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Nội dung đánh giá',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value ?? false;
                    });
                  },
                ),
                const Text('Ẩn danh'),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ..._images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Image.file(
                        image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _images.removeAt(index);
                              _fileNames.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
                if (_images.length < 2)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gửi'),
        ),
      ],
    );  
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}