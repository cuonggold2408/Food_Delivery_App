import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày

const _primaryColor = Color(0xFFFC6E2A);
const _textGray = Color(0xFF676767);
const _fontFamily = 'Montserrat';
const _cardShadow = BoxShadow(
  color: Colors.black12,
  blurRadius: 6,
  spreadRadius: 0,
  offset: Offset(0, 2),
);

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final List<dynamic> _users = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _canFetch = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('access_token');

  Future<void> _fetchUsers() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final tkn = await _token();
      if (tkn == null) throw Exception('Vui lòng đăng nhập');

      final uri = Uri.parse(
        'https://api.df.nguyenquangcuong.pro/admin/users?page=$_page&limit=20',
      );

      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $tkn',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('API trả về ${res.statusCode}');
      }

      final data = jsonDecode(res.body)['data'];
      final List<dynamic> fetched = data['users'] as List<dynamic>;
      final int total = data['total'] ?? _users.length + fetched.length;

      setState(() {
        _users.addAll(fetched);
        _page++;
        _hasMore = _users.length < total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_canFetch &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _canFetch = false;
      _fetchUsers().then((_) {
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _canFetch = true,
        );
      });
    }
  }

  Future<void> _toggleUserStatus(int userId, bool isActive) async {
    try {
      final tkn = await _token();
      if (tkn == null) throw Exception('Vui lòng đăng nhập');

      final uri = Uri.parse(
        'https://api.df.nguyenquangcuong.pro/admin/users/$userId/${isActive ? 'unblock' : 'block'}',
      );

      final res = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $tkn',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        setState(() {
          final user = _users.firstWhere((u) => u['user_id'] == userId);
          user['is_active'] = isActive;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Đã mở khóa user' : 'Đã khóa user'),
          ),
        );
      } else {
        throw Exception('API trả về ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách người dùng',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _users.clear();
            _page = 1;
            _hasMore = true;
          });
          await _fetchUsers();
        },
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04,
                vertical: sh * 0.02,
              ),
              itemCount: _users.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _users.length) {
                  final u = _users[index];
                  return _UserCard(
                    user: u,
                    onToggleStatus:
                        (userId, isActive) =>
                            _toggleUserStatus(userId, isActive),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                );
              },
            ),
            if (_isLoading && _users.isEmpty)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

/// Card hiển thị thông tin 1 user
class _UserCard extends StatelessWidget {
  final dynamic user;
  final Function(int, bool) onToggleStatus;

  const _UserCard({required this.user, required this.onToggleStatus});

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isActive = user['is_active'] ?? true;

    return Card(
      margin: EdgeInsets.only(bottom: sw * 0.04),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black26,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Colors.white : Colors.grey[100],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.04,
            vertical: sw * 0.02,
          ),
          leading: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: sw * 0.08,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                        ? NetworkImage(user['avatar_url'])
                        : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
              ),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    size: sw * 0.04,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user['name'] ?? 'Không rõ tên',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: sw * 0.045,
                    color: isActive ? Colors.black : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.02,
                  vertical: sw * 0.01,
                ),
                decoration: BoxDecoration(
                  color:
                      user['user_role'] == 'admin'
                          ? Colors.blue[100]
                          : Colors.green[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user['user_role']?.toUpperCase() ?? 'customer',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: sw * 0.03,
                    color:
                        user['user_role'] == 'admin'
                            ? Colors.blue[800]
                            : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: sw * 0.01),
              Text(
                user['email'] ?? 'Không rõ email',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: sw * 0.035,
                  color: _textGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: sw * 0.01),
              Text(
                'Đăng ký: ${_formatDate(user['created_at'] ?? '')}',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: sw * 0.03,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _textGray, size: sw * 0.06),
            onSelected: (value) {
              if (value == 'block' || value == 'unlock') {
                onToggleStatus(user['user_id'], value == 'unlock');
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: isActive ? 'block' : 'unlock',
                    child: Text(
                      isActive ? 'Khóa' : 'Mở khóa',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
