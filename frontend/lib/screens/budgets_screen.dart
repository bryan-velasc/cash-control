import 'package:flutter/material.dart';

class BudgetsScreen
    extends StatelessWidget {

  final String email;

  const BudgetsScreen({

    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Colors.black,

      appBar: AppBar(

        backgroundColor:
            Colors.black,

        title: const Text(
          "Presupuestos",
        ),
      ),

      body: const Center(

        child: Text(

          "Sistema de presupuestos",

          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}