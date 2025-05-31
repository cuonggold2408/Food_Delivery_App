import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Nếu đã có quyền, gọi hàm lấy vị trí mà không hiển thị dialog
      _requestLocationPermission();
    } else {
      // Nếu chưa có quyền, hiển thị dialog
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Yêu cầu quyền vị trí'),
            content: const Text(
              'DFOOD cần truy cập vị trí của bạn để cung cấp dịch vụ giao hàng tốt nhất. Chỉ sử dụng khi ứng dụng đang hoạt động.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToHomeScreen(null);
                },
                child: const Text('Từ chối'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _requestLocationPermission();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: const Text(
                  'Đồng ý',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dịch vụ vị trí đang tắt.'),
              action: SnackBarAction(
                label: 'Bật',
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  _requestLocationPermission();
                },
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Quyền truy cập vị trí bị từ chối vĩnh viễn.',
              ),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        _navigateToHomeScreen(null);
        return;
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cần quyền truy cập vị trí.'),
              action: SnackBarAction(
                label: 'Thử lại',
                onPressed: _requestLocationPermission,
              ),
            ),
          );
        }
        _navigateToHomeScreen(null);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Unknown location';
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        address = [
          placemark.street,
          placemark.locality,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', address);
      await prefs.setDouble('user_latitude', position.latitude);
      await prefs.setDouble('user_longitude', position.longitude);

      _navigateToHomeScreen(address);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lấy vị trí: $e')));
      }
      _navigateToHomeScreen(null);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHomeScreen(String? address) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.map, size: 150, color: Colors.grey[400]),
                        Icon(
                          Icons.location_pin,
                          size: 60,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'TRUY CẬP VỊ TRÍ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DFOOD sẽ truy cập vị trí của bạn chỉ khi sử dụng ứng dụng',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              ),
            ),
        ],
      ),
    );
  }
}
