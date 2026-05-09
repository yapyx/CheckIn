import 'package:flutter/material.dart';

import '../widgets/care_status_card.dart';
import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({
    required this.onRecord,
    required this.onHealth,
    required this.onSettings,
    super.key,
  });

  final VoidCallback onRecord;
  final VoidCallback onHealth;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) onHealth();
          if (index == 2) onSettings();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Health Logs'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const TopBar(title: 'CheckIn', avatar: 'M'),
          const SizedBox(height: 24),
          const Text('Hi Mary, ready for your daily check-in?', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          const Text('Record a short update for your care team. We will share urgent concerns right away.', style: TextStyle(fontSize: 20, color: Color(0xFF4E535D))),
          const SizedBox(height: 36),
          ElevatedButton.icon(onPressed: onRecord, icon: const Icon(Icons.mic_rounded), label: const Text('Start Voice Check-in')),
          const SizedBox(height: 20),
          const CareStatusCard(),
        ],
      ),
    );
  }
}
