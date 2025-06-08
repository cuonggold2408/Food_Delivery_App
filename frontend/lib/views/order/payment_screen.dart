import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/firebase_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final String qrCodeUrl;
  final double totalPrice;
  final String accessToken;
  final String timeOut;
  final int orderId;

  const PaymentScreen({
    super.key,
    required this.qrCodeUrl,
    required this.totalPrice,
    required this.accessToken,
    required this.timeOut,
    required this.orderId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late IO.Socket socket;
  bool _isPaymentConfirmed = false;
  bool _isChecking = true;
  late Duration _remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _initializeTimer();
  }

  void _initializeSocket() {
    socket = IO.io(
      'https://api.df.nguyenquangcuong.pro/payment',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer ${widget.accessToken}'})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket.IO connected');
      socket.emit('joinPayment', {'token': widget.accessToken});
    });

    socket.on('payment', (data) async {
      if (data['status'] == 'success' && !_isPaymentConfirmed) {
        _isPaymentConfirmed = true;
        setState(() {
          _isChecking = false;
        });
        _timer?.cancel();
        await _showPaymentSuccessNotification();
      }
    });

    socket.onDisconnect((_) => debugPrint('Socket.IO disconnected'));
    socket.onError((err) => debugPrint('Socket.IO error: $err'));
  }

  void _initializeTimer() {
    DateTime timeout = DateTime.parse(widget.timeOut);
    _remainingTime = timeout.difference(DateTime.now());

    if (_remainingTime.inSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingTime = timeout.difference(DateTime.now());
          if (_remainingTime.inSeconds <= 0) {
            timer.cancel();
            if (!_isPaymentConfirmed && context.mounted) {
              _showTimeoutDialog();
            }
          }
        });
      });
    } else {
      _showTimeoutDialog();
    }
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hết thời gian thanh toán'),
        content: const Text('Thời gian thanh toán đã hết. Vui lòng thử lại.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    socket.dispose();
    super.dispose();
  }

  Future<void> _showPaymentSuccessNotification() async {
    // Trigger FCM push notification
    await FirebaseService.triggerPaymentSuccessNotification(
      widget.accessToken,
      widget.orderId,
    );

    // Show local notification
    await FirebaseService.showLocalNotification(
      title: 'Thanh toán thành công',
      body: 'Đơn hàng #${widget.orderId} của bạn đã được thanh toán thành công!',
      orderId: widget.orderId.toString(),
    );

    // Show in-app notification (SnackBar)
    FirebaseService.showPaymentSuccessInAppNotification(widget.orderId.toString());
  }

  String _formatPrice(double price) {
    final intNumber = price.toInt();
    return '${(intNumber ~/ 1000)}.${intNumber % 1000 == 0 ? '000' : (intNumber % 1000).toString().padLeft(3, '0')}₫';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thanh toán đơn hàng'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Quét mã QR để thanh toán',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.network(
                widget.qrCodeUrl,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/default_qr.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tổng thanh toán: ${_formatPrice(widget.totalPrice)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Thời gian còn lại: ${_formatDuration(_remainingTime)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vui lòng sử dụng ứng dụng ngân hàng để quét mã QR và hoàn tất thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaymentConfirmed
                    ? () {
                        _showPaymentSuccessNotification(); // Show notification when pressing "Hoàn tất"
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPaymentConfirmed ? Colors.red : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _isPaymentConfirmed ? 'Hoàn tất' : 'Đang chờ xác nhận...',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}