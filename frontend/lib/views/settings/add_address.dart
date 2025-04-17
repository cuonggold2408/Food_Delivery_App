import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_service.dart';

// Hàm gọi API để lưu địa chỉ
Future<void> saveAddress({
  required String address,
  required String street,
  required String apartment,
  // required String label,
  required String recipientName,
  required String phoneNumber,
  required String postalCode,
  required double latitude,
  required double longitude,
  required String token,
}) async {
  final url = Uri.parse('http://10.0.2.2:3000/user/address');
  print('URL: $url');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  final body = jsonEncode({
    'address_name': address,
    'street_address': street,
    'apartment': apartment,
    // 'label': label,
    'recipient_name': recipientName,
    'phone_number': phoneNumber,
    'postal_code': postalCode,
    'latitude': latitude,
    'longitude': longitude,
  });

  try {
    final response = await http.post(url, headers: headers, body: body);
    print('Response body: ${response.body}');
    print('Response status: ${response.statusCode}');
    if (response.statusCode == 201) {
      print('Địa chỉ đã được lưu thành công');
    } else {
      throw Exception(
        'Lỗi khi lưu địa chỉ: ${response.statusCode} - ${response.body}',
      );
    }
  } catch (e) {
    throw Exception('Lỗi kết nối: $e');
  }
}

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
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
);

const kButtonPadding = EdgeInsets.symmetric(horizontal: 30, vertical: 10);
const kSaveButtonPadding = EdgeInsets.symmetric(vertical: 15);
const kOrangeColor = Colors.deepOrange;
const kBackgroundColor = Color(0xFFF5F5F5);
const kMapHeightRatio = 1 / 3;
const kSpacing = 16.0;
const kDefaultLatLng = LatLng(21.0285, 105.8542);

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  String _selectedLabel = 'Home';
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<_MapSectionState> _mapSectionKey = GlobalKey();
  bool _isLoading = false;

  @override
  void dispose() {
    _streetController.dispose();
    _apartmentController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * kMapHeightRatio;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Add Address',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MapSection(
              key: _mapSectionKey,
              height: mapHeight,
              onLocationSelected: (LatLng position, String address) {
                setState(() {
                  _addressController.text = address;
                });
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: kSpacing),
                    AddressField(controller: _addressController),
                    const SizedBox(height: kSpacing),
                    StreetAndPostCodeSection(
                      streetController: _streetController,
                      isLoading: _isLoading,
                      onFindPressed: () async {
                        if (_addressController.text.isNotEmpty) {
                          if (_mapSectionKey.currentState != null) {
                            setState(() {
                              _isLoading = true;
                            });
                            await _mapSectionKey.currentState!
                                ._getCoordinatesFromAddress(
                                  _addressController.text,
                                );
                            setState(() {
                              _isLoading = false;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lỗi: Không thể truy cập bản đồ'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập địa chỉ'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: kSpacing),
                    ApartmentField(controller: _apartmentController),
                    const SizedBox(height: kSpacing),
                    LabelAsSection(
                      selectedLabel: _selectedLabel,
                      onLabelSelected: (label) {
                        setState(() => _selectedLabel = label);
                      },
                    ),
                    const SizedBox(height: kSpacing * 2),
                    SaveButton(
                      addressController: _addressController,
                      streetController: _streetController,
                      apartmentController: _apartmentController,
                      label: _selectedLabel,
                      mapSectionKey: _mapSectionKey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapSection extends StatefulWidget {
  final double height;
  final Function(LatLng, String) onLocationSelected;

  const MapSection({
    super.key,
    required this.height,
    required this.onLocationSelected,
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = kDefaultLatLng;
  Set<Marker> _markers = {};
  Map<LatLng, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật dịch vụ vị trí')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn'),
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _selectedPosition = newPosition;
          _updateMarkerAndAddress();
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newPosition, 15.0),
          );
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lấy vị trí: $e')));
      }
    }
  }

  Future<void> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng newPosition = LatLng(location.latitude, location.longitude);
        if (mounted) {
          setState(() {
            _selectedPosition = newPosition;
            _updateMarkerAndAddress();
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(newPosition, 15.0),
            );
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy địa chỉ')),
          );
        }
      }
    } catch (e) {
      print('Error forward geocoding: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tìm địa chỉ: $e')));
      }
    }
  }

  Future<void> _updateMarkerAndAddress() async {
    if (_addressCache.containsKey(_selectedPosition)) {
      widget.onLocationSelected(
        _selectedPosition,
        _addressCache[_selectedPosition]!,
      );
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
          ),
        };
      });
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
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

        _addressCache[_selectedPosition] = address;
        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: _selectedPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          };
        });
        widget.onLocationSelected(_selectedPosition, address);
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      widget.onLocationSelected(_selectedPosition, 'Error fetching address');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selectedPosition,
          zoom: 15.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: (LatLng position) {
          setState(() {
            _selectedPosition = position;
            _updateMarkerAndAddress();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

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
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class StreetAndPostCodeSection extends StatelessWidget {
  final TextEditingController streetController;
  final bool isLoading;
  final VoidCallback onFindPressed;

  const StreetAndPostCodeSection({
    super.key,
    required this.streetController,
    required this.isLoading,
    required this.onFindPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STREET', style: kLabelTextStyle),
              const SizedBox(height: 8),
              TextField(
                controller: streetController,
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter street',
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: kSpacing),
        ElevatedButton(
          onPressed: isLoading ? null : onFindPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: kOrangeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            minimumSize: const Size(80, 48),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Find',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
        ),
      ],
    );
  }
}

class ApartmentField extends StatelessWidget {
  final TextEditingController controller;

  const ApartmentField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('APARTMENT', style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: kTextFieldDecoration.copyWith(
            hintText: 'Enter apartment number',
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

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
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: kButtonPadding,
        elevation: 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }
}

class SaveButton extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController streetController;
  final TextEditingController apartmentController;
  final String label;
  final GlobalKey<_MapSectionState> mapSectionKey;

  const SaveButton({
    super.key,
    required this.addressController,
    required this.streetController,
    required this.apartmentController,
    required this.label,
    required this.mapSectionKey,
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrangeColor,
          padding: kSaveButtonPadding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed:
            _isSaving
                ? null
                : () async {
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    // Lấy token từ ApiService
                    final token = await ApiService.getToken();
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập để lưu địa chỉ'),
                        ),
                      );
                      return;
                    }

                    // Lấy giá trị mới nhất từ TextEditingController
                    final address = widget.addressController.text.trim();
                    final street = widget.streetController.text.trim();
                    final apartment = widget.apartmentController.text.trim();

                    // Kiểm tra dữ liệu đầu vào
                    if (address.isEmpty || street.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng điền địa chỉ và tên đường'),
                        ),
                      );
                      return;
                    }

                    // Lấy tọa độ từ MapSection
                    if (widget.mapSectionKey.currentState == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lỗi: Không thể truy cập bản đồ'),
                        ),
                      );
                      return;
                    }
                    final latLng =
                        widget.mapSectionKey.currentState!._selectedPosition;
                    final latitude = latLng.latitude;
                    final longitude = latLng.longitude;

                    // Giá trị cố định
                    const recipientName = 'QuocAnh';
                    const phoneNumber = '123';
                    const postalCode = '123';

                    // Debug giá trị đầu vào
                    print('Address: "$address"');
                    print('Street: "$street"');
                    print('Apartment: "$apartment"');
                    print('Label: "${widget.label}"');
                    print('Recipient Name: "$recipientName"');
                    print('Phone Number: "$phoneNumber"');
                    print('Postal Code: "$postalCode"');
                    print('Latitude: $latitude');
                    print('Longitude: $longitude');

                    await saveAddress(
                      address: address,
                      street: street,
                      apartment: apartment,
                      // label: widget.label,
                      recipientName: recipientName,
                      phoneNumber: phoneNumber,
                      postalCode: postalCode,
                      latitude: latitude,
                      longitude: longitude,
                      token: token,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Địa chỉ đã được lưu thành công'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
        child:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
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
