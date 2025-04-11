import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'ALL';

  // Constants for styling
  static const _primaryColor = Color(0xFFFC6E2A);
  static const _textColor = Color(0xFF676767);
  static const _fontFamily = 'San Francisco';
  static const _chipPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  static const _defaultChipColor = Color(0xFFECF0F4);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.01,
          ),
          child: SingleChildScrollView(
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
                _buildRestaurantsSection(context, screenWidth, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
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
            const Column(
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
          ],
        ),
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildCircularIcon(double screenWidth, {required Widget icon}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.06),
      child: Container(
        color: _defaultChipColor,
        width: screenWidth * 0.12,
        height: screenWidth * 0.12,
        child: icon,
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        const Icon(Icons.notifications, size: 28),
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(double screenWidth) {
    return Text(
      'Hey Halal, Good Afternoon!',
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('ALL', screenWidth, screenHeight),
              SizedBox(width: screenWidth * 0.02),
              _buildCategoryChip('Hot Dog', screenWidth, screenHeight),
              SizedBox(width: screenWidth * 0.02),
              _buildCategoryChip('Dog1', screenWidth, screenHeight),
              SizedBox(width: screenWidth * 0.02),
              _buildCategoryChip('Dog2', screenWidth, screenHeight),
              SizedBox(width: screenWidth * 0.02),
              _buildCategoryChip('Burg', screenWidth, screenHeight),
            ],
          ),
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
    final isSelected = _selectedCategory == label;
    final imagePath = _getImagePathForCategory(label);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
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
    switch (label) {
      case 'Hot Dog':
        return 'assets/images/vuongsonhien.jfif';
      case 'Dog1':
      case 'Dog2':
      case 'Burg':
      default:
        return 'assets/images/vuongsonhien.jfif';
    }
  }

  Widget _buildRestaurantsSection(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OPEN RESTAURANTS', 'SEE ALL'),
        SizedBox(height: screenHeight * 0.01),
        _buildRestaurantCard(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildRestaurantCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: screenHeight * 0.15,
            width: double.infinity,
            color: Colors.grey[400],
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rose Garden Restaurant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: _fontFamily,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  'Burger • Chicken • Rice • Wings',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                _buildRestaurantInfoRow(screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfoRow(double screenWidth) {
    return Row(
      children: [
        _buildInfoItem(Icons.star, '4.7', screenWidth, color: Colors.orange),
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
