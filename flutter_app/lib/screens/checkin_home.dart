import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/app_screen.dart';
import '../models/app_user.dart';
import '../models/checkin_message.dart';
import '../models/role.dart';
import '../models/signup_form_data.dart';
import '../services/audio_upload_service_stub.dart'
    if (dart.library.io) '../services/audio_upload_service_io.dart';
import '../services/checkin_api.dart';
import 'caregiver_home_screen.dart';
import 'delivered_screen.dart';
import 'elder_home_screen.dart';
import 'family_screen.dart';
import 'message_detail_screen.dart';
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
  final CheckInApi _api = CheckInApi();
  final CheckInAudioService _audioService = CheckInAudioService();
  AppScreen _screen = AppScreen.welcome;
  List<CheckInMessage> _caregiverMessages = List.of(sampleMessages);
  CheckInMessage? _selectedMessage;
  AppUser? _currentUser;
  String? _recordedAudioPath;
  bool _isRecording = false;
  bool _isAuthLoading = false;
  bool _isFeedLoading = false;
  bool _isSendingCheckIn = false;
  bool _isUpdatingMessage = false;
  bool _isLinkingSenior = false;
  String? _authError;
  String? _feedError;
  String? _sendError;
  String? _linkError;

  void _go(AppScreen screen) {
    setState(() => _screen = screen);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
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
          onCreateAccount: (role) => _go(role == Role.senior
              ? AppScreen.seniorSignup
              : AppScreen.caregiverSignup),
          onSignIn: _login,
          isLoading: _isAuthLoading,
          errorText: _authError,
        );
      case AppScreen.seniorSignup:
        return SignupScreen.senior(
          onCreate: _signUpSenior,
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverSignup:
        return SignupScreen.caregiver(
          onCreate: _signUpCaregiver,
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverHome:
        return CaregiverHomeScreen(
          messages: _caregiverMessages,
          onMessageSelected: _openMessage,
          onMessageDismissed: _dismissMessage,
          onFamily: () => _go(AppScreen.family),
          onRefresh: _refreshFeed,
          userName: _currentUser?.displayName.isNotEmpty == true
              ? _currentUser!.displayName
              : _currentUser?.id ?? 'Caregiver',
          isLoading: _isFeedLoading,
          errorText: _feedError,
        );
      case AppScreen.family:
        return FamilyScreen(
          family: _linkedFamilyLabels(),
          onHome: () => _go(AppScreen.caregiverHome),
          onLinkSenior: _linkSenior,
          isLinking: _isLinkingSenior,
          linkError: _linkError,
        );
      case AppScreen.message:
        return MessageDetailScreen(
          message: _selectedMessage ?? sampleMessages.first,
          onBack: () => _go(AppScreen.caregiverHome),
          onAcknowledge: () => _updateSelectedMessageStatus('acknowledged'),
          onResolve: () => _updateSelectedMessageStatus('resolved'),
          isUpdating: _isUpdatingMessage,
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
          onToggleRecording: _toggleRecording,
          onDone: _sendCheckIn,
          seniorId: _currentUser?.id ?? 'senior-1',
          hasRecording: _recordedAudioPath != null,
          isSending: _isSendingCheckIn,
          errorText: _sendError,
        );
      case AppScreen.delivered:
        return DeliveredScreen(onHome: () => _go(AppScreen.elderHome));
      case AppScreen.health:
        return SimpleStatusScreen(
          title: 'Health Logs',
          icon: Icons.monitor_heart_outlined,
          body:
              'Medication, mood, and symptom trends will appear here after daily voice check-ins are processed.',
          onBack: () => _go(AppScreen.elderHome),
        );
      case AppScreen.settings:
        return SimpleStatusScreen(
          title: 'Settings',
          icon: Icons.settings_outlined,
          body:
              'Manage trusted contacts, emergency preferences, reminders, and accessibility options.',
          onBack: () => _go(AppScreen.elderHome),
        );
    }
  }

  void _openMessage(CheckInMessage message) {
    setState(() {
      _selectedMessage = message;
      _screen = AppScreen.message;
    });
  }

  void _dismissMessage(CheckInMessage message) {
    setState(() {
      _caregiverMessages =
          _caregiverMessages.where((item) => item.id != message.id).toList();
      if (_selectedMessage?.id == message.id) {
        _selectedMessage = null;
      }
    });
  }

  Future<void> _signUp(Role role, SignupFormData data) async {
    final user = await _api.signUp(
      role: role,
      userId: data.userId,
      password: data.password,
      displayName: data.displayName,
      profileContext: data.profileContext,
      occupation: data.occupation,
    );
    setState(() {
      _currentUser = user;
      _authError = null;
      _screen = user.role == Role.senior
          ? AppScreen.elderHome
          : AppScreen.caregiverHome;
    });
    if (user.role == Role.caregiver) {
      await _refreshFeed();
    }
  }

  Future<void> _signUpSenior(SignupFormData data) {
    return _signUp(Role.senior, data);
  }

  Future<void> _signUpCaregiver(SignupFormData data) {
    return _signUp(Role.caregiver, data);
  }

  Future<void> _login(String userId, String password) async {
    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });
    try {
      final user = await _api.login(userId: userId, password: password);
      setState(() {
        _currentUser = user;
        _screen = user.role == Role.senior
            ? AppScreen.elderHome
            : AppScreen.caregiverHome;
      });
      if (user.role == Role.caregiver) {
        await _refreshFeed();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _authError = error.toString());
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _refreshFeed() async {
    final user = _currentUser;
    if (user == null || user.role != Role.caregiver) return;
    setState(() {
      _isFeedLoading = true;
      _feedError = null;
    });
    try {
      final messages = await _api.fetchFeed(caregiverId: user.id);
      if (!mounted) return;
      setState(() => _caregiverMessages = messages);
    } catch (error) {
      if (!mounted) return;
      setState(() => _feedError = error.toString());
    } finally {
      if (mounted) setState(() => _isFeedLoading = false);
    }
  }

  Future<void> _toggleRecording() async {
    final user = _currentUser;
    if (user == null || user.role != Role.senior) {
      setState(() => _sendError =
          'Please sign in as a senior before recording a check-in.');
      return;
    }

    setState(() => _sendError = null);
    try {
      if (_isRecording) {
        final path = await _audioService.stopRecording();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
        });
        return;
      }

      await _audioService.startRecording(user.id);
      if (!mounted) return;
      setState(() {
        _recordedAudioPath = null;
        _isRecording = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _sendError = error.toString();
      });
    }
  }

  Future<void> _sendCheckIn() async {
    final user = _currentUser;
    final localPath = _recordedAudioPath;
    if (user == null || user.role != Role.senior) {
      setState(() =>
          _sendError = 'Please sign in as a senior before sending a check-in.');
      return;
    }
    if (localPath == null) {
      setState(() => _sendError = 'Record a voice check-in before sending.');
      return;
    }

    setState(() {
      _isSendingCheckIn = true;
      _sendError = null;
    });
    try {
      final storagePath = await _audioService.uploadRecording(
        seniorId: user.id,
        localPath: localPath,
      );
      await _api.ingestTriage(seniorId: user.id, storagePath: storagePath);
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedAudioPath = null;
        _screen = AppScreen.delivered;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendError = error.toString());
    } finally {
      if (mounted) setState(() => _isSendingCheckIn = false);
    }
  }

  Future<void> _updateSelectedMessageStatus(String status) async {
    final message = _selectedMessage;
    if (message == null) return;
    setState(() => _isUpdatingMessage = true);
    try {
      await _api.updateMessageStatus(
        messageId: message.id,
        status: status,
        actionTaken: status == 'resolved'
            ? 'Marked as resolved in the Flutter app.'
            : 'Acknowledged in the Flutter app.',
      );
      if (!mounted) return;
      setState(() {
        _caregiverMessages =
            _caregiverMessages.where((item) => item.id != message.id).toList();
        _selectedMessage = null;
        _screen = AppScreen.caregiverHome;
      });
      await _refreshFeed();
    } catch (error) {
      if (!mounted) return;
      setState(() => _feedError = error.toString());
    } finally {
      if (mounted) setState(() => _isUpdatingMessage = false);
    }
  }

  Future<void> _linkSenior(String pairingCode) async {
    final user = _currentUser;
    if (user == null || user.role != Role.caregiver) return;
    setState(() {
      _isLinkingSenior = true;
      _linkError = null;
    });
    try {
      await _api.linkSenior(
          caregiverId: user.id, seniorPairingCode: pairingCode);
      await _refreshFeed();
    } catch (error) {
      if (!mounted) return;
      setState(() => _linkError = error.toString());
    } finally {
      if (mounted) setState(() => _isLinkingSenior = false);
    }
  }

  List<String> _linkedFamilyLabels() {
    final linked = _caregiverMessages
        .map((message) => message.seniorId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (linked.isEmpty) return familyMembers;
    return linked;
  }
}
