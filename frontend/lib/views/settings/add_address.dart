import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// Định nghĩa các hằng số chung
const kLabelTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: Colors.black54,
);

const kTextFieldDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide.none,
  ),
);

const kButtonPadding = EdgeInsets.symmetric(horizontal: 30, vertical: 10);
const kSaveButtonPadding = EdgeInsets.symmetric(vertical: 15);
const kOrangeColor = Colors.orange;
const kBackgroundColor = Colors.grey;
const kMapHeightRatio = 1 / 3; // Tỷ lệ chiều cao bản đồ (1/3 màn hình)
const kSpacing = 16.0; // Khoảng cách giữa các thành phần
const kDefaultLatLng = LatLng(40.7128, -74.0060); // Tọa độ mặc định (New York)

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  String _selectedLabel = 'Home'; // Mặc định chọn "Home"
  GoogleMapController? _mapController;
  LatLng _currentPosition = kDefaultLatLng; // Vị trí hiện tại trên bản đồ
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Lấy vị trí hiện tại khi khởi tạo
    _addressController.addListener(
      _onAddressChanged,
    ); // Lắng nghe thay đổi địa chỉ
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _addressController.dispose();
    _streetController.dispose();
    _postCodeController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  // Lấy vị trí hiện tại của người dùng
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có được bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Kiểm tra và yêu cầu quyền truy cập vị trí
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Di chuyển bản đồ đến vị trí hiện tại
    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));

    // Cập nhật địa chỉ từ tọa độ
    _updateAddressFromCoordinates(_currentPosition);
  }

  // Chuyển địa chỉ thành tọa độ và cập nhật bản đồ
  Future<void> _onAddressChanged() async {
    String address = _addressController.text;
    if (address.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng newPosition = LatLng(location.latitude, location.longitude);
        setState(() {
          _currentPosition = newPosition;
        });

        // Di chuyển bản đồ đến vị trí mới
        _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
  }

  // Chuyển tọa độ thành địa chỉ và cập nhật trường Address
  Future<void> _updateAddressFromCoordinates(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.postalCode,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address;
          _streetController.text = placemark.street ?? '';
          _postCodeController.text = placemark.postalCode ?? '';
        });
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * kMapHeightRatio;

    return Scaffold(
      backgroundColor: kBackgroundColor[200],
      body: SafeArea(
        child: Column(
          children: [
            // Phần bản đồ
            MapSection(
              height: mapHeight,
              position: _currentPosition,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onBackPressed: () => Navigator.pop(context),
            ),
            // Phần nội dung chính
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: kSpacing),
                      AddressField(controller: _addressController),
                      const SizedBox(height: kSpacing),
                      StreetAndPostCodeSection(
                        streetController: _streetController,
                        postCodeController: _postCodeController,
                      ),
                      const SizedBox(height: kSpacing),
                      ApartmentField(controller: _apartmentController),
                      const SizedBox(height: kSpacing),
                      LabelAsSection(
                        selectedLabel: _selectedLabel,
                        onLabelSelected: (label) {
                          setState(() {
                            _selectedLabel = label;
                          });
                        },
                      ),
                      const SizedBox(height: kSpacing),
                      SaveButton(
                        onPressed: () {
                          // Logic lưu địa chỉ
                          print('Address: ${_addressController.text}');
                          print('Street: ${_streetController.text}');
                          print('Post Code: ${_postCodeController.text}');
                          print('Apartment: ${_apartmentController.text}');
                          print('Label: $_selectedLabel');
                          print('Coordinates: $_currentPosition');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget cho phần bản đồ
class MapSection extends StatelessWidget {
  final double height;
  final LatLng position;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onBackPressed;

  const MapSection({
    super.key,
    required this.height,
    required this.position,
    required this.onMapCreated,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: 15),
            onMapCreated: onMapCreated,
            markers: {
              Marker(
                markerId: const MarkerId('current_position'),
                position: position,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Padding(
            padding: const EdgeInsets.all(kSpacing),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: onBackPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget cho trường Address
class AddressField extends StatelessWidget {
  final TextEditingController controller;

  const AddressField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ADDRESS', style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: kTextFieldDecoration.copyWith(
            prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
            hintText: 'Enter your address',
          ),
        ),
      ],
    );
  }
}

// Widget cho phần Street và Post Code
class StreetAndPostCodeSection extends StatelessWidget {
  final TextEditingController streetController;
  final TextEditingController postCodeController;

  const StreetAndPostCodeSection({
    super.key,
    required this.streetController,
    required this.postCodeController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            label: 'STREET',
            hintText: 'Enter street',
            controller: streetController,
          ),
        ),
        const SizedBox(width: kSpacing),
        Expanded(
          child: CustomTextField(
            label: 'POST CODE',
            hintText: 'Enter post code',
            controller: postCodeController,
          ),
        ),
      ],
    );
  }
}

// Widget cho trường Apartment
class ApartmentField extends StatelessWidget {
  final TextEditingController controller;

  const ApartmentField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'APARTMENT',
      hintText: 'Enter apartment number',
      controller: controller,
    );
  }
}

// Widget chung cho các trường TextField
class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: kTextFieldDecoration.copyWith(hintText: hintText),
        ),
      ],
    );
  }
}

// Widget cho phần Label As
class LabelAsSection extends StatelessWidget {
  final String selectedLabel;
  final Function(String) onLabelSelected;

  const LabelAsSection({
    super.key,
    required this.selectedLabel,
    required this.onLabelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LABEL AS', style: kLabelTextStyle),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LabelButton(
              label: 'Home',
              isSelected: selectedLabel == 'Home',
              onPressed: () => onLabelSelected('Home'),
            ),
            LabelButton(
              label: 'Work',
              isSelected: selectedLabel == 'Work',
              onPressed: () => onLabelSelected('Work'),
            ),
            LabelButton(
              label: 'Other',
              isSelected: selectedLabel == 'Other',
              onPressed: () => onLabelSelected('Other'),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget cho các nút Label (Home, Work, Other)
class LabelButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const LabelButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? kOrangeColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: kButtonPadding,
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }
}

// Widget cho nút Save Location
class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrangeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: kSaveButtonPadding,
        ),
        child: const Text(
          'SAVE LOCATION',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
