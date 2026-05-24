import 'dart:convert';

import 'package:http/http.dart'
    as http;

class BudgetService {

 static const String baseUrl =
    "https://cash-control-3vhg.onrender.com";

  static Future createBudget(

    String email,
    String category,
    double limit,

  ) async {

    final response =
        await http.post(

      Uri.parse(
        "$baseUrl/budgets/create",
      ),

      headers: {

        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "user_email": email,

        "category": category,

        "limit": limit,
      }),
    );

    return jsonDecode(
      response.body,
    );
  }

  static Future<List>
      getBudgets(
    String email,
  ) async {

    final response =
        await http.get(

      Uri.parse(
        "$baseUrl/budgets/$email",
      ),
    );

    return jsonDecode(
      response.body,
    );
  }
}