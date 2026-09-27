import 'package:flutter/material.dart';

import 'auth/auth_gradient_background.dart';
import 'velora/velora.dart';

/// Branded full-screen splash shown while the app or a tab is loading.
class AppSplashView extends StatelessWidget {
  const AppSplashView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/brand/velora_logo_light.png',
                  width: 220,
                  semanticLabel: 'VELORA',
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: VeloraColors.amber),
                ),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: VeloraText.body(14, weight: FontWeight.w600, color: const Color(0xFFCFE2DC)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
