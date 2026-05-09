import 'package:flutter/material.dart';

import '../models/checkin_message.dart';
import '../widgets/caregiver_nav.dart';
import '../widgets/screen_frame.dart';

class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({
    required this.messages,
    required this.onMessageSelected,
    required this.onMessageDismissed,
    required this.onFamily,
    this.userName = 'Sarah',
    super.key,
  });

  final List<CheckInMessage> messages;
  final ValueChanged<CheckInMessage> onMessageSelected;
  final ValueChanged<CheckInMessage> onMessageDismissed;
  final VoidCallback onFamily;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: CaregiverNav(onHome: () {}, onFamily: onFamily, activeFamily: false),
      child: Column(
        children: [
          DashboardHeader(onAvatarTap: () => _showProfileSheet(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const Text('Mon, 15 Feb', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.3)),
                const SizedBox(height: 6),
                Text('Hello, $userName!', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0B1F33), height: 1.15)),
                const SizedBox(height: 34),
                const Text('Recent Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF3F4652), height: 1.3)),
                const SizedBox(height: 24),
                if (messages.isEmpty)
                  const _EmptyMessages()
                else
                  ...messages.map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DashboardMessageCard(
                        message: message,
                        onTap: () => onMessageSelected(message),
                        onDismiss: message.actionLabel == null ? null : () => onMessageDismissed(message),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profile & Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0B1F33))),
              const SizedBox(height: 8),
              const Text('Caregiver profile preferences will appear here.', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.35)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({required this.onAvatarTap, super.key});

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('CheckIn', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF0B1F33), height: 1.2)),
          ),
          Material(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onAvatarTap,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Center(child: Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3F4652)))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMessageCard extends StatelessWidget {
  const DashboardMessageCard({
    required this.message,
    required this.onTap,
    this.onDismiss,
    super.key,
  });

  final CheckInMessage message;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final iconBackground = switch (message.tone) {
      MessageTone.critical => const Color(0xFFFFE4E4),
      MessageTone.warm => const Color(0xFFFFE5D4),
      MessageTone.plain => const Color(0xFFDCEEFF),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: message.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: message.tone == MessageTone.plain ? Border.all(color: const Color(0xFFC9D1DD)) : null,
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: message.tone == MessageTone.plain ? Colors.transparent : message.accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: iconBackground,
                                child: Icon(message.icon, color: message.accentColor, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(message.kind, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF0B1F33), height: 1.25))),
                              Text(message.time, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.3)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(message.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0B1F33), height: 1.25)),
                          const SizedBox(height: 8),
                          Text(message.copy, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Color(0xFF4B5563), height: 1.55)),
                          if (message.actionLabel != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: onDismiss,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0B1F33),
                                  side: const BorderSide(color: Color(0xFF0B1F33), width: 1.6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: Text(message.actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: const Text('No recent messages. New care updates will appear here.', style: TextStyle(fontSize: 17, color: Color(0xFF6B7280), height: 1.35)),
    );
  }
}
