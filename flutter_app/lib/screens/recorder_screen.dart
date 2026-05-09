import 'package:flutter/material.dart';

import '../widgets/screen_frame.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({
    required this.isRecording,
    required this.onToggleRecording,
    required this.onDone,
    required this.seniorId,
    required this.hasRecording,
    this.isSending = false,
    this.errorText,
    super.key,
  });

  final bool isRecording;
  final Future<void> Function() onToggleRecording;
  final Future<void> Function() onDone;
  final String seniorId;
  final bool hasRecording;
  final bool isSending;
  final String? errorText;

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  @override
  Widget build(BuildContext context) {
    final canSend =
        widget.hasRecording && !widget.isRecording && !widget.isSending;

    return ScreenFrame(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Daily Check-in',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 48),
            Icon(Icons.mic_rounded,
                size: 96,
                color: widget.isRecording
                    ? const Color(0xFFDC151B)
                    : const Color(0xFF0968B8)),
            const SizedBox(height: 18),
            Text(widget.isRecording ? 'Recording...' : 'Tap to record',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Tell us how you are feeling today.',
                style: TextStyle(fontSize: 20, color: Color(0xFF4E535D))),
            const Spacer(),
            SizedBox(
              width: 260,
              height: 260,
              child: ElevatedButton(
                onPressed: widget.isSending
                    ? null
                    : () async => widget.onToggleRecording(),
                style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: widget.isRecording
                        ? const Color(0xFFDC151B)
                        : const Color(0xFF0968B8)),
                child: Text(widget.isRecording ? 'Stop' : 'Record',
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 32),
            _RecordingStatus(
              isRecording: widget.isRecording,
              hasRecording: widget.hasRecording,
              isSending: widget.isSending,
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: 12),
              Text(widget.errorText!,
                  style: const TextStyle(
                      color: Color(0xFFB42318), fontSize: 15, height: 1.3)),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: canSend ? () async => widget.onDone() : null,
              child: Text(widget.isSending ? 'Sending...' : 'Send Check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus({
    required this.isRecording,
    required this.hasRecording,
    required this.isSending,
  });

  final bool isRecording;
  final bool hasRecording;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final text = switch ((isRecording, hasRecording, isSending)) {
      (true, _, _) => 'Recording now. Tap Stop when you are done.',
      (false, true, true) => 'Uploading your voice check-in securely.',
      (false, true, false) => 'Recording saved. Send it to your care team.',
      _ =>
        'Tap Record and speak naturally. Your audio will be uploaded after you stop.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4E535D),
          fontSize: 16,
          height: 1.35,
        ),
      ),
    );
  }
}
