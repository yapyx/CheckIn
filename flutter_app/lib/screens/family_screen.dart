import 'package:flutter/material.dart';

import '../widgets/caregiver_nav.dart';
import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    required this.family,
    required this.onHome,
    required this.onLinkSenior,
    this.isLinking = false,
    this.linkError,
    super.key,
  });

  final List<String> family;
  final VoidCallback onHome;
  final Future<void> Function(String pairingCode) onLinkSenior;
  final bool isLinking;
  final String? linkError;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final TextEditingController _pairingCodeController = TextEditingController();

  @override
  void dispose() {
    _pairingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: CaregiverNav(
          onHome: widget.onHome, onFamily: () {}, activeFamily: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          const TopBar(title: 'Family', avatar: 'A'),
          const Text(
              'Link seniors with their pairing code so their triage messages appear in your feed.',
              style: TextStyle(
                  fontSize: 17, color: Color(0xFF6B7280), height: 1.35)),
          const SizedBox(height: 24),
          for (final member in widget.family)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE5E7EB))),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.elderly_rounded)),
                title: Text(member,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                subtitle: const Text('Daily check-ins enabled'),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _pairingCodeController,
            decoration: InputDecoration(
              labelText: 'Senior pairing code',
              hintText: 'e.g. CI-123ABC or senior user id',
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (widget.linkError != null) ...[
            const SizedBox(height: 12),
            Text(widget.linkError!,
                style: const TextStyle(
                    color: Color(0xFFB42318), fontSize: 15, height: 1.3)),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.isLinking
                ? null
                : () async {
                    final code = _pairingCodeController.text.trim();
                    if (code.isEmpty) return;
                    await widget.onLinkSenior(code);
                    if (mounted) _pairingCodeController.clear();
                  },
            icon: const Icon(Icons.add),
            label: Text(widget.isLinking ? 'Linking...' : 'Link Senior'),
          ),
        ],
      ),
    );
  }
}
