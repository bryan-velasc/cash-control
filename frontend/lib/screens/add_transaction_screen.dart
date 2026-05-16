import 'package:flutter/material.dart';

import '../services/transaction_service.dart';

class AddTransactionScreen
    extends StatefulWidget {

  final String email;

  const AddTransactionScreen({
    super.key,
    required this.email,
  });

  @override
  State<AddTransactionScreen>
      createState() =>
          _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {

  final amountController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  String type = "income";

  String category = "General";

  bool loading = false;

  Future<void> saveTransaction() async {

    setState(() {
      loading = true;
    });

    await TransactionService
        .createTransaction(

      email: widget.email,

      type: type,

      category: category,

      amount: double.parse(
        amountController.text,
      ),

      description:
          descriptionController.text,
    );

    setState(() {
      loading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text("Nueva Transacción"),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(

              controller:
                  amountController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  const InputDecoration(
                labelText: "Monto",
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller:
                  descriptionController,

              decoration:
                  const InputDecoration(
                labelText: "Descripción",
              ),
            ),

            const SizedBox(height: 20),

            DropdownButton<String>(

              value: type,

              isExpanded: true,

              items: const [

                DropdownMenuItem(
                  value: "income",
                  child: Text("Ingreso"),
                ),

                DropdownMenuItem(
                  value: "expense",
                  child: Text("Egreso"),
                ),
              ],

              onChanged: (value) {

                setState(() {

                  type = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                    loading
                        ? null
                        : saveTransaction,

                child: loading

                    ? const CircularProgressIndicator()

                    : const Text(
                        "Guardar",
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}