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
    this.actionLabel,
  });

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
  final String? actionLabel;
}
