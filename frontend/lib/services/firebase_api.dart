import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/main.dart'; // Import the navigator key

class FirebaseApi {
  // create an instance of Firebase Messaging
  final _firebaseMessage = FirebaseMessaging.instance;

  // function to initialize notifications
  Future<void> initNotifications() async {
    // request premission from user (will prompt user)
    await _firebaseMessage.requestPermission();

    // fetch the FCM token for this device
    final fCMToken = await _firebaseMessage.getToken();

    // print the token (normally you would send this to your server)
    print('Token: $fCMToken');

    // initialize further setting for push noti
    initPushNotifications();
  }

  // functions to handle received messages
  void handleMessage(RemoteMessage? message) {
    // Nếu không cần xử lý nội dung thông báo, chỉ cần điều hướng đến trang từ điển
    navigatorKey.currentState?.popAndPushNamed('/home');
  }

  // functions to initialize foreground and background settings
  Future initPushNotifications() async {
    // handle notification if the app was terminated and now opened
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // attach event listeners for when a notification opens the app
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}