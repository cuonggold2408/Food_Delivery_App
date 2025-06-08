import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Màu sắc và kiểu dáng
const _cardBgLight = Color(0xFFF4F7FC);
const _cardBgDark = Color(0xFF1E1E1E);
const _avatarColor = Color(0xFF9BB3CF);
const _primaryColor = Color(0xFFFC6E2A);
const _textGray = Color(0xFF676767);
const _fontFamily = 'San Francisco';

// Mô hình đánh giá
class Review {
  final String date;
  final String title;
  final String comment;
  final int rating;
  final String? user;
  final String? reply;
  final String? replyDate;
  final int reviewId;

  const Review({
    required this.date,
    required this.title,
    required this.comment,
    required this.rating,
    required this.reviewId,
    this.user,
    this.reply,
    this.replyDate,
  });
}

// Màn hình danh sách đánh giá
class ReviewsScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ReviewsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  // Lấy danh sách đánh giá từ API
  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/${widget.restaurantId}/reviews',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final reviewData =
            jsonData is Map<String, dynamic> && jsonData['data'] != null
                ? jsonData['data'] as List<dynamic>
                : jsonData is List<dynamic>
                ? jsonData
                : [];

        final reviews =
            reviewData.map((review) {
              final createdAt = DateTime.parse(review['created_at']);
              final dateFormat = DateFormat('dd/MM/yyyy');
              final replyDate =
                  review['reply_date'] != null
                      ? dateFormat.format(DateTime.parse(review['reply_date']))
                      : null;
              return Review(
                date: dateFormat.format(createdAt),
                title: review['menuItem']?['name'] ?? 'Không xác định',
                comment: review['review_text'] ?? '',
                rating: (review['rating'] as num?)?.toInt() ?? 0,
                user: review['user'] ?? 'Ẩn danh',
                reply: review['review_reply'],
                replyDate: replyDate,
                reviewId: review['review_id'] as int,
              );
            }).toList();

        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Tải đánh giá thất bại: Mã lỗi ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải đánh giá: $e';
        _isLoading = false;
      });
    }
  }

  // Gửi phản hồi qua API
  Future<void> _sendReply(int reviewId, String replyText) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Không tìm thấy access token. Vui lòng đăng nhập.');
      }

      final response = await http.post(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/reviews/$reviewId/reply',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'review_reply': replyText}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          json.decode(response.body); // Kiểm tra định dạng JSON
        } catch (e) {
          throw Exception('Định dạng phản hồi từ server không hợp lệ');
        }
        await _fetchReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phản hồi đã được gửi thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          'Không thể gửi phản hồi: Mã lỗi ${response.statusCode}',
        );
      }
    } catch (e) {
      // Ghi log lỗi để debug
      debugPrint('Lỗi khi gửi phản hồi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi gửi phản hồi: ${e.toString().split(':').last.trim()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Kéo để làm mới
  Future<void> _onRefresh() async {
    await _fetchReviews();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Thanh tiêu đề
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? Colors.white24
                              : Colors.black.withOpacity(0.05),
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.restaurantName,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Danh sách đánh giá
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontFamily: _fontFamily,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchReviews,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'Thử lại',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                            ),
                          ],
                        )
                        : _reviews.isEmpty
                        ? Center(
                          child: Text(
                            'Không có đánh giá nào cho nhà hàng này',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: _fontFamily,
                              color: _textGray,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 24,
                            right: 16,
                          ),
                          itemBuilder:
                              (context, index) => _ReviewCard(
                                review: _reviews[index],
                                isDark: isDark,
                                onReply: _sendReply,
                              ),
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 12),
                          itemCount: _reviews.length,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget thẻ đánh giá
class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isDark;
  final Future<void> Function(int, String) onReply;

  const _ReviewCard({
    required this.review,
    required this.isDark,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? _cardBgDark : _cardBgLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar giả
        Container(
          margin: const EdgeInsets.only(left: 16),
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _avatarColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),

        // Nội dung thẻ
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề và menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin đánh giá
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.date,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 12,
                              color: _textGray.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bởi: ${review.user ?? 'Ẩn danh'}',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 12,
                              color: _textGray.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review.title,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Dãy sao đánh giá
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color:
                                    index < review.rating
                                        ? _primaryColor
                                        : _textGray.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu tùy chọn
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: Icon(
                        Icons.more_horiz,
                        color:
                            isDark
                                ? Colors.white70
                                : Colors.black.withOpacity(0.6),
                      ),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'reply',
                              child: Text('Phản hồi'),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Báo cáo'),
                            ),
                          ],
                      onSelected: (value) {
                        if (value == 'reply') {
                          _showReplyDialog(context);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nội dung đánh giá
                Text(
                  review.comment,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : _textGray,
                    height: 1.35,
                  ),
                ),

                // Phần phản hồi
                if (review.reply != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phản hồi: ${review.reply}',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : _textGray,
                            height: 1.35,
                          ),
                        ),
                        if (review.replyDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ngày phản hồi: ${review.replyDate}',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              color: _textGray.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Hiển thị hộp thoại phản hồi
  void _showReplyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Phản hồi đánh giá',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nhập nội dung phản hồi',
                border: const OutlineInputBorder(),
                hintText: 'Viết phản hồi của bạn...',
                hintStyle: TextStyle(color: _textGray.withOpacity(0.6)),
              ),
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.done,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: TextStyle(fontFamily: _fontFamily, color: _textGray),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final replyText = controller.text.trim();
                  if (replyText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập nội dung phản hồi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (replyText.length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phản hồi phải có ít nhất 5 ký tự'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  onReply(review.reviewId, replyText);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Gửi', style: TextStyle(fontFamily: _fontFamily)),
              ),
            ],
          ),
    );
  }
}
