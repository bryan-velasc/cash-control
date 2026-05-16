import 'dart:convert';

import 'package:http/http.dart' as http;

class GoalService {

static const String baseUrl =
    "http://10.0.9.132:8000";

  static Future<List> getGoals(
      String email) async {

    final response = await http.get(

      Uri.parse(
        "$baseUrl/goals/$email",
      ),
    );

    return jsonDecode(response.body);
  }

  static Future createGoal(

    String email,

    String goalName,

    double targetAmount,

  ) async {

    final response = await http.post(

      Uri.parse(
        "$baseUrl/goals/create",
      ),

      headers: {
        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "user_email": email,

        "goal_name": goalName,

        "target_amount": targetAmount,
      }),
    );

    return jsonDecode(response.body);
  }
}