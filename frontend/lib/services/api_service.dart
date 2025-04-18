import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Lấy accessToken từ SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('Request: ${options.method} ${options.uri}');
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response: ${response.statusCode}');
          print('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print('Error: ${e.message}');
          // Xử lý lỗi 401 (token hết hạn)
          if (e.response?.statusCode == 401) {
            final refreshResult = await refreshToken();
            if (refreshResult['success']) {
              // Thử lại yêu cầu với token mới
              final options = e.requestOptions;
              final prefs = await SharedPreferences.getInstance();
              final newToken = prefs.getString('auth_token');
              if (newToken != null) {
                options.headers['Authorization'] = 'Bearer $newToken';
                try {
                  final retryResponse = await _dio.fetch(options);
                  return handler.resolve(retryResponse);
                } catch (retryError) {
                  return handler.next(e);
                }
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: jsonEncode({'email': email, 'password': password}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print("Raw API Response: ${response.data}");

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        // Kiểm tra xem accessToken có tồn tại trong response hay không
        if (data['data'] == null) {
          return {'success': false, 'error': 'Thiếu dữ liệu trong response'};
        }
        if (data['data']?['accessToken'] == null) {
          return {
            'success': false,
            'error': 'Thiếu access token trong response',
          };
        }

        // Lưu token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['data']['accessToken']);

        return {
          'success': true,
          'data': data['data'],
          'statusCode': response.statusCode,
        };
      }

      final errorMessage =
          response.data['message'] ?? 'Tài khoản hoặc mật khẩu không chính xác';
      return {'success': false, 'error': errorMessage};
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Lỗi không xác định';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Hết thời gian kết nối';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Hết thời gian nhận phản hồi';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi không xác định: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String confirmPassword,
    String code,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'code': code,
        },
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Đăng ký thất bại'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    String type = "REGISTER",
  }) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: jsonEncode({'email': email, 'type': type}),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Gửi mã OTP thất bại'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi không xác định: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await prefs.setString('auth_token', data['accessToken']);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Làm mới token thất bại'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi không xác định: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  // Hàm lấy thông tin user profile

  // Hàm lấy danh sách categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/restaurants/categories/');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'error': 'Không thể lấy danh sách categories'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  // Hàm lấy danh sách shops
  static Future<Map<String, dynamic>> getShops({
    required int page,
    required int limit,
    String? category,
  }) async {
    try {
      final queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null && category.isNotEmpty) 'category': category,
      };
      final response = await _dio.get(
        '/restaurants',
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'error': 'Không thể lấy danh sách nhà hàng'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
    // return prefs.containsKey('auth_token');
  }
}
