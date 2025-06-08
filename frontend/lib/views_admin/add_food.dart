import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddNewItemScreen extends StatefulWidget {
  final String restaurantId;

  const AddNewItemScreen({super.key, required this.restaurantId});

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  // Controllers
  final _nameCtr = TextEditingController(text: 'Mazalichiken Halim');
  final _priceCtr = TextEditingController(text: '50');
  final _detailCtr = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Image handling
  File? _selectedImage;
  String? _fileName;
  String? _fileExt;
  bool _isUploading = false;

  // Colors
  static const _primary = Color(0xFFFC6E2A);
  static const _greyText = Color(0xFF676767);
  static const _greyHint = Color(0xFF9AA1A9);
  static const _greyBorder = Color(0xFFE1E4E8);
  static const _fill = Color(0xFFF8F9FB);

  @override
  void dispose() {
    _nameCtr.dispose();
    _priceCtr.dispose();
    _detailCtr.dispose();
    super.dispose();
  }

  // Lấy access token
  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Chọn ảnh
  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;

    _fileName = p.basename(img.path);
    _fileExt = p.extension(img.path).replaceFirst('.', '').toLowerCase();

    debugPrint('🖼️  File: $_fileName — ext: $_fileExt');
    setState(() => _selectedImage = File(img.path));
  }

  // Tạo presigned URL
  Future<Map<String, String>> _createPresignedUrl() async {
    final tkn = await _token();
    if (tkn == null) throw Exception('Không tìm thấy access token');

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
      throw Exception('Lỗi tạo presigned URL: ${res.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(res.body);
    final Map<String, dynamic> inner = body['data'] as Map<String, dynamic>;

    final String uploadUrl = inner['presignedUrl'] as String;
    final String publicUrl = inner['url'] as String;

    debugPrint('presignedUrl: $uploadUrl');
    debugPrint('publicUrl   : $publicUrl');

    return {'upload_url': uploadUrl, 'public_url': publicUrl};
  }

  // Tải ảnh lên S3
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
      throw Exception('Tải ảnh lên S3 thất bại: ${res.statusCode}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Lưu món ăn
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final imgUrl = await _uploadImageToS3();
      if (_selectedImage != null && imgUrl == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể tải ảnh')));
        return;
      }

      final tkn = await _token();
      if (tkn == null) throw Exception('Không tìm thấy access token');

      final body = json.encode({
        'name': _nameCtr.text,
        'price': int.tryParse(_priceCtr.text) ?? 0,
        'description': _detailCtr.text,
        'image_url': imgUrl ?? '',
      });

      final res = await http.post(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/admin/restaurant/${widget.restaurantId}/food',
        ),
        headers: {
          'Authorization': 'Bearer $tkn',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm món: ${_nameCtr.text}')),
        );
        Navigator.pop(context, true); // Trả về kết quả để làm mới danh sách
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm món: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final gapH = h * 0.022; // vertical gap
    final gapW = w * 0.05; // horizontal padding
    final fieldH = h * 0.06; // height of input
    final box = (w - gapW * 2 - 2 * w * 0.02) / 3;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: gapW, vertical: gapH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onReset: _reset),
                SizedBox(height: gapH * 1.2),

                _Label('TÊN MÓN ĂN'),
                _RoundedInput(
                  controller: _nameCtr,
                  hint: 'Tên món ăn',
                  height: fieldH,
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Vui lòng nhập tên món ăn' : null,
                ),
                SizedBox(height: gapH),

                _Label('ẢNH/VIDEO'),
                SizedBox(height: h * 0.015),
                _UploadRow(
                  box: box,
                  onPickImage: _pickImage,
                  image: _selectedImage,
                ),

                SizedBox(height: gapH * 1.2),
                _Label('GIÁ'),
                SizedBox(height: h * 0.012),
                Row(
                  children: [
                    SizedBox(
                      width: w * 0.28,
                      child: _RoundedInput(
                        controller: _priceCtr,
                        hint: '50',
                        height: fieldH,
                        keyboard: TextInputType.number,
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 6),
                          child: Text(
                            r'$',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: _greyText,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Vui lòng nhập giá';
                          final price = int.tryParse(value);
                          if (price == null || price <= 0)
                            return 'Giá phải là số dương';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: gapH * 1.2),
                _Label('CHI TIẾT'),
                _RoundedInput(
                  controller: _detailCtr,
                  hint: 'Mô tả món ăn...',
                  height: h * 0.18,
                  multiline: true,
                ),

                SizedBox(height: gapH * 1.5),
                SizedBox(
                  width: double.infinity,
                  height: h * 0.07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isUploading ? null : _saveItem,
                    child:
                        _isUploading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'LƯU THAY ĐỔI',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reset() => setState(() {
    _nameCtr.clear();
    _priceCtr.text = '50';
    _detailCtr.clear();
    _selectedImage = null;
    _fileName = null;
    _fileExt = null;
  });

  Widget _Label(String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      txt,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 12,
        letterSpacing: .6,
        color: _greyHint,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/*──────────────── Header ─────────────────*/
class _Header extends StatelessWidget {
  const _Header({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return Row(
      children: [
        Container(
          width: w * 0.12,
          height: w * 0.12,
          decoration: const BoxDecoration(
            color: Color(0xFFEDEFF1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: w * 0.05),
            color: const Color(0xFF424242),
            onPressed: () => Navigator.maybePop(ctx),
          ),
        ),
        SizedBox(width: w * 0.04),
        Expanded(
          child: Text(
            'Thêm Món Mới',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: w * 0.05,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
        ),
        TextButton(
          onPressed: onReset,
          child: const Text(
            'RESET',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: _AddNewItemScreenState._primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/*──────────────── Upload Row ─────────────*/
class _UploadRow extends StatelessWidget {
  const _UploadRow({
    required this.box,
    required this.onPickImage,
    required this.image,
  });
  final double box;
  final VoidCallback onPickImage;
  final File? image;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (i) {
        return SizedBox(
          width: box,
          height: box,
          child:
              i == 0 && image != null
                  ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: FileImage(image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  : DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(14),
                    dashPattern: const [6, 4],
                    color: _AddNewItemScreenState._greyHint,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onPickImage,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFEAE7FF),
                                  child: Icon(
                                    Icons.upload,
                                    size: 20,
                                    color: Color(0xFF6D5DF9),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Thêm',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13,
                                    color: _AddNewItemScreenState._greyHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
        );
      }),
    );
  }
}

/*──────────────── Rounded Input ───────────*/
class _RoundedInput extends StatelessWidget {
  const _RoundedInput({
    required this.controller,
    required this.hint,
    required this.height,
    this.multiline = false,
    this.prefix,
    this.keyboard,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final double height;
  final bool multiline;
  final Widget? prefix;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: multiline ? null : height,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _AddNewItemScreenState._fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AddNewItemScreenState._greyBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: multiline ? null : 1,
        minLines: multiline ? 4 : 1,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: _AddNewItemScreenState._greyText,
          ),
        ),
        style: const TextStyle(fontFamily: 'Roboto', fontSize: 16),
      ),
    );
  }
}
