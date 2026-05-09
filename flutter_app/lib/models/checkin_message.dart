import 'package:flutter/material.dart';

enum MessageTone { critical, warm, plain }

class CheckInMessage {
  const CheckInMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.time,
    required this.copy,
    required this.tone,
    required this.icon,
    required this.transcript,
    required this.summary,
    required this.intent,
    required this.mood,
    required this.priority,
    required this.accentColor,
    required this.backgroundColor,
    this.status = '',
    this.suggestedAction = '',
    this.audioUrl = '',
    this.seniorId = '',
    this.actionLabel,
  });

  factory CheckInMessage.fromApi(Map<String, dynamic> json) {
    final priority = json['priority'] as String? ?? '';
    final summary = json['summary'] as String? ?? '';
    final transcript = json['transcript'] as String? ?? '';
    final suggestedAction = json['suggested_action'] as String? ?? '';
    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue.replaceFirst('Z', '+00:00'))
        : null;
    final isEmergency = priority.toLowerCase() == 'emergency';

    return CheckInMessage(
      id: json['id'] as String? ?? json['message_id'] as String? ?? '',
      kind: isEmergency ? 'Emergency Triage' : 'Care Update',
      title: isEmergency ? 'Needs attention' : 'Not emergency',
      time: _relativeTime(createdAt),
      copy: summary.isNotEmpty
          ? summary
          : 'The backend is still processing this voice check-in.',
      tone: isEmergency ? MessageTone.critical : MessageTone.plain,
      icon: isEmergency
          ? Icons.warning_rounded
          : Icons.check_circle_outline_rounded,
      transcript: transcript.isNotEmpty ? transcript : 'Transcript pending.',
      summary: summary.isNotEmpty ? summary : 'AI summary pending.',
      intent: priority.isNotEmpty ? priority : 'Processing',
      mood: json['status'] as String? ?? 'processing',
      priority: priority.isNotEmpty ? priority : 'Processing',
      accentColor:
          isEmergency ? const Color(0xFFDC151B) : const Color(0xFF0B63C9),
      backgroundColor:
          isEmergency ? const Color(0xFFF1F2F4) : const Color(0xFFFFFFFF),
      status: json['status'] as String? ?? '',
      suggestedAction: suggestedAction,
      audioUrl: json['audio_url'] as String? ?? '',
      seniorId: json['senior_id'] as String? ?? '',
      actionLabel: 'Mark as handled',
    );
  }

  final String id;
  final String kind;
  final String title;
  final String time;
  final String copy;
  final MessageTone tone;
  final IconData icon;
  final String transcript;
  final String summary;
  final String intent;
  final String mood;
  final String priority;
  final Color accentColor;
  final Color backgroundColor;
  final String status;
  final String suggestedAction;
  final String audioUrl;
  final String seniorId;
  final String? actionLabel;
}

String _relativeTime(DateTime? createdAt) {
  if (createdAt == null) return 'Just now';
  final diff = DateTime.now().difference(createdAt.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  return '${diff.inDays} days ago';
}
