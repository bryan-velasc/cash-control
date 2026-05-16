import 'dart:convert';

import 'package:http/http.dart' as http;

class TransactionService {

static const String baseUrl =
    "http://10.0.9.132:8000";

  static Future<Map<String, dynamic>>
      createTransaction({

    required String email,

    required String type,

    required String category,

    required double amount,

    required String description,

  }) async {

    final response = await http.post(

      Uri.parse(
        "$baseUrl/transactions/create",
      ),

      headers: {
        "Content-Type":
            "application/json"
      },

      body: jsonEncode({

        "user_email": email,

        "type": type,

        "category": category,

        "amount": amount,

        "description": description
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>>
      getTransactions(
    String email,
  ) async {

    final response = await http.get(

      Uri.parse(
        "$baseUrl/transactions/$email",
      ),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>>
      getBalance(
    String email,
  ) async {

    final response = await http.get(

      Uri.parse(
        "$baseUrl/balance/$email",
      ),
    );

    return jsonDecode(response.body);
  }
  static Future<List<dynamic>>
    getFinancialAdvice(
  String email,
) async {

  final response = await http.get(

    Uri.parse(
      "$baseUrl/financial-advice/$email",
    ),
  );

  final data =
      jsonDecode(response.body);

  return data["advice"];
}
}