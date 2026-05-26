import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../services/transaction_service.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../services/notification_service.dart';
import '../services/goal_service.dart';

import '../providers/theme_provider.dart';

import 'add_transaction_screen.dart';
import 'login_screen.dart';
import 'goals_screen.dart';
import 'ocr_screen.dart';
import 'budgets_screen.dart';
import 'notifications_screen.dart';

import '../widgets/balance_card.dart';
import '../widgets/income_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/ai_advice_widget.dart';
import '../widgets/transactions_widget.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  final String email;

  const DashboardScreen({
    super.key,
    required this.email,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;

  double balance = 0;
  double income = 0;
  double expenses = 0;

  int unreadNotifications = 0;

  int totalGoals = 0;
  double totalGoalsSaved = 0;
  double totalGoalsTarget = 0;
  double goalsProgress = 0;

  List transactions = [];
  List advice = [];

  @override
  void initState() {
    super.initState();

    loadData();
    loadUnreadNotifications();
    loadGoalsSummary();
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final count = await NotificationService.getUnreadCount(
        widget.email,
      );

      setState(() {
        unreadNotifications = count;
      });
    } catch (e) {
      print("ERROR NOTIFICATIONS:");
      print(e);
    }
  }

  Future<void> loadGoalsSummary() async {
    try {
      final summary = await GoalService.getGoalsSummary(
        widget.email,
      );

      setState(() {
        totalGoals = summary["total_goals"];
        totalGoalsSaved = summary["total_saved"];
        totalGoalsTarget = summary["total_target"];
        goalsProgress = summary["average_progress"];
      });
    } catch (e) {
      print("ERROR GOALS SUMMARY:");
      print(e);
    }
  }

  List<PieChartSectionData> generatePieData() {
    return [
      PieChartSectionData(
        value: income,
        title: "Ingresos",
        radius: 70,
        color: Colors.green,
      ),
      PieChartSectionData(
        value: expenses,
        title: "Gastos",
        radius: 70,
        color: Colors.red,
      ),
    ];
  }

  List<FlSpot> generateChartData() {
    List<FlSpot> spots = [];

    double current = 0;

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];

      final amount = (tx["amount"] as num).toDouble();

      if (tx["type"] == "income") {
        current += amount;
      } else {
        current -= amount;
      }

      spots.add(
        FlSpot(
          i.toDouble(),
          current,
        ),
      );
    }

    if (spots.isEmpty) {
      spots.add(
        const FlSpot(
          0,
          0,
        ),
      );
    }

    return spots;
  }

  Future<void> loadData() async {
    try {
      final balanceData = await TransactionService.getBalance(
        widget.email,
      );

      final txData = await TransactionService.getTransactions(
        widget.email,
      );

      List adviceData = [];

      try {
        adviceData = await TransactionService.getFinancialAdvice(
          widget.email,
        );
      } catch (e) {
        print("ERROR IA:");
        print(e);
      }

      income = 0;
      expenses = 0;

      for (var tx in txData) {
        final amount = (tx["amount"] as num).toDouble();

        if (tx["type"] == "income") {
          income += amount;
        } else {
          expenses += amount;
        }
      }

      setState(() {
        balance = (balanceData["balance"] as num).toDouble();
        transactions = txData;
        advice = adviceData;
        loading = false;
      });
    } catch (e) {
      print("ERROR DASHBOARD:");
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> refreshDashboard() async {
    await loadData();
    await loadUnreadNotifications();
    await loadGoalsSummary();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      "user_email",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  Widget buildGoalsSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade400,
            Colors.blue.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Icon(
                  Icons.savings,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              const Expanded(
                child: Text(
                  "Resumen de Metas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          Text(
            "$totalGoals metas activas",
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 18,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            "Ahorrado: \$${totalGoalsSaved.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            "Objetivo: \$${totalGoalsTarget.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (goalsProgress / 100).clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            "${goalsProgress.toStringAsFixed(1)}% completado",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsScreen(
                      userEmail: widget.email,
                    ),
                  ),
                );

                loadGoalsSummary();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.flag,
              ),
              label: const Text(
                "Ver metas",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        backgroundColor: Colors.black,
        title: const Text(
          "CASH-CONTROL",
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: "Notificaciones",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                        email: widget.email,
                      ),
                    ),
                  );

                  loadUnreadNotifications();
                },
                icon: const Icon(
                  Icons.notifications,
                ),
              ),

              if (unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(
                      5,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            tooltip: "Agregar movimiento",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                    email: widget.email,
                  ),
                ),
              );

              refreshDashboard();
            },
            icon: const Icon(
              Icons.add,
            ),
          ),

          IconButton(
            tooltip: "Metas",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoalsScreen(
                    userEmail: widget.email,
                  ),
                ),
              );

              loadGoalsSummary();
            },
            icon: const Icon(
              Icons.flag,
            ),
          ),

          IconButton(
            tooltip: "Exportar PDF",
            onPressed: () {
              PdfService.generateReport(
                email: widget.email,
                balance: balance,
                income: income,
                expenses: expenses,
                transactions: transactions,
              );
            },
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
          ),

          IconButton(
            tooltip: "Exportar Excel",
            onPressed: () {
              ExcelService.exportExcel(
                email: widget.email,
                balance: balance,
                income: income,
                expenses: expenses,
                transactions: transactions,
              );
            },
            icon: const Icon(
              Icons.table_chart,
            ),
          ),
          
IconButton(
  tooltip: "OCR",
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OCRScreen(
          email: widget.email,
        ),
      ),
    );

    if (result == true) {
      refreshDashboard();
    }
  },
  icon: const Icon(
    Icons.camera_alt,
  ),
),

          IconButton(
            tooltip: "Cambiar tema",
            onPressed: () {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme();
            },
            icon: const Icon(
              Icons.dark_mode,
            ),
          ),

          IconButton(
            tooltip: "Presupuestos",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetsScreen(
                    email: widget.email,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.account_balance_wallet,
            ),
          ),

          IconButton(
            tooltip: "Cerrar sesión",
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceCard(
                        balance: balance,
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: IncomeCard(
                              income: income,
                            ),
                          ),

                          const SizedBox(
                            width: 15,
                          ),

                          Expanded(
                            child: ExpenseCard(
                              expenses: expenses,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      buildGoalsSummaryCard(),

                      const SizedBox(
                        height: 30,
                      ),

                      AiAdviceWidget(
                        advice: advice,
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      PieChartWidget(
                        income: income,
                        expenses: expenses,
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      GlassCard(
                        height: 300,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            20,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Evolución Financiera",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: false,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: false,
                                    ),
                                    borderData: FlBorderData(
                                      show: false,
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: generateChartData(),
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 4,
                                        dotData: FlDotData(
                                          show: false,
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      const Text(
                        "Movimientos",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      TransactionsWidget(
                        transactions: transactions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}