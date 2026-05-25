import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationService {

  static const String baseUrl =
      "https://cash-control-3vhg.onrender.com";

  static Future<List<dynamic>>
      getNotifications(
    String email,
  ) async {

    final response = await http.get(

      Uri.parse(
        "$baseUrl/notifications/$email",
      ),
    );

    return jsonDecode(
      response.body,
    );
  }

  static Future<void> markAsRead(
    String id,
  ) async {

    await http.put(

      Uri.parse(
        "$baseUrl/notifications/read/$id",
      ),
    );
  }

  static Future<void> deleteNotification(
    String id,
  ) async {

    await http.delete(

      Uri.parse(
        "$baseUrl/notifications/$id",
      ),
    );
  }
}