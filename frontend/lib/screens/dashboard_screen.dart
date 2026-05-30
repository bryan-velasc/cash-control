import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/transaction_service.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../services/notification_service.dart';
import '../services/goal_service.dart';
import '../services/offline_sync_service.dart';

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
import 'timeline_screen.dart';

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

  StreamSubscription? connectivitySubscription;

  bool isOnline = true;
  bool syncing = false;
  int pendingTransactions = 0;

  @override
  void initState() {
    super.initState();

    loadData();
    loadUnreadNotifications();
    loadGoalsSummary();
    initConnectivityMonitor();
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> initConnectivityMonitor() async {
    final online = await OfflineSyncService.hasInternet();

    setState(() {
      isOnline = online;
    });

    await updatePendingCount();

    if (online && pendingTransactions > 0) {
      await syncOfflineData();
    }

    connectivitySubscription =
        OfflineSyncService.connectivityStream().listen(
      (event) async {
        final hasInternet = event != ConnectivityResult.none;

        setState(() {
          isOnline = hasInternet;
        });

        if (hasInternet) {
          await syncOfflineData();
        }
      },
    );
  }

  Future<void> updatePendingCount() async {
    final count = await OfflineSyncService.getPendingCount();

    if (!mounted) return;

    setState(() {
      pendingTransactions = count;
    });
  }

  Future<void> syncOfflineData() async {
    final count = await OfflineSyncService.getPendingCount();

    if (count == 0) {
      await updatePendingCount();
      return;
    }

    setState(() {
      syncing = true;
    });

    final result = await OfflineSyncService.syncPending();

    if (!mounted) return;

    setState(() {
      syncing = false;
    });

    await updatePendingCount();
    await refreshDashboard();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result["message"].toString(),
        ),
      ),
    );
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
    await updatePendingCount();
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

  Widget buildConnectionStatusCard() {
    Color color;
    String text;
    IconData icon;

    if (syncing) {
      color = Colors.orangeAccent;
      text = "Sincronizando";
      icon = Icons.sync;
    } else if (!isOnline) {
      color = Colors.redAccent;
      text = "Modo Offline";
      icon = Icons.cloud_off;
    } else {
      color = Colors.greenAccent;
      text = "Conectado";
      icon = Icons.cloud_done;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (pendingTransactions > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$pendingTransactions pendientes",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
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
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
          Text(
            "\$${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
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

  Widget buildQuickAccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(30),
      ),
      child: GridView.count(
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
            title: "Timeline",
            icon: Icons.timeline,
            color: Colors.amberAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TimelineScreen(
                    email: widget.email,
                  ),
                ),
              );
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
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Sincronizar",
          onPressed: syncing ? null : syncOfflineData,
          icon: Icon(
            syncing ? Icons.sync : Icons.cloud_sync,
          ),
        ),
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
          icon: const Icon(Icons.notifications),
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
            return const [
              PopupMenuItem(
                value: "theme",
                child: Text(
                  "Cambiar tema",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: "logout",
                child: Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget buildPremiumCard(
    String title,
    String subtitle,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
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
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.black.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: colors.first,
            ),
            child: const Text("Abrir"),
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
      ),
      child: Row(
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
        color: const Color(0xFF151515),
      ),
      child: Text(
        "Metas activas: $totalGoals\nAhorrado: \$${totalGoalsSaved.toStringAsFixed(2)}\nObjetivo: \$${totalGoalsTarget.toStringAsFixed(2)}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: buildCleanAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    buildConnectionStatusCard(),
                    const SizedBox(height: 18),
                    buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: IncomeCard(income: income)),
                        const SizedBox(width: 15),
                        Expanded(child: ExpenseCard(expenses: expenses)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    BalanceCard(balance: balance),
                    const SizedBox(height: 30),
                    buildQuickAccessCard(),
                    const SizedBox(height: 30),
                    if (chartSummary != null)
                      FinancialPiesWidget(
                        chartSummary: chartSummary!,
                      ),
                    const SizedBox(height: 30),
                    buildPremiumCard(
                      "Flujo de Dinero",
                      "Audita de dónde entró y salió tu dinero.",
                      Icons.account_tree,
                      [
                        Colors.greenAccent,
                        Colors.tealAccent,
                      ],
                      () {
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
                    const SizedBox(height: 30),
                    buildPremiumCard(
                      "Timeline Financiero",
                      "Consulta tus movimientos en orden cronológico.",
                      Icons.timeline,
                      [
                        Colors.amberAccent,
                        Colors.orangeAccent,
                      ],
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimelineScreen(
                              email: widget.email,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    buildGoalsSummaryCard(),
                    const SizedBox(height: 30),
                    AiAdviceWidget(advice: advice),
                    const SizedBox(height: 30),
                    buildExportCard(),
                    const SizedBox(height: 30),
                    TransactionsWidget(
                      transactions: transactions,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}