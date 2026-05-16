import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:provider/provider.dart';

import '../services/transaction_service.dart';

import '../services/pdf_service.dart';

import '../services/excel_service.dart';

import '../providers/theme_provider.dart';

import 'add_transaction_screen.dart';

import 'login_screen.dart';

import 'goals_screen.dart';

import 'ocr_screen.dart';

import 'budgets_screen.dart';

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

class _DashboardScreenState
    extends State<DashboardScreen> {

  bool loading = true;

  double balance = 0;

  double income = 0;

  double expenses = 0;

  List transactions = [];

  List advice = [];

  @override
  void initState() {

    super.initState();

    loadData();
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

      if (tx["type"] == "income") {

        current += tx["amount"];

      } else {

        current -= tx["amount"];
      }

      spots.add(

        FlSpot(
          i.toDouble(),
          current,
        ),
      );
    }

    return spots;
  }

  Future<void> loadData() async {

    try {

      final balanceData =
          await TransactionService
              .getBalance(
        widget.email,
      );

      final txData =
          await TransactionService
              .getTransactions(
        widget.email,
      );

      List adviceData = [];

      try {

        adviceData =
            await TransactionService
                .getFinancialAdvice(
          widget.email,
        );

      } catch (e) {

        print("ERROR IA:");
        print(e);
      }

      income = 0;

      expenses = 0;

      for (var tx in txData) {

        if (tx["type"] == "income") {

          income += tx["amount"];

        } else {

          expenses += tx["amount"];
        }
      }

      setState(() {

        balance =
            balanceData["balance"]
                .toDouble();

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

  Future<void> logout() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      "user_email",
    );

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(

        builder: (_) =>
            const LoginScreen(),
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

          IconButton(

            onPressed: () async {

              await Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      AddTransactionScreen(
                    email: widget.email,
                  ),
                ),
              );

              loadData();
            },

            icon: const Icon(
              Icons.add,
            ),
          ),

          IconButton(

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      GoalsScreen(
                    email: widget.email,
                  ),
                ),
              );
            },

            icon: const Icon(
              Icons.flag,
            ),
          ),

          IconButton(

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

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      const OCRScreen(),
                ),
              );
            },

            icon: const Icon(
              Icons.camera_alt,
            ),
          ),

          IconButton(

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

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      BudgetsScreen(
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

            onPressed: logout,

            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : SingleChildScrollView(

              child: Padding(

                padding:
                    const EdgeInsets.all(20),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    BalanceCard(
                      balance: balance,
                    ),

                    const SizedBox(height: 30),

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

                    const SizedBox(height: 30),

                    AiAdviceWidget(
                      advice: advice,
                    ),

                    const SizedBox(height: 30),

                    PieChartWidget(

                      income: income,

                      expenses: expenses,
                    ),

                    const SizedBox(height: 30),

                    GlassCard(

                      height: 300,

                      child: Padding(

                        padding:
                            const EdgeInsets.all(20),

                        child: Column(

                          children: [

                            const Text(

                              "Evolución Financiera",

                              style: TextStyle(

                                fontSize: 20,

                                fontWeight:
                                    FontWeight.bold,

                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 20),

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

                                      spots:
                                          generateChartData(),

                                      isCurved: true,

                                      color: Colors.green,

                                      barWidth: 4,

                                      dotData: FlDotData(
                                        show: false,
                                      ),

                                      belowBarData:
                                          BarAreaData(
                                        show: true,
                                      ),
                                    )
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
                        fontWeight:
                            FontWeight.bold,
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
    );
  }
}