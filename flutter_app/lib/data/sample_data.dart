import 'package:flutter/material.dart';

import '../models/checkin_message.dart';

const familyMembers = ['Grandpa Joe', 'Grandma Mary'];

const sampleMessages = [
  CheckInMessage(
    id: 'critical',
    kind: 'Critical Alert',
    title: 'Medication Reminder Missed',
    time: '10 mins ago',
    copy:
        "Sarah hasn't acknowledged her morning blood pressure medication. This may require immediate attention.",
    tone: MessageTone.critical,
    icon: Icons.warning_rounded,
    transcript:
        'I forgot whether I took my blood pressure pill this morning, and I feel a little dizzy.',
    summary:
        'Possible missed blood pressure medication with dizziness reported.',
    intent: 'Medical Alert',
    mood: 'Concerned',
    priority: 'High',
    accentColor: Color(0xFFDC151B),
    backgroundColor: Color(0xFFF1F2F4),
  ),
  CheckInMessage(
    id: 'note',
    kind: 'Personal Note',
    title: 'Feeling Lonely',
    time: '45 mins ago',
    copy:
        "Just wanted to say hi and ask about dinner plans tonight. It's been a quiet afternoon.",
    tone: MessageTone.warm,
    icon: Icons.favorite_border_rounded,
    transcript:
        'I was just wondering if you are coming over for dinner today? I made your favorite chicken stew.',
    summary:
        'Grandma Mary is checking dinner plans and would appreciate a response.',
    intent: 'Routine Inquiry',
    mood: 'Anticipatory',
    priority: 'Warm',
    accentColor: Color(0xFFE29A6B),
    backgroundColor: Color(0xFFFFF1EA),
  ),
  CheckInMessage(
    id: 'daily',
    kind: 'Check-in',
    title: 'Daily Status',
    time: '5 hours ago',
    copy: "I'm doing well today, the weather looks lovely through the window.",
    tone: MessageTone.plain,
    icon: Icons.check_circle_outline_rounded,
    transcript:
        "I'm doing well today, the weather looks lovely through the window.",
    summary: 'Daily wellbeing check-in, no action needed.',
    intent: 'Daily Check-in',
    mood: 'Content',
    priority: 'Routine',
    accentColor: Color(0xFF0B63C9),
    backgroundColor: Color(0xFFFFFFFF),
    actionLabel: 'Dismiss',
  ),
];
