import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';

// Định nghĩa API Key cho Goong
const goongApiKey = 'HnbVVYEre497owDt61e9wK2sFsvMLDWzXVx8QFA0';

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
Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
  final url = Uri.parse(
    'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=$goongApiKey',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['result'];
      final geometry = result['geometry']['location'];
      return {'latitude': geometry['lat'], 'longitude': geometry['lng']};
    } else {
      print('Goong Place Detail API error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching Goong place details: $e');
    return null;
  }
}

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});
  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  // ───────────────── constants ─────────────────
  static const _primaryColor = Color(0xFFFC6E2A);
  static const _textColor = Color(0xFF676767);
  static const _fontFamily = 'San Francisco';
  static const _spacing = 16.0;

  // ───────────────── form / state ──────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _cityCtr = TextEditingController();
  final _addressCtr = TextEditingController();
  File? _selectedImage;
  String? _fileName;
  String? _fileExt;
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;

  // ───────────────── helpers ───────────────────
  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('access_token');

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _textColor),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _primaryColor),
      borderRadius: BorderRadius.circular(10),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );

  // ───────────────── pick image ────────────────
  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;

    _fileName = p.basename(img.path);
    _fileExt = p.extension(img.path).replaceFirst('.', '').toLowerCase();

    debugPrint('🖼️  File: $_fileName — ext: $_fileExt');
    setState(() => _selectedImage = File(img.path));
  }

  // ───────────────── presigned URL ─────────────
  Future<Map<String, String>> _createPresignedUrl() async {
    final tkn = await _token();
    if (tkn == null) throw Exception('No access token');

    final res = await http.post(
      Uri.parse(
        'https://api.df.nguyenquangcuong.pro/media/images/upload/presigned-url',
      ),
      headers: {
        'Authorization': 'Bearer $tkn',
        'Content-Type': 'application/json',
      },
      body: json.encode({'fileName': _fileName}),
    );

    if (res.statusCode != 201) {
      throw Exception('Presigned-URL error ${res.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(res.body);
    final Map<String, dynamic> inner = body['data'] as Map<String, dynamic>;

    final String uploadUrl = inner['presignedUrl'] as String;
    final String publicUrl = inner['url'] as String;

    debugPrint('presignedUrl: $uploadUrl');
    debugPrint('publicUrl   : $publicUrl');

    return {'upload_url': uploadUrl, 'public_url': publicUrl};
  }

  // ───────────────── upload image ──────────────
  Future<String?> _uploadImageToS3() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploading = true);

    try {
      final presigned = await _createPresignedUrl();
      final putUrl = presigned['upload_url']!;
      final publicUrl = presigned['public_url']!;
      final bytes = await _selectedImage!.readAsBytes();
      final mimeType =
          lookupMimeType(_selectedImage!.path) ?? 'application/octet-stream';

      final res = await http.put(
        Uri.parse(putUrl),
        headers: {'Content-Type': mimeType},
        body: bytes,
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        debugPrint('✅ S3 upload OK');
        return publicUrl;
      }
      throw Exception('S3 upload fail ${res.statusCode}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ───────────────── submit ────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_addressCtr.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa chỉ')));
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một địa chỉ từ gợi ý')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imgUrl = await _uploadImageToS3();
      if (_selectedImage != null && imgUrl == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể tải ảnh')));
        setState(() => _isUploading = false);
        return;
      }

      final tkn = await _token();
      if (tkn == null) throw Exception('No access token');

      final body = json.encode({
        'name': _nameCtr.text,
        'city': _cityCtr.text,
        'address': _addressCtr.text,
        'shop_image_url': imgUrl ?? '',
        'latitude': _latitude,
        'longitude': _longitude,
      });

      final res = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/admin/restaurant'),
        headers: {
          'Authorization': 'Bearer $tkn',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã thêm: ${_nameCtr.text}')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ───────────────── UI ────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm Nhà hàng',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Quay lại trang Admin',
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04,
                vertical: _spacing,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameCtr,
                        decoration: _decor('Tên nhà hàng'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Vui lòng nhập tên nhà hàng'
                                    : null,
                      ),
                      SizedBox(height: _spacing),
                      TextFormField(
                        controller: _cityCtr,
                        decoration: _decor('Thành phố'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Vui lòng nhập thành phố'
                                    : null,
                      ),
                      SizedBox(height: _spacing),
                      AddressField(
                        controller: _addressCtr,
                        onPlaceSelected: (GoongPlace place) async {
                          final coords = await getPlaceDetails(place.placeId);
                          if (coords != null) {
                            setState(() {
                              _latitude = coords['latitude'];
                              _longitude = coords['longitude'];
                            });
                          } else {
                            setState(() {
                              _latitude = null;
                              _longitude = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không thể lấy toạ độ từ địa chỉ',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: _spacing),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fileName == null
                                  ? 'Chưa chọn hình ảnh'
                                  : 'Đã chọn: $_fileName ($_fileExt)',
                              style: const TextStyle(
                                fontSize: 16,
                                color: _textColor,
                                fontFamily: _fontFamily,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Chọn Hình ảnh'),
                          ),
                        ],
                      ),
                      if (_selectedImage != null)
                        Padding(
                          padding: EdgeInsets.only(top: _spacing),
                          child: Image.file(
                            _selectedImage!,
                            height: sh * 0.20,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(height: _spacing * 2),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.10,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child:
                              _isUploading
                                  ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                  : const Text('Thêm Nhà hàng'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
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
  String _lastSubmittedText = '';
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
              decoration: _AddRestaurantScreenState()
                  ._decor('Nhập địa chỉ')
                  .copyWith(
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                    ),
                    hintText: 'Nhập địa chỉ',
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
                  width: MediaQuery.of(context).size.width - 32,
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
