import 'dart:convert';

import 'package:http/http.dart' as http;

class TransactionService {
  static const String baseUrl =
      "https://cash-control-3vhg.onrender.com";

  static Future<Map<String, dynamic>> createTransaction({
    required String email,
    required String type,
    required String category,
    required double amount,
    required String description,
    String note = "",
    String sourceMode = "general",
    String? sourceTransactionId,
    String? sourceTransactionName,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/transactions/create"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "user_email": email,
        "type": type,
        "category": category,
        "amount": amount,
        "description": description,
        "note": note,
        "source_mode": sourceMode,
        "source_transaction_id": sourceTransactionId,
        "source_transaction_name": sourceTransactionName,
      }),
    );

    print("CREATE TRANSACTION STATUS: ${response.statusCode}");
    print("CREATE TRANSACTION BODY: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data["detail"]?.toString() ??
          "Error al crear movimiento",
    );
  }

  static Future<List<dynamic>> getTransactions(
    String email,
  ) async {
    final encodedEmail = Uri.encodeComponent(email);

    final response = await http.get(
      Uri.parse("$baseUrl/transactions/$encodedEmail"),
    );

    print("GET TRANSACTIONS STATUS: ${response.statusCode}");
    print("GET TRANSACTIONS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(
      "Error al cargar movimientos: ${response.body}",
    );
  }

  static Future<Map<String, dynamic>> getBalance(
    String email,
  ) async {
    final encodedEmail = Uri.encodeComponent(email);

    final response = await http.get(
      Uri.parse("$baseUrl/balance/$encodedEmail"),
    );

    print("GET BALANCE STATUS: ${response.statusCode}");
    print("GET BALANCE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Error al cargar balance: ${response.body}",
    );
  }

  static Future<List<dynamic>> getFinancialAdvice(
    String email,
  ) async {
    final encodedEmail = Uri.encodeComponent(email);

    final response = await http.get(
      Uri.parse("$baseUrl/financial-advice/$encodedEmail"),
    );

    print("FINANCIAL ADVICE STATUS: ${response.statusCode}");
    print("FINANCIAL ADVICE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["advice"] ?? [];
    }

    throw Exception(
      "Error al cargar consejos financieros: ${response.body}",
    );
  }

  static Future<List<dynamic>> getIncomeSources(
    String email,
  ) async {
    final encodedEmail = Uri.encodeComponent(email);

    final response = await http.get(
      Uri.parse("$baseUrl/transactions/income-sources/$encodedEmail"),
    );

    print("INCOME SOURCES STATUS: ${response.statusCode}");
    print("INCOME SOURCES BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(
      "Error al cargar fuentes de ingreso: ${response.body}",
    );
  }

  static Future<Map<String, dynamic>> getChartSummary(
    String email,
  ) async {
    final encodedEmail = Uri.encodeComponent(email);

    final response = await http.get(
      Uri.parse("$baseUrl/transactions/chart-summary/$encodedEmail"),
    );

    print("CHART SUMMARY STATUS: ${response.statusCode}");
    print("CHART SUMMARY BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Error al cargar resumen de gráficas: ${response.body}",
    );
  }

  static Future<Map<String, dynamic>> getIncomeDetail(
    String incomeId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/transactions/income-detail/$incomeId"),
    );

    print("INCOME DETAIL STATUS: ${response.statusCode}");
    print("INCOME DETAIL BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final data = jsonDecode(response.body);

    throw Exception(
      data["detail"]?.toString() ??
          "Error al cargar detalle del ingreso",
    );
  }

  static Future<Map<String, dynamic>> getMoneyFlow(
    String email,
  ) async {
    final encodedEmail = Uri.encodeComponent(email);

    final response = await http.get(
      Uri.parse("$baseUrl/transactions/money-flow/$encodedEmail"),
    );

    print("MONEY FLOW STATUS: ${response.statusCode}");
    print("MONEY FLOW BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Error al cargar flujo de dinero: ${response.body}",
    );
  }
}