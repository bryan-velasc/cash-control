import 'package:flutter/material.dart';

import '../services/transaction_service.dart';

class MoneyFlowScreen extends StatefulWidget {
  final String email;

  const MoneyFlowScreen({
    super.key,
    required this.email,
  });

  @override
  State<MoneyFlowScreen> createState() =>
      _MoneyFlowScreenState();
}

class _MoneyFlowScreenState
    extends State<MoneyFlowScreen> {
  bool loading = true;

  List flow = [];

  @override
  void initState() {
    super.initState();
    loadMoneyFlow();
  }

  Future<void> loadMoneyFlow() async {
    try {
      final data = await TransactionService.getMoneyFlow(
        widget.email,
      );

      setState(() {
        flow = data["flow"] ?? [];
        loading = false;
      });
    } catch (e) {
      print("ERROR MONEY FLOW:");
      print(e);

      setState(() {
        loading = false;
      });

      showMessage(
        e.toString(),
      );
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  Widget buildIncomeFlowCard(dynamic item) {
    final description =
        item["description"]?.toString() ?? "Ingreso";

    final category =
        item["category"]?.toString() ?? "Entrada";

    final amount = parseDouble(item["amount"]);

    final used = parseDouble(item["used_amount"]);

    final remaining = parseDouble(
      item["remaining_amount"],
    );

    final usedPercentage = parseDouble(
      item["used_percentage"],
    );

    final expenses = item["linked_expenses"];

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.greenAccent,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: buildMiniMetric(
                  "Entró",
                  amount,
                  Colors.greenAccent,
                ),
              ),
              Expanded(
                child: buildMiniMetric(
                  "Usado",
                  used,
                  Colors.redAccent,
                ),
              ),
              Expanded(
                child: buildMiniMetric(
                  "Disponible",
                  remaining,
                  Colors.blueAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (usedPercentage / 100).clamp(
                0.0,
                1.0,
              ),
              minHeight: 14,
              backgroundColor:
                  Colors.white.withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${usedPercentage.toStringAsFixed(1)}% usado de esta entrada",
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Salidas ligadas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (expenses is List && expenses.isNotEmpty)
            ...expenses.map(
              (expense) => buildExpenseFlowItem(
                expense,
              ),
            )
          else
            Text(
              "No hay salidas ligadas a esta entrada.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.48),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildMiniMetric(
    String title,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "\$${value.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildExpenseFlowItem(dynamic expense) {
    final category =
        expense["category"]?.toString() ?? "Salida";

    final description =
        expense["description"]?.toString() ?? "";

    final note =
        expense["note"]?.toString() ?? "";

    final amount = parseDouble(expense["amount"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_downward,
            color: Colors.redAccent,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 13,
                  ),
                ),

                if (note.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Nota: $note",
                    style: TextStyle(
                      color: Colors.orangeAccent
                          .withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Text(
            "-\$${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 90,
              color: Colors.greenAccent.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sin flujo de dinero",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Registra entradas y liga salidas a una entrada específica para ver aquí la trazabilidad.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.95),
            Colors.tealAccent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_tree,
            color: Colors.black,
            size: 42,
          ),
          SizedBox(height: 14),
          Text(
            "Análisis de flujo de dinero",
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Visualiza de dónde entró tu dinero, en qué se usó y cuánto queda disponible.",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Flujo de dinero",
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: loadMoneyFlow,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : flow.isEmpty
              ? buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadMoneyFlow,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: flow.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return buildHeader();
                      }

                      return buildIncomeFlowCard(
                        flow[index - 1],
                      );
                    },
                  ),
                ),
    );
  }
}
