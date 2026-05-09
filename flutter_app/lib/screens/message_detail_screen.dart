import 'package:flutter/material.dart';

import '../models/checkin_message.dart';
import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({
    required this.message,
    required this.onBack,
    required this.onAcknowledge,
    required this.onResolve,
    this.isUpdating = false,
    super.key,
  });

  final CheckInMessage message;
  final VoidCallback onBack;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TopBar(title: message.kind, onBack: onBack),
          if (message.tone == MessageTone.critical) const _EmergencyBanner(),
          Text(message.time,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          Text(message.title,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1F33),
                  height: 1.2)),
          const SizedBox(height: 12),
          Text(message.copy,
              style: const TextStyle(
                  fontSize: 18, color: Color(0xFF4B5563), height: 1.45)),
          const SizedBox(height: 24),
          _VoiceCard(message: message),
          const Text('AI Analysis',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child:
                      _AnalysisTile(label: 'Priority', value: message.intent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _AnalysisTile(label: 'Status', value: message.mood)),
            ],
          ),
          if (message.suggestedAction.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SuggestedAction(text: message.suggestedAction),
          ],
          const SizedBox(height: 20),
          Text('"${message.transcript}"',
              style: const TextStyle(
                  fontSize: 22, fontStyle: FontStyle.italic, height: 1.45)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isUpdating ? null : onAcknowledge,
            icon: const Icon(Icons.reply_rounded),
            label: Text(isUpdating ? 'Updating...' : 'Acknowledge'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isUpdating ? null : onResolve,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Mark as resolved'),
          ),
        ],
      ),
    );
  }
}

class _SuggestedAction extends StatelessWidget {
  const _SuggestedAction({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF8E5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3D27A))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF9A6A00)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5E4700),
                      height: 1.35,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.message});

  final CheckInMessage message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(message.summary,
                style: const TextStyle(fontSize: 18, color: Color(0xFF3C414C))),
            const SizedBox(height: 24),
            const _Waveform(),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded)),
                const SizedBox(width: 12),
                const Expanded(child: LinearProgressIndicator(value: .38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
          color: const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          final height = 16.0 + (index % 5) * 9.0;
          return Container(
            width: 6,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
                color: const Color(0xFF0968B8)
                    .withValues(alpha: index.isEven ? .35 : 1),
                borderRadius: BorderRadius.circular(6)),
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
      decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBDD8FF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF5A9BD6),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
      decoration: BoxDecoration(
          color: const Color(0xFFFFE4E4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFAAAA))),
      child: const Row(
        children: [
          Icon(Icons.emergency_rounded, color: Color(0xFF9C1015)),
          SizedBox(width: 10),
          Expanded(
              child: Text('Emergency attention may be required.',
                  style: TextStyle(
                      color: Color(0xFF9C1015), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}
