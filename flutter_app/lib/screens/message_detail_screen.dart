import 'package:flutter/material.dart';

import '../models/checkin_message.dart';
import '../widgets/caregiver_nav.dart';
import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({
    required this.message,
    this.onFamily,
    super.key,
  });

  final CheckInMessage message;
  final VoidCallback? onFamily;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: CaregiverNav(
        onHome: () => Navigator.pop(context),
        onFamily: () {
          Navigator.pop(context);
          widget.onFamily?.call();
        },
        activeFamily: false,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          TopBar(
            title: 'CheckIn',
            onBack: () => Navigator.pop(context),
            avatar: 'A',
          ),
          const SizedBox(height: 8),
          Text(message.kind, style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280), fontWeight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 6),
          if (message.tone == MessageTone.critical) const _EmergencyBanner(),
          Text(message.time, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          Text(message.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0B1F33), height: 1.2)),
          const SizedBox(height: 12),
          Text(message.copy, style: const TextStyle(fontSize: 18, color: Color(0xFF4B5563), height: 1.45)),
          const SizedBox(height: 24),
          _VoiceCard(
            message: message,
            isPlaying: _isPlaying,
            onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
          ),
          const SizedBox(height: 28),
          const Text('AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B1F33), letterSpacing: 1.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _AnalysisTile(label: 'Intent', value: message.intent)),
              const SizedBox(width: 12),
              Expanded(child: _AnalysisTile(label: 'Mood', value: message.mood)),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Transcript', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B1F33), height: 1.3)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text('"${message.transcript}"', style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Color(0xFF364152), height: 1.45)),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.message,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  final CheckInMessage message;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF0B1F33), height: 1.25)),
            const SizedBox(height: 12),
            Text(message.summary, style: const TextStyle(fontSize: 17, color: Color(0xFF4B5563), height: 1.35)),
            const SizedBox(height: 24),
            _Waveform(isPlaying: isPlaying),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.filled(
                  onPressed: onTogglePlay,
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF0B63C9), foregroundColor: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(child: LinearProgressIndicator(value: isPlaying ? .58 : .38, color: const Color(0xFF0B63C9), backgroundColor: const Color(0xFFE5E7EB))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          final height = 16.0 + (index % 5) * 9.0 + (isPlaying && index.isEven ? 6 : 0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 6,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0B63C9).withOpacity(index.isEven ? .35 : 1),
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  const _AnalysisTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFBDD8FF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF0B63C9), fontWeight: FontWeight.w800, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 19, color: Color(0xFF0B1F33), fontWeight: FontWeight.w800, height: 1.2)),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFE4E4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFAAAA))),
      child: const Row(
        children: [
          Icon(Icons.emergency_rounded, color: Color(0xFF9C1015)),
          SizedBox(width: 10),
          Expanded(child: Text('Emergency attention may be required.', style: TextStyle(color: Color(0xFF9C1015), fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
