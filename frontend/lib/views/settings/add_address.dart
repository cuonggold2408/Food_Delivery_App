import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/views/settings/address_screen.dart';

// Định nghĩa API Key cho Goong
const goongApiKey = 'HnbVVYEre497owDt61e9wK2sFsvMLDWzXVx8QFA0';

// Hàm gọi API để lưu địa chỉ (thêm mới hoặc cập nhật)
Future<void> saveAddress({
  int? addressId,
  required String address,
  required String street,
  required String apartment,
  required String recipientName,
  required String phoneNumber,
  required String latitude,
  required String longitude,
  required String token,
  required String label,
}) async {
  final url =
      addressId == null
          ? Uri.parse('https://api.df.nguyenquangcuong.pro/user/address')
          : Uri.parse(
            'https://api.df.nguyenquangcuong.pro/user/address/$addressId',
          );
  final method = addressId == null ? http.post : http.put;

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  final body = jsonEncode({
    'address_name': address,
    'street_address': street,
    'apartment': apartment,
    'recipient_name': recipientName,
    'phone_number': phoneNumber,
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
  });

  try {
    final response = await method(url, headers: headers, body: body);
    print('Response body: ${response.body}');
    print('Response status: ${response.statusCode}');
    if (response.statusCode == 201 || response.statusCode == 200) {
      print(
        'Địa chỉ đã được ${addressId == null ? 'thêm' : 'cập nhật'} thành công',
      );
    } else {
      throw Exception(
        'Lỗi khi ${addressId == null ? 'thêm' : 'cập nhật'} địa chỉ: ${response.statusCode} - ${response.body}',
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

// Định nghĩa lớp GoongPlace để lưu trữ thông tin gợi ý địa chỉ
class GoongPlace {
  final String description;
  final String placeId;

  GoongPlace({required this.description, required this.placeId});

  factory GoongPlace.fromJson(Map<String, dynamic> json) {
    return GoongPlace(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
    );
  }
}

// Hàm lấy chi tiết địa chỉ từ Goong Place Detail API
Future<LatLng?> getPlaceDetails(String placeId) async {
  final url = Uri.parse(
    'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=$goongApiKey',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['result'];
      final geometry = result['geometry']['location'];
      return LatLng(geometry['lat'], geometry['lng']);
    } else {
      print('Goong Place Detail API error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching Goong place details: $e');
    return null;
  }
}

class AddAddressScreen extends StatefulWidget {
  final Address? address;
  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  String _selectedLabel = 'Home';
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final GlobalKey<_MapSectionState> _mapSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _addressController.text = widget.address!.addressName;
      _streetController.text = widget.address!.streetAddress;
      _apartmentController.text = widget.address!.apartment ?? '';
      _recipientNameController.text = widget.address!.recipientName ?? '';
      _phoneNumberController.text = widget.address!.phoneNumber ?? '';
      _selectedLabel = widget.address!.label;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _apartmentController.dispose();
    _addressController.dispose();
    _recipientNameController.dispose();
    _phoneNumberController.dispose();
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            MapSection(
              key: _mapSectionKey,
              height: mapHeight,
              isEditing: widget.address != null,
              onLocationSelected: (LatLng position, String address) {
                setState(() {
                  _addressController.text = address;
                });
              },
              initialPosition:
                  widget.address != null
                      ? LatLng(
                        double.parse(widget.address!.latitude),
                        double.parse(widget.address!.longitude),
                      )
                      : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: kSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: kSpacing),
                    AddressField(
                      controller: _addressController,
                      onPlaceSelected: (GoongPlace place) async {
                        final latLng = await getPlaceDetails(place.placeId);
                        if (latLng != null &&
                            _mapSectionKey.currentState != null) {
                          _mapSectionKey.currentState!._selectedPosition =
                              latLng;
                          await _mapSectionKey.currentState!
                              ._updateMarkerAndAddress();
                          _mapSectionKey.currentState!._mapController
                              ?.animateCamera(
                                CameraUpdate.newLatLngZoom(latLng, 15.0),
                              );
                        }
                      },
                    ),
                    const SizedBox(height: kSpacing),
                    StreetAndPostCodeSection(
                      streetController: _streetController,
                    ),
                    const SizedBox(height: kSpacing),
                    ApartmentField(controller: _apartmentController),
                    const SizedBox(height: kSpacing),
                    RecipientNameField(controller: _recipientNameController),
                    const SizedBox(height: kSpacing),
                    PhoneNumberField(controller: _phoneNumberController),
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
                      recipientNameController: _recipientNameController,
                      phoneNumberController: _phoneNumberController,
                      label: _selectedLabel,
                      mapSectionKey: _mapSectionKey,
                      address: widget.address,
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
  final bool isEditing;
  final LatLng? initialPosition;
  final Function(LatLng, String) onLocationSelected;

  const MapSection({
    super.key,
    required this.height,
    required this.isEditing,
    this.initialPosition,
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
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
      _updateMarkerAndAddress();
    } else {
      _getUserLocation();
    }
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
            CameraUpdate.newLatLngZoom(newPosition, _currentZoom),
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

  void _zoomIn() {
    if (_mapController != null) {
      setState(() {
        _currentZoom += 1;
        _mapController!.animateCamera(CameraUpdate.zoomIn());
      });
    }
  }

  void _zoomOut() {
    if (_mapController != null) {
      setState(() {
        _currentZoom -= 1;
        _mapController!.animateCamera(CameraUpdate.zoomOut());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: _currentZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (widget.isEditing) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_selectedPosition, _currentZoom),
                );
              }
            },
            onTap: (LatLng position) {
              setState(() {
                _selectedPosition = position;
                _updateMarkerAndAddress();
              });
            },
          ),
          Positioned(
            right: 10,
            bottom: 25,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _zoomIn,
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _zoomOut,
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class AddressField extends StatefulWidget {
  final TextEditingController controller;
  final Function(GoongPlace) onPlaceSelected;

  const AddressField({
    super.key,
    required this.controller,
    required this.onPlaceSelected,
  });

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  bool _isSubmitted = false;
  String _lastSubmittedText = ''; // Lưu giá trị text khi submit
  final _debouncer = Debouncer();

  Future<List<GoongPlace>> _fetchGoongSuggestions(String input) async {
    if (input.isEmpty || _isSubmitted) return [];

    final completer = Completer<List<GoongPlace>>();

    _debouncer.debounce(
      duration: const Duration(milliseconds: 500),
      onDebounce: () async {
        final url = Uri.parse(
          'https://rsapi.goong.io/Place/AutoComplete?input=$input&location=21.0285,105.8542&api_key=$goongApiKey',
        );
        try {
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final predictions = data['predictions'] as List<dynamic>;
            completer.complete(
              predictions
                  .map((prediction) => GoongPlace.fromJson(prediction))
                  .toList(),
            );
          } else {
            print('Goong API error: ${response.statusCode}');
            completer.complete([]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi API: ${response.statusCode}')),
              );
            }
          }
        } catch (e) {
          print('Error fetching Goong suggestions: $e');
          completer.complete([]);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
          }
        }
      },
    );

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _lastSubmittedText = widget.controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ADDRESS', style: kLabelTextStyle),
        const SizedBox(height: 8),
        Autocomplete<GoongPlace>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            return await _fetchGoongSuggestions(textEditingValue.text);
          },
          displayStringForOption: (GoongPlace option) => option.description,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            textEditingController.text = widget.controller.text;
            textEditingController.addListener(() {
              widget.controller.text = textEditingController.text;
              if (_isSubmitted &&
                  textEditingController.text != _lastSubmittedText) {
                setState(() {
                  _isSubmitted = false;
                });
              }
            });
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: kTextFieldDecoration.copyWith(
                prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                hintText: 'Enter your address',
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              onSubmitted: (value) {
                setState(() {
                  _isSubmitted = true;
                  _lastSubmittedText = value;
                });
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<GoongPlace> onSelected,
            Iterable<GoongPlace> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  width:
                      MediaQuery.of(context).size.width -
                      32, // Match TextField width
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final GoongPlace option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            option.description,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (GoongPlace place) {
            widget.controller.text = place.description;
            setState(() {
              _isSubmitted = true;
              _lastSubmittedText = place.description;
            });
            widget.onPlaceSelected(place);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}

class StreetAndPostCodeSection extends StatelessWidget {
  final TextEditingController streetController;

  const StreetAndPostCodeSection({super.key, required this.streetController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STREET', style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: streetController,
          decoration: kTextFieldDecoration.copyWith(
            hintText: 'Nhập tên đường',
            hintStyle: const TextStyle(color: Colors.grey),
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
            hintText: 'Nhập số căn hộ',
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class RecipientNameField extends StatelessWidget {
  final TextEditingController controller;

  const RecipientNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECIPIENT NAME', style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: kTextFieldDecoration.copyWith(
            hintText: 'Nhập tên người nhận',
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;

  const PhoneNumberField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PHONE NUMBER', style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: kTextFieldDecoration.copyWith(
            hintText: 'Nhập số điện thoại',
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
  final TextEditingController recipientNameController;
  final TextEditingController phoneNumberController;
  final String label;
  final GlobalKey<_MapSectionState> mapSectionKey;
  final Address? address;

  const SaveButton({
    super.key,
    required this.addressController,
    required this.streetController,
    required this.apartmentController,
    required this.recipientNameController,
    required this.phoneNumberController,
    required this.label,
    required this.mapSectionKey,
    required this.address,
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
                    final token = await ApiService.getToken();
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập để lưu địa chỉ'),
                        ),
                      );
                      return;
                    }

                    final address = widget.addressController.text.trim();
                    final street = widget.streetController.text.trim();
                    final apartment = widget.apartmentController.text.trim();
                    final recipientName =
                        widget.recipientNameController.text.trim();
                    final phoneNumber =
                        widget.phoneNumberController.text.trim();

                    if (address.isEmpty ||
                        street.isEmpty ||
                        recipientName.isEmpty ||
                        phoneNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng điền địa chỉ, tên đường, tên người nhận và số điện thoại',
                          ),
                        ),
                      );
                      return;
                    }

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
                    final latitude = latLng.latitude.toString();
                    final longitude = latLng.longitude.toString();

                    final addressId = widget.address?.id;

                    await saveAddress(
                      addressId: addressId,
                      address: address,
                      street: street,
                      apartment: apartment,
                      recipientName: recipientName,
                      phoneNumber: phoneNumber,
                      latitude: latitude,
                      longitude: longitude,
                      token: token,
                      label: widget.label,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Địa chỉ đã được ${addressId == null ? 'thêm' : 'cập nhật'} thành công',
                          ),
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
                  'SAVE ADDRESS',
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
