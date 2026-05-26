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
import 'copilot_screen.dart';
import 'financial_health_screen.dart';

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
      final count = await NotificationService.getUnreadCount(widget.email);
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
      final summary = await GoalService.getGoalsSummary(widget.email);

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

      spots.add(FlSpot(i.toDouble(), current));
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return spots;
  }

  Future<void> loadData() async {
    try {
      final balanceData = await TransactionService.getBalance(widget.email);
      final txData = await TransactionService.getTransactions(widget.email);

      List adviceData = [];

      try {
        adviceData = await TransactionService.getFinancialAdvice(widget.email);
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
    await prefs.remove("user_email");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  Widget buildCopilotCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.95),
            Colors.tealAccent.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.smart_toy, color: Colors.black, size: 42),
          const SizedBox(height: 14),
          const Text(
            "Cash-Control AI Copilot",
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pregunta sobre tus gastos, metas, presupuestos y balance.",
            style: TextStyle(
              color: Colors.black.withOpacity(0.75),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CopilotScreen(email: widget.email),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text("Abrir Copilot"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFinancialHealthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.purpleAccent.withOpacity(0.95),
            Colors.deepPurpleAccent.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white, size: 42),
          const SizedBox(height: 14),
          const Text(
            "Salud Financiera IA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Consulta tu score, riesgo financiero y predicción de balance.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinancialHealthScreen(
                      email: widget.email,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_graph),
              label: const Text("Ver salud financiera"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
        ],
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
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumen de Metas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "$totalGoals metas activas",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 14),
          Text(
            "Ahorrado: \$${totalGoalsSaved.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Objetivo: \$${totalGoalsTarget.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 22),
          LinearProgressIndicator(
            value: (goalsProgress / 100).clamp(0.0, 1.0),
            minHeight: 14,
          ),
          const SizedBox(height: 12),
          Text(
            "${goalsProgress.toStringAsFixed(1)}% completado",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsScreen(userEmail: widget.email),
                  ),
                );

                loadGoalsSummary();
              },
              icon: const Icon(Icons.flag),
              label: const Text("Ver metas"),
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
        title: const Text("CASH-CONTROL"),
        actions: [
          IconButton(
            tooltip: "Salud Financiera IA",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FinancialHealthScreen(email: widget.email),
                ),
              );
            },
            icon: const Icon(Icons.health_and_safety),
          ),
          IconButton(
            tooltip: "AI Copilot",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CopilotScreen(email: widget.email),
                ),
              );
            },
            icon: const Icon(Icons.smart_toy),
          ),
          IconButton(
            tooltip: "Notificaciones",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(email: widget.email),
                ),
              );

              loadUnreadNotifications();
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            tooltip: "Agregar movimiento",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(email: widget.email),
                ),
              );

              refreshDashboard();
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: "Metas",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoalsScreen(userEmail: widget.email),
                ),
              );

              loadGoalsSummary();
            },
            icon: const Icon(Icons.flag),
          ),
          IconButton(
            tooltip: "OCR",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OCRScreen(email: widget.email),
                ),
              );

              if (result == true) {
                refreshDashboard();
              }
            },
            icon: const Icon(Icons.camera_alt),
          ),
          IconButton(
            tooltip: "Presupuestos",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetsScreen(email: widget.email),
                ),
              );

              refreshDashboard();
            },
            icon: const Icon(Icons.account_balance_wallet),
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
            icon: const Icon(Icons.picture_as_pdf),
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
            icon: const Icon(Icons.table_chart),
          ),
          IconButton(
            tooltip: "Cambiar tema",
            onPressed: () {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme();
            },
            icon: const Icon(Icons.dark_mode),
          ),
          IconButton(
            tooltip: "Cerrar sesión",
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceCard(balance: balance),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(child: IncomeCard(income: income)),
                          const SizedBox(width: 15),
                          Expanded(child: ExpenseCard(expenses: expenses)),
                        ],
                      ),
                      const SizedBox(height: 30),
                      buildCopilotCard(),
                      const SizedBox(height: 30),
                      buildFinancialHealthCard(),
                      const SizedBox(height: 30),
                      buildGoalsSummaryCard(),
                      const SizedBox(height: 30),
                      AiAdviceWidget(advice: advice),
                      const SizedBox(height: 30),
                      PieChartWidget(income: income, expenses: expenses),
                      const SizedBox(height: 30),
                      GlassCard(
                        height: 300,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
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
                              const SizedBox(height: 20),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: generateChartData(),
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 4,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Movimientos",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TransactionsWidget(transactions: transactions),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}