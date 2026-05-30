import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'security_shield_screen.dart';
import 'money_flow_screen.dart';

import '../widgets/balance_card.dart';
import '../widgets/income_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/ai_advice_widget.dart';
import '../widgets/transactions_widget.dart';
import '../widgets/financial_pies_widget.dart';

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

  Map<String, dynamic>? chartSummary;

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
        totalGoals = summary["total_goals"] ?? 0;
        totalGoalsSaved =
            (summary["total_saved"] as num?)?.toDouble() ?? 0;
        totalGoalsTarget =
            (summary["total_target"] as num?)?.toDouble() ?? 0;
        goalsProgress =
            (summary["average_progress"] as num?)?.toDouble() ?? 0;
      });
    } catch (e) {
      print("ERROR GOALS SUMMARY:");
      print(e);
    }
  }

  Future<void> loadData() async {
    try {
      final balanceData = await TransactionService.getBalance(
        widget.email,
      );

      final txData = await TransactionService.getTransactions(
        widget.email,
      );

      Map<String, dynamic>? chartData;

      try {
        chartData = await TransactionService.getChartSummary(
          widget.email,
        );
      } catch (e) {
        print("ERROR CHART SUMMARY:");
        print(e);
      }

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
        chartSummary = chartData;
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

  Widget buildWelcomeHeader() {
    final name = widget.email.split("@").first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.95),
            Colors.tealAccent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hola, $name",
            style: TextStyle(
              color: Colors.black.withOpacity(0.72),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tu control financiero inteligente",
            style: TextStyle(
              color: Colors.black,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.black,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "\$${balance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Balance disponible actual",
            style: TextStyle(
              color: Colors.black.withOpacity(0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuickAccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Accesos rápidos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tus herramientas principales en un solo lugar.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              buildQuickButton(
                title: "Movimiento",
                icon: Icons.add,
                color: Colors.greenAccent,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(
                        email: widget.email,
                      ),
                    ),
                  );

                  if (result == true) {
                    refreshDashboard();
                  }
                },
              ),
              buildQuickButton(
                title: "OCR",
                icon: Icons.camera_alt,
                color: Colors.orangeAccent,
                onTap: () async {
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
              ),
              buildQuickButton(
                title: "Metas",
                icon: Icons.flag,
                color: Colors.blueAccent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoalsScreen(
                        userEmail: widget.email,
                      ),
                    ),
                  );

                  refreshDashboard();
                },
              ),
              buildQuickButton(
                title: "Presup.",
                icon: Icons.account_balance_wallet,
                color: Colors.purpleAccent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetsScreen(
                        email: widget.email,
                      ),
                    ),
                  );

                  refreshDashboard();
                },
              ),
              buildQuickButton(
                title: "Flujo",
                icon: Icons.account_tree,
                color: Colors.greenAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MoneyFlowScreen(
                        email: widget.email,
                      ),
                    ),
                  );
                },
              ),
              buildQuickButton(
                title: "Shield",
                icon: Icons.security,
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SecurityShieldScreen(
                        email: widget.email,
                      ),
                    ),
                  );
                },
              ),
              buildQuickButton(
                title: "IA",
                icon: Icons.smart_toy,
                color: Colors.tealAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CopilotScreen(
                        email: widget.email,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildQuickButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withOpacity(0.35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 31,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCopilotCard() {
    return buildPremiumActionCard(
      title: "Cash-Control AI Copilot",
      subtitle:
          "Pregunta sobre tus gastos, metas, presupuestos y balance.",
      icon: Icons.smart_toy,
      colors: [
        Colors.greenAccent.withOpacity(0.95),
        Colors.tealAccent.withOpacity(0.85),
      ],
      iconColor: Colors.black,
      textColor: Colors.black,
      buttonText: "Abrir Copilot",
      buttonIcon: Icons.chat,
      buttonBackground: Colors.black,
      buttonForeground: Colors.greenAccent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CopilotScreen(
              email: widget.email,
            ),
          ),
        );
      },
    );
  }

  Widget buildFinancialHealthCard() {
    return buildPremiumActionCard(
      title: "Salud Financiera IA",
      subtitle:
          "Consulta tu score, riesgo financiero y predicción de balance.",
      icon: Icons.health_and_safety,
      colors: [
        Colors.purpleAccent.withOpacity(0.95),
        Colors.deepPurpleAccent.withOpacity(0.85),
      ],
      iconColor: Colors.white,
      textColor: Colors.white,
      buttonText: "Ver salud financiera",
      buttonIcon: Icons.auto_graph,
      buttonBackground: Colors.white,
      buttonForeground: Colors.deepPurple,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FinancialHealthScreen(
              email: widget.email,
            ),
          ),
        );
      },
    );
  }

  Widget buildSecurityShieldCard() {
    return buildPremiumActionCard(
      title: "Security Shield",
      subtitle:
          "Detecta phishing, fraude, SMS peligrosos y enlaces maliciosos.",
      icon: Icons.security,
      colors: [
        Colors.redAccent.withOpacity(0.95),
        Colors.deepOrangeAccent.withOpacity(0.85),
      ],
      iconColor: Colors.white,
      textColor: Colors.white,
      buttonText: "Abrir Security Shield",
      buttonIcon: Icons.shield,
      buttonBackground: Colors.white,
      buttonForeground: Colors.redAccent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityShieldScreen(
              email: widget.email,
            ),
          ),
        );
      },
    );
  }

  Widget buildMoneyFlowCard() {
    return buildPremiumActionCard(
      title: "Análisis de Flujo de Dinero",
      subtitle:
          "Visualiza exactamente de dónde entró tu dinero, en qué se gastó y cuánto queda disponible.",
      icon: Icons.account_tree,
      colors: [
        Colors.greenAccent.withOpacity(0.95),
        Colors.tealAccent.withOpacity(0.85),
      ],
      iconColor: Colors.black,
      textColor: Colors.black,
      buttonText: "Abrir análisis",
      buttonIcon: Icons.analytics,
      buttonBackground: Colors.black,
      buttonForeground: Colors.greenAccent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MoneyFlowScreen(
              email: widget.email,
            ),
          ),
        );
      },
    );
  }

  Widget buildPremiumActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required Color iconColor,
    required Color textColor,
    required String buttonText,
    required IconData buttonIcon,
    required Color buttonBackground,
    required Color buttonForeground,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackground,
                foregroundColor: buttonForeground,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: (goalsProgress / 100).clamp(
                0.0,
                1.0,
              ),
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(
                0.2,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
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
                    builder: (_) => GoalsScreen(
                      userEmail: widget.email,
                    ),
                  ),
                );

                refreshDashboard();
              },
              icon: const Icon(Icons.flag),
              label: const Text("Ver metas"),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Exportaciones",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Genera tus reportes financieros en PDF o Excel.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
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
                  label: const Text("PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
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
                  label: const Text("Excel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget buildCleanAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Text(
        "CASH-CONTROL",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
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
        PopupMenuButton<String>(
          color: const Color(0xFF151515),
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == "theme") {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme();
            }

            if (value == "logout") {
              logout();
            }
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem(
                value: "theme",
                child: Row(
                  children: [
                    Icon(
                      Icons.dark_mode,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Cambiar tema",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Cerrar sesión",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: buildCleanAppBar(),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: refreshDashboard,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      buildWelcomeHeader(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: IncomeCard(
                              income: income,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ExpenseCard(
                              expenses: expenses,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      BalanceCard(
                        balance: balance,
                      ),
                      const SizedBox(height: 30),
                      buildQuickAccessCard(),
                      const SizedBox(height: 30),
                      if (chartSummary != null)
                        FinancialPiesWidget(
                          chartSummary: chartSummary!,
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151515),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            "No se pudo cargar el resumen de gráficas.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                      buildMoneyFlowCard(),
                      const SizedBox(height: 30),
                      buildCopilotCard(),
                      const SizedBox(height: 30),
                      buildFinancialHealthCard(),
                      const SizedBox(height: 30),
                      buildSecurityShieldCard(),
                      const SizedBox(height: 30),
                      buildGoalsSummaryCard(),
                      const SizedBox(height: 30),
                      AiAdviceWidget(
                        advice: advice,
                      ),
                      const SizedBox(height: 30),
                      buildExportCard(),
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