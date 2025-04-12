import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showQRCodeBottomSheet(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final String secureKey = dotenv.env['SECURE_KEY']!;

  // Retrieve and decode userData Map from SharedPreferences
  final userDataString = prefs.getString('userData');
  if (userDataString == null) return;

  //Payload encryption function
  String encryptPayload(String data, String key) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromUtf8(key), mode: encrypt.AESMode.cbc),
    );
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  //Encrypted data
  final encryptedData = encryptPayload(userDataString, secureKey);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.65,
        expand: false,
        builder: (context, scrollController) {
          final screenWidth = MediaQuery.of(context).size.width;

          return SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(
              width: screenWidth,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "🧾 Patient QR Code",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    //Secure QR generation
                    QrImageView(
                      data: encryptedData,
                      version: QrVersions.auto,
                      size: MediaQuery.of(context).size.width * 0.8,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Patient ID : 1234241",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
