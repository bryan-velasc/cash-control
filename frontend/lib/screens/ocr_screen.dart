
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';

class OCRScreen extends StatefulWidget {

  const OCRScreen({
    super.key,
  });

  @override
  State<OCRScreen> createState() =>
      _OCRScreenState();
}

class _OCRScreenState
    extends State<OCRScreen> {

  File? image;

  String result = "";

  bool loading = false;

  Future<void> pickImage() async {

    final picked =
        await ImagePicker().pickImage(

      source: ImageSource.gallery,
    );

    if (picked == null) return;

    setState(() {

      image = File(
        picked.path,
      );
    });
  }

  Future<void> scanText() async {

    if (image == null) return;

    setState(() {

      loading = true;
    });

    final text =
        await OCRService.scanReceipt(
      image!,
    );

    setState(() {

      result = text;

      loading = false;
    });
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
          "OCR Scanner",
        ),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          children: [

            ElevatedButton(

              onPressed: pickImage,

              child: const Text(
                "Seleccionar Imagen",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed:
                  loading
                      ? null
                      : scanText,

              child: loading

                  ? const CircularProgressIndicator()

                  : const Text(
                      "Escanear Texto",
                    ),
            ),

            const SizedBox(height: 20),

            Expanded(

              child: SingleChildScrollView(

                child: Text(

                  result,

                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}