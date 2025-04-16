import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          'http://10.0.2.2:3000', // Sử dụng 10.0.2.2 thay localhost cho Android emulator
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Thêm interceptor cho logging
  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
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
        onError: (DioException e, handler) {
          print('Error: ${e.message}');
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

      print("Raw API Response: ${response.data}"); // Debug

      // Kiểm tra status code thành công (201 theo response của bạn)
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        // Kiểm tra cấu trúc data
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
          'data': data['data'], // Trả về phần data chính
          'statusCode': response.statusCode,
        };
      }

      // Xử lý các mã lỗi
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
    await prefs.remove('auth_token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // static Future<List<dynamic>> getProducts() async {
  //   try {
  //     final response = await _dio.get('/products/page=1&limit=10');
  //     if (response.statusCode == 200) {
  //       return response.data['data'] as List<dynamic>;
  //     } else {
  //       throw Exception('Failed to load products');
  //     }
  //   } on DioException catch (e) {
  //     throw Exception('Failed to load products: ${e.message}');
  //   } catch (e) {
  //     throw Exception('Failed to load products: $e');
  //   }
  // }
}
