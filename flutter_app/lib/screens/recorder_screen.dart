import 'package:flutter/material.dart';

import '../widgets/screen_frame.dart';

class RecorderScreen extends StatelessWidget {
  const RecorderScreen({
    required this.isRecording,
    required this.onToggleRecording,
    required this.onDone,
    super.key,
  });

  final bool isRecording;
  final VoidCallback onToggleRecording;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Daily Check-in', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 48),
            Icon(Icons.mic_rounded, size: 96, color: isRecording ? const Color(0xFFDC151B) : const Color(0xFF0968B8)),
            const SizedBox(height: 18),
            Text(isRecording ? 'Recording...' : 'Tap to record', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Tell us how you are feeling today.', style: TextStyle(fontSize: 20, color: Color(0xFF4E535D))),
            const Spacer(),
            SizedBox(
              width: 260,
              height: 260,
              child: ElevatedButton(
                onPressed: onToggleRecording,
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: isRecording ? const Color(0xFFDC151B) : const Color(0xFF0968B8)),
                child: Text(isRecording ? 'Stop' : 'Record', style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(onPressed: onDone, child: const Text('Send Check-in')),
          ],
        ),
      ),
    );
  }
}
