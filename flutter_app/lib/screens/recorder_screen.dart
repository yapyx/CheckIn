import 'package:flutter/material.dart';

import '../widgets/screen_frame.dart';

class RecorderScreen extends StatelessWidget {
  const RecorderScreen({
    required this.isRecording,
    required this.onToggleRecording,
    required this.onLogout,
    super.key,
  });

  final bool isRecording;
  final VoidCallback onToggleRecording;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isRecording ? const Color(0xFFDE2D32) : const Color(0xFF0B63C9);
    final ringColor =
        isRecording ? const Color(0xFFC51E24) : const Color(0xFF68A8FF);

    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Talk to Caregiver',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF061D3B),
                        height: 1.2),
                  ),
                ),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 23,
                        backgroundImage: AssetImage('assets/caregiver pfp.png'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRecording ? 'CLICK TO END' : 'CLICK TO TALK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            height: 1.2),
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isRecording ? 1 : 0,
                        child: const Text(
                          'Press and hold the big button to speak.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                              height: 1.35),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _VoiceButton(
                        color: primaryColor,
                        ringColor: ringColor,
                        label: isRecording ? 'CLICK TO END' : 'CLICK TO START',
                        onTap: onToggleRecording,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _SecuredFooter(),
        ],
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.color,
    required this.ringColor,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final Color ringColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: ringColor, width: 8),
          boxShadow: const [
            BoxShadow(
                color: Color(0x24000000), blurRadius: 24, offset: Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 82),
            const SizedBox(height: 18),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _SecuredFooter extends StatelessWidget {
  const _SecuredFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EAEC),
        border: Border(top: BorderSide(color: Color(0xFFD6D9DE))),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF1A1A1A), size: 24),
              SizedBox(width: 10),
              Text('Secured System',
                  style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
