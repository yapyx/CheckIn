import 'package:flutter/material.dart';

import '../widgets/caregiver_nav.dart';
import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({required this.family, required this.onHome, super.key});

  final List<String> family;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: CaregiverNav(onHome: onHome, onFamily: () {}, activeFamily: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          const TopBar(title: 'Family', avatar: 'A'),
          const Text('Family contacts and care network will appear here.', style: TextStyle(fontSize: 17, color: Color(0xFF6B7280), height: 1.35)),
          const SizedBox(height: 24),
          for (final member in family)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE5E7EB))),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.elderly_rounded)),
                title: Text(member, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                subtitle: const Text('Daily check-ins enabled'),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Family Member')),
        ],
      ),
    );
  }
}
