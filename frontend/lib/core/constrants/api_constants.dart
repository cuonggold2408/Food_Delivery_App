// core/constants/api_constants.dart
abstract class ApiConstants {
  static const connectionTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 5);
}

abstract class ApiEndpoints {
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh';
  static const register = '/auth/register';
  static const verifyEmail = '/auth/verify-email';
  static const verifyOtp = '/auth/verify-otp';
  static const forgotPassword = '/auth/forgot-password';
  static const getUser = '/user/profile';

}
