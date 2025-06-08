import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_results_screen.dart'; // Import màn hình kết quả tìm kiếm

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<Map<String, dynamic>> _suggestedRestaurants = [
    {'name': 'Bánh mì', 'image': 'placeholder4'},
    {'name': 'Bún bò Huế', 'image': 'placeholder1'},
    {'name': 'Bún đậu mắm tôm', 'image': 'placeholder2'},
    {'name': 'Gà rán', 'image': 'placeholder3'},
    {'name': 'Nem nướng', 'image': 'placeholder4'},
    {'name': 'Cơm chiên dưa bò', 'image': 'placeholder4'},
    {'name': 'Bún', 'image': 'placeholder4'},
    {'name': 'Cơm gà xối mỡ', 'image': 'placeholder4'},
    {'name': 'Gà ủ muối', 'image': 'placeholder4'},
    {'name': 'Mì trộn Indomie', 'image': 'placeholder4'},
    {'name': 'Bánh xèo', 'image': 'placeholder4'},
    {'name': 'Phở', 'image': 'placeholder4'},
    {'name': 'Cháo lòng', 'image': 'placeholder4'},
    {'name': 'Bánh tráng trộn', 'image': 'placeholder4'},
    {'name': 'Trà sữa', 'image': 'placeholder4'},
    {'name': 'Bánh canh cua', 'image': 'placeholder4'},
    {'name': 'Nước dừa', 'image': 'placeholder4'},
    {'name': 'Pizza', 'image': 'placeholder4'},
    {'name': 'Tré trộn', 'image': 'placeholder4'},
    {'name': 'Cá viên chiên', 'image': 'placeholder4'},
    {'name': 'Bánh kem', 'image': 'placeholder4'},
    {'name': 'Bánh tacos', 'image': 'placeholder4'},
    {'name': 'Cơm', 'image': 'placeholder4'},
    {'name': 'Miến trộn', 'image': 'placeholder4'},
    {'name': 'Mì tương đen', 'image': 'placeholder4'},
    {'name': 'Chân gà nướng', 'image': 'placeholder4'},
    {'name': 'Cơm niêu', 'image': 'placeholder4'},
    {'name': 'Chè Thái', 'image': 'placeholder4'},
    {'name': 'Phở bò', 'image': 'placeholder4'},
    {'name': 'Cà phê muối', 'image': 'placeholder4'},
  ];
  final List<Map<String, dynamic>> _popularFastFood = [
    {'name': 'European Pizza Uttora Coffee House', 'image': 'placeholder1'},
    {'name': 'Buffalo Pizza Cafenio Coffee Club', 'image': 'placeholder2'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Hàm điều hướng sang SearchResultsScreen với từ khóa và tọa độ
  Future<void> _performSearch(String query) async {
    if (query.isNotEmpty) {
      // Lấy tọa độ từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final latitude =
          prefs.getDouble('user_latitude') ?? 10.0; // Giá trị mặc định
      final longitude =
          prefs.getDouble('user_longitude') ?? 1.0; // Giá trị mặc định

      // Kiểm tra tọa độ hợp lệ
      double finalLatitude = latitude;
      double finalLongitude = longitude;
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid coordinates, using default location'),
          ),
        );
        finalLatitude = 10.0;
        finalLongitude = 1.0;
      }

      // Log tọa độ trước khi truyền
      print('Sending location to SearchResultsScreen:');
      print('Latitude: $finalLatitude');
      print('Longitude: $finalLongitude');

      // Điều hướng sang SearchResultsScreen và truyền tọa độ
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SearchResultsScreen(
                searchQuery: query,
                latitude: finalLatitude,
                longitude: finalLongitude,
              ),
        ),
      );

      // Xóa nội dung TextField và đặt lại focus sau khi quay lại
      setState(() {
        _searchController.clear();
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            const Text('Search', style: TextStyle(color: Colors.black)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search dishes, restaurants...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchFocusNode.requestFocus();
                                    });
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onSubmitted: (value) {
                        // Khi người dùng nhấn Enter trên bàn phím
                        _performSearch(value.trim());
                      },
                      onChanged: (value) {
                        setState(
                          () {},
                        ); // Cập nhật giao diện để hiển thị/xóa suffixIcon
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),
              // Suggested Dishes
              const Text(
                'Suggested Dishes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                itemCount: _suggestedRestaurants.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 cột
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8, // Tỷ lệ chiều rộng/chiều cao của mỗi ô
                ),
                itemBuilder: (context, index) {
                  final dish = _suggestedRestaurants[index];
                  return GestureDetector(
                    onTap: () {
                      // Điều hướng khi nhấn vào món ăn, sử dụng tên món ăn làm từ khóa
                      _performSearch(dish['name']);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Giới hạn chiều cao
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .center, // Căn giữa theo chiều ngang
                      children: [
                        Container(
                          width: double.infinity,
                          height: 80, // Chiều cao hình ảnh
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[400], // Placeholder
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity, // Giới hạn chiều rộng bằng ô
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            dish['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
