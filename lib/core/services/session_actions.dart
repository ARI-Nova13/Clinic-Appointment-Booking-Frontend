import 'package:flutter/material.dart';
import 'package:medicare_app/features/authentication/data/auth_service.dart';
import 'package:medicare_app/features/authentication/presentation/login_screen.dart';

class SessionActions {
  static Future<void> logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
