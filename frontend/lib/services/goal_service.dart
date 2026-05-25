import 'dart:convert';
import 'package:http/http.dart' as http;

class GoalService {
  static const String baseUrl =
      "https://cash-control-3vhg.onrender.com";

  static Future<List> getGoals(String email) async {
    final response = await http.get(
      Uri.parse("$baseUrl/goals/$email"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener metas");
    }
  }

  static Future createGoal(
    String email,
    String goalName,
    double targetAmount,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/goals/create"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "user_email": email,
        "goal_name": goalName,
        "target_amount": targetAmount,
        "current_amount": 0,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future addSaving(
    String goalId,
    double amount,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/goals/add-saving/$goalId"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "amount": amount,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future deleteGoal(String goalId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/goals/$goalId"),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getGoalsSummary(
    String email,
  ) async {
    final goals = await getGoals(email);

    double totalTarget = 0;
    double totalSaved = 0;

    for (var goal in goals) {
      totalTarget +=
          double.tryParse(goal["target_amount"].toString()) ?? 0;

      totalSaved +=
          double.tryParse(goal["current_amount"].toString()) ?? 0;
    }

    final double progress =
        totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;

    return {
      "total_goals": goals.length,
      "total_target": totalTarget,
      "total_saved": totalSaved,
      "average_progress": progress,
    };
  }
}