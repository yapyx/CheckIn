import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/app_screen.dart';
import '../models/checkin_message.dart';
import '../models/family_member.dart';
import '../models/role.dart';
import 'caregiver_home_screen.dart';
import 'delivered_screen.dart';
import 'elder_home_screen.dart';
import 'family_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'recorder_screen.dart';
import 'signup_screen.dart';
import 'simple_status_screen.dart';

class CheckInHome extends StatefulWidget {
  const CheckInHome({super.key});

  @override
  State<CheckInHome> createState() => _CheckInHomeState();
}

class _CheckInHomeState extends State<CheckInHome> {
  AppScreen _screen = AppScreen.welcome;
  List<CheckInMessage> _caregiverMessages = List.of(sampleMessages);
  List<FamilyMember> _familyMembers = List.of(familyMembers);
  bool _isRecording = false;

  void _go(AppScreen screen) {
    setState(() => _screen = screen);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildScreen(),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onCreateAccount: (role) => _go(role == Role.senior ? AppScreen.seniorSignup : AppScreen.caregiverSignup),
          onSignIn: (role) => _go(role == Role.senior ? AppScreen.recorder : AppScreen.caregiverHome),
        );
      case AppScreen.seniorSignup:
        return SignupScreen.senior(
          onCreate: () => _go(AppScreen.recorder),
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverSignup:
        return SignupScreen.caregiver(
          onCreate: () => _go(AppScreen.caregiverHome),
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverHome:
        return CaregiverHomeScreen(
          messages: _caregiverMessages,
          onMessageDismissed: _dismissMessage,
          onFamily: () => _go(AppScreen.family),
        );
      case AppScreen.family:
        return FamilyScreen(
          family: _familyMembers,
          onMemberAdded: _addFamilyMember,
          onHome: () => _go(AppScreen.caregiverHome),
        );
      case AppScreen.elderHome:
        return ElderHomeScreen(
          onRecord: () => _go(AppScreen.recorder),
          onHealth: () => _go(AppScreen.health),
          onSettings: () => _go(AppScreen.settings),
        );
      case AppScreen.recorder:
        return RecorderScreen(
          isRecording: _isRecording,
          onToggleRecording: () => setState(() => _isRecording = !_isRecording),
        );
      case AppScreen.delivered:
        return DeliveredScreen(onHome: () => _go(AppScreen.elderHome));
      case AppScreen.health:
        return SimpleStatusScreen(
          title: 'Health Logs',
          icon: Icons.monitor_heart_outlined,
          body: 'Medication, mood, and symptom trends will appear here after daily voice check-ins are processed.',
          onBack: () => _go(AppScreen.elderHome),
        );
      case AppScreen.settings:
        return SimpleStatusScreen(
          title: 'Settings',
          icon: Icons.settings_outlined,
          body: 'Manage trusted contacts, emergency preferences, reminders, and accessibility options.',
          onBack: () => _go(AppScreen.elderHome),
        );
    }
  }

  void _dismissMessage(CheckInMessage message) {
    setState(() {
      _caregiverMessages = _caregiverMessages.where((item) => item.id != message.id).toList();
    });
  }

  void _addFamilyMember(FamilyMember member) {
    setState(() => _familyMembers = [..._familyMembers, member]);
  }
}
