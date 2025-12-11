import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationApi {
  static const String baseUrl = "https://backend-olxs.onrender.com"; // 👈 अपने backend URL से replace करो

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse("$baseUrl/send-push");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "title": title,
          "body": body,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Push sent successfully: ${response.body}");
      } else {
        print("❌ Failed to send push: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error sending push: $e");
    }
  }
}
