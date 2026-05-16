import 'dart:convert';

import 'dart:io';

import 'package:http/http.dart'
    as http;

class OCRService {

  static Future<String>
      scanReceipt(
    File image,
  ) async {

    try {

      var request =
          http.MultipartRequest(

        'POST',

        Uri.parse(
          'https://api.ocr.space/parse/image',
        ),
      );

      request.headers.addAll({

        'apikey':
            'helloworld',
      });

      request.files.add(

        await http.MultipartFile
            .fromPath(

          'file',

          image.path,
        ),
      );

      final response =
          await request.send();

      final result =
          await response.stream
              .bytesToString();

      final data =
          jsonDecode(result);

      return data["ParsedResults"][0]
          ["ParsedText"];

    } catch (e) {

      return "Error OCR";
    }
  }
}