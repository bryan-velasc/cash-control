import 'package:flutter/material.dart';

import '../services/goal_service.dart';

class GoalsScreen extends StatefulWidget {

  final String email;

  const GoalsScreen({
    super.key,
    required this.email,
  });

  @override
  State<GoalsScreen> createState() =>
      _GoalsScreenState();
}

class _GoalsScreenState
    extends State<GoalsScreen> {

  List goals = [];

  bool loading = true;

  final TextEditingController
      goalController =
      TextEditingController();

  final TextEditingController
      amountController =
      TextEditingController();

  @override
  void initState() {

    super.initState();

    loadGoals();
  }

  Future<void> loadGoals() async {

    try {

      final data =
          await GoalService.getGoals(
        widget.email,
      );

      setState(() {

        goals = data;

        loading = false;
      });

    } catch (e) {

      print(e);

      setState(() {

        loading = false;
      });
    }
  }

  Future<void> createGoal() async {

    if (goalController.text.isEmpty ||
        amountController.text.isEmpty) {
      return;
    }

    await GoalService.createGoal(

      widget.email,

      goalController.text,

      double.parse(
        amountController.text,
      ),
    );

    goalController.clear();

    amountController.clear();

    loadGoals();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Colors.black,

      appBar: AppBar(

        backgroundColor:
            Colors.black,

        title: const Text(
          "Metas de Ahorro",
        ),
      ),

      floatingActionButton:
          FloatingActionButton(

        backgroundColor:
            Colors.green,

        onPressed: () {

          showDialog(

            context: context,

            builder: (_) {

              return AlertDialog(

                backgroundColor:
                    const Color(
                        0xFF111111),

                title: const Text(
                  "Nueva Meta",
                ),

                content: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    TextField(

                      controller:
                          goalController,

                      decoration:
                          const InputDecoration(
                        hintText:
                            "Meta",
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    TextField(

                      controller:
                          amountController,

                      keyboardType:
                          TextInputType.number,

                      decoration:
                          const InputDecoration(
                        hintText:
                            "Cantidad",
                      ),
                    ),
                  ],
                ),

                actions: [

                  ElevatedButton(

                    onPressed: () {

                      Navigator.pop(
                          context);

                      createGoal();
                    },

                    child: const Text(
                      "Guardar",
                    ),
                  )
                ],
              );
            },
          );
        },

        child: const Icon(
          Icons.add,
        ),
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : ListView.builder(

              padding:
                  const EdgeInsets.all(20),

              itemCount:
                  goals.length,

              itemBuilder:
                  (context, index) {

                final goal =
                    goals[index];

                double progress =
                    goal["current_amount"] /
                        goal["target_amount"];

                return Container(

                  margin:
                      const EdgeInsets.only(
                    bottom: 20,
                  ),

                  padding:
                      const EdgeInsets.all(20),

                  decoration: BoxDecoration(

                    color:
                        const Color(
                            0xFF111111),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        goal["goal_name"],

                        style:
                            const TextStyle(

                          fontSize: 22,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              Colors.white,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      LinearProgressIndicator(

                        value: progress,

                        minHeight: 12,

                        backgroundColor:
                            Colors.white10,

                        color: Colors.green,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(

                        "\$${goal["current_amount"]} / \$${goal["target_amount"]}",

                        style: TextStyle(

                          color: Colors
                              .grey.shade400,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}