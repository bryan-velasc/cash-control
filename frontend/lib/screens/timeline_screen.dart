import 'package:flutter/material.dart';

import '../services/transaction_service.dart';

class TimelineScreen extends StatefulWidget {
  final String email;

  const TimelineScreen({
    super.key,
    required this.email,
  });

  @override
  State<TimelineScreen> createState() =>
      _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool loading = true;

  List timeline = [];

  @override
  void initState() {
    super.initState();
    loadTimeline();
  }

  Future<void> loadTimeline() async {
    try {
      final data = await TransactionService.getTimeline(
        widget.email,
      );

      setState(() {
        timeline = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Widget buildTimelineItem(dynamic tx, int index) {
    final type = tx["type"]?.toString() ?? "expense";
    final isIncome = type == "income";

    final amount = parseDouble(tx["amount"]);
    final category = tx["category"]?.toString() ?? "";
    final description = tx["description"]?.toString() ?? "";
    final note = tx["note"]?.toString() ?? "";
    final sourceName =
        tx["source_transaction_name"]?.toString() ?? "";
    final createdAt = tx["created_at"]?.toString() ?? "";

    final color =
        isIncome ? Colors.greenAccent : Colors.redAccent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 3,
              height: 130,
              color: Colors.white.withOpacity(0.12),
            ),
          ],
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isIncome
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isIncome ? "Entrada" : "Salida",
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${isIncome ? "+" : "-"}\$${amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14,
                  ),
                ),

                if (!isIncome && sourceName.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Origen: $sourceName",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                if (note.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Nota: $note",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Text(
                  createdAt,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.amberAccent.withOpacity(0.95),
            Colors.orangeAccent.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.timeline,
            color: Colors.black,
            size: 42,
          ),
          SizedBox(height: 14),
          Text(
            "Timeline Financiero",
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Consulta el recorrido cronológico de tus entradas, salidas, notas y origen del dinero.",
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

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 90,
              color: Colors.amberAccent.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sin movimientos",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Registra entradas y salidas para ver aquí tu historial financiero.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Timeline"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: loadTimeline,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : timeline.isEmpty
              ? buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadTimeline,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: timeline.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return buildHeader();
                      }

                      return buildTimelineItem(
                        timeline[index - 1],
                        index - 1,
                      );
                    },
                  ),
                ),
    );
  }
}