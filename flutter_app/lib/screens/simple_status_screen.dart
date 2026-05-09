import 'package:flutter/material.dart';

import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class SimpleStatusScreen extends StatelessWidget {
  const SimpleStatusScreen({
    required this.title,
    required this.icon,
    required this.body,
    required this.onBack,
    super.key,
  });

  final String title;
  final IconData icon;
  final String body;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopBar(title: title, onBack: onBack),
            const Spacer(),
            Center(child: Icon(icon, size: 92, color: const Color(0xFF0968B8))),
            const SizedBox(height: 24),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, color: Color(0xFF4E535D), height: 1.4)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
