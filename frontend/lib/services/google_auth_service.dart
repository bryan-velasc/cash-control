import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;

class GoogleAuthService {

 static const String baseUrl =
    "http://10.0.9.132:8000";

  static Future<UserCredential?>
      signInWithGoogle() async {

    try {

      final provider =
          GoogleAuthProvider();

      provider.addScope(
        "email",
      );

      provider.setCustomParameters({

        "prompt":
            "select_account",
      });

      final userCredential =
          await FirebaseAuth
              .instance
              .signInWithPopup(
        provider,
      );

      final user =
          userCredential.user;

      if (user != null) {

        await http.post(

          Uri.parse(
            "$baseUrl/google-login",
          ),

          headers: {
            "Content-Type":
                "application/json",
          },

          body: jsonEncode({

            "email":
                user.email,

            "name":
                user.displayName,
          }),
        );
      }

      return userCredential;

    } catch (e) {

      print("ERROR GOOGLE LOGIN:");
      print(e);

      return null;
    }
  }
}