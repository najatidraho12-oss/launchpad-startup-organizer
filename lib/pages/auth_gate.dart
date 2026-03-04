import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../settings/app_settings.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthRepository();

    return FutureBuilder<int?>(
      future: auth.getCurrentUserId(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final id = snap.data;

        if (id == null) {
          return const LoginPage();
        }

        //  connecté => Home
        return HomePage(settings: AppSettings.instance);
      },
    );
  }
}
