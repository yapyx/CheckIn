import 'package:flutter/material.dart';

import '../widgets/care_status_card.dart';
import '../widgets/screen_frame.dart';

class DeliveredScreen extends StatelessWidget {
  const DeliveredScreen({required this.onHome, super.key});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFEEF3FA),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 36),
          const CircleAvatar(
              radius: 68,
              backgroundColor: Color(0xFFD6E5FF),
              child: Icon(Icons.check_rounded,
                  size: 78, color: Color(0xFF0968B8))),
          const SizedBox(height: 32),
          const Text('Your message was delivered',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Text('Angelica will see your check-in soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Color(0xFF4E535D))),
          const SizedBox(height: 40),
          const CareStatusCard(),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onHome, child: const Text('Back Home')),
        ],
      ),
    );
  }
}
