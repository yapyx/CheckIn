import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/app_screen.dart';
import '../models/app_user.dart';
import '../models/checkin_message.dart';
import '../models/family_member.dart';
import '../models/role.dart';
import '../models/signup_form_data.dart';
import '../services/audio_upload_service.dart';
import '../services/checkin_api.dart';
import '../services/checkin_notifications.dart';
import '../services/session_store.dart';
import 'caregiver_home_screen.dart';
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
  List<FamilyMember> _familyMembers = [];
  bool _isRecording = false;
  bool _isSendingRecording = false;
  bool _isRefreshingCaregiverData = false;
  String? _recordingPath;
  Timer? _caregiverRefreshTimer;
  AppUser? _currentUser;
  final CheckInApi _api = CheckInApi();
  final CheckInAudioService _audioService = CheckInAudioService();
  final CheckInSessionStore _sessionStore = CheckInSessionStore();

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _caregiverRefreshTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadFeed(
      {String caregiverId = 'demo-caregiver',
      bool replaceWithEmpty = false}) async {
    try {
      final messages = _sortMessages(
          await _api.fetchFeed(caregiverId: caregiverId));
      if (!mounted) return;
      final newFamilyMembers = _familyMembersFromMessages(messages);
      if (messages.isNotEmpty || replaceWithEmpty) {
        setState(() {
          _caregiverMessages = messages;
          _familyMembers = [..._familyMembers, ...newFamilyMembers];
        });
      } else if (newFamilyMembers.isNotEmpty) {
        setState(
            () => _familyMembers = [..._familyMembers, ...newFamilyMembers]);
      }
    } catch (_) {
      // Keep sample data on any error (minimal change requirement).
    }
  }

  List<FamilyMember> _familyMembersFromMessages(List<CheckInMessage> messages) {
    final existingIds = _familyMembers.map((member) => member.userId).toSet();
    return messages
        .map((message) => message.seniorId)
        .where((seniorId) => seniorId.isNotEmpty && existingIds.add(seniorId))
        .map((seniorId) => FamilyMember(userId: seniorId, nickname: seniorId))
        .toList();
  }

  List<CheckInMessage> _sortMessages(List<CheckInMessage> messages) {
    final sorted = List<CheckInMessage>.of(messages);
    sorted.sort((a, b) {
      final aResolved = a.status.toLowerCase() == 'resolved';
      final bResolved = b.status.toLowerCase() == 'resolved';
      if (aResolved == bResolved) return 0;
      return aResolved ? 1 : -1;
    });
    return sorted;
  }

  void _go(AppScreen screen) {
    setState(() => _screen = screen);
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _sessionStore.load();
      if (!mounted || user == null) return;

      _currentUser = user;
      if (user.role == Role.caregiver) {
        await _registerCaregiverNotifications(user.id);
        await _loadFeed(caregiverId: user.id, replaceWithEmpty: true);
        _startCaregiverRefresh();
        if (mounted) _go(AppScreen.caregiverHome);
      } else {
        _stopCaregiverRefresh();
        _go(AppScreen.recorder);
      }
    } catch (_) {
      // Stay signed out if the saved session cannot be read.
    }
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
          onSignIn: _signIn,
        );
      case AppScreen.seniorSignup:
        return SignupScreen.senior(
          onCreate: (data) => _createAccount(Role.senior, data),
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverSignup:
        return SignupScreen.caregiver(
          onCreate: (data) => _createAccount(Role.caregiver, data),
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverHome:
        return CaregiverHomeScreen(
          messages: _caregiverMessages,
          onMessageDismissed: _dismissMessage,
          onFamily: () => _go(AppScreen.family),
          onLogout: () => _logout(),
        );
      case AppScreen.message:
        return SimpleStatusScreen(
          title: 'Message',
          icon: Icons.message_outlined,
          body: 'Message details are not available in this demo.',
          onBack: () => _go(AppScreen.caregiverHome),
        );
      case AppScreen.family:
        return FamilyScreen(
          family: _familyMembers,
          onMemberAdded: _addFamilyMember,
          onHome: () => _go(AppScreen.caregiverHome),
        );
      case AppScreen.elderHome:
      case AppScreen.recorder:
      case AppScreen.delivered:
      case AppScreen.health:
      case AppScreen.settings:
        return RecorderScreen(
          isRecording: _isRecording,
          onToggleRecording: _toggleRecording,
          onLogout: () => _logout(),
        );
    }
  }

  void _dismissMessage(CheckInMessage message) {
    _api
        .updateMessageStatus(
      messageId: message.id,
      status: 'resolved',
      actionTaken: 'Marked as handled from caregiver dashboard.',
    )
        .then((_) {
      final caregiverId = _currentUser?.id;
      if (caregiverId != null) {
        _loadFeed(caregiverId: caregiverId, replaceWithEmpty: true);
      }
    })
        .catchError((_) {
      if (mounted) {
        _showError('Could not update message status.');
      }
    });
  }

  Future<bool> _addFamilyMember(FamilyMember member) async {
    final caregiverId = _currentUser?.id;
    if (caregiverId == null || _currentUser?.role != Role.caregiver) {
      _showError('Please sign in as a caregiver first.');
      return false;
    }

    try {
      final linkedSeniorId = await _api.linkSenior(
        caregiverId: caregiverId,
        seniorPairingCode: member.userId,
      );
      final linkedMember = FamilyMember(
        userId: linkedSeniorId.isEmpty ? member.userId : linkedSeniorId,
        nickname: member.nickname,
      );
      setState(() => _familyMembers = [..._familyMembers, linkedMember]);
      await _loadFeed(caregiverId: caregiverId, replaceWithEmpty: true);
      return true;
    } catch (_) {
      _showError('Could not link that senior account.');
      return false;
    }
  }

  Future<void> _createAccount(Role role, SignupFormData data) async {
    try {
      final user = await _api.signUp(
        role: role,
        userId: data.userId,
        password: data.password,
        displayName: data.displayName,
        profileContext: data.profileContext,
        occupation: data.occupation,
      );
      await _rememberUser(user);
      if (user.role == Role.caregiver) {
        await _registerCaregiverNotifications(user.id);
        await _loadFeed(caregiverId: user.id, replaceWithEmpty: true);
        _startCaregiverRefresh();
        _go(AppScreen.caregiverHome);
      } else {
        _stopCaregiverRefresh();
        _go(AppScreen.recorder);
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _signIn(LoginFormData data) async {
    try {
      final user =
          await _api.login(userId: data.userId, password: data.password);
      if (user.role != data.role) {
        _showError('This account is registered as a different role.');
        return;
      }
      await _rememberUser(user);
      if (user.role == Role.caregiver) {
        await _registerCaregiverNotifications(user.id);
        await _loadFeed(caregiverId: user.id, replaceWithEmpty: true);
        _startCaregiverRefresh();
        _go(AppScreen.caregiverHome);
      } else {
        _stopCaregiverRefresh();
        _go(AppScreen.recorder);
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _rememberUser(AppUser user) async {
    _currentUser = user;
    try {
      await _sessionStore.save(user);
    } catch (_) {
      // Keep the in-memory login even if persistence is unavailable.
    }
  }

  Future<void> _logout() async {
    try {
      await _sessionStore.clear();
    } catch (_) {
      _showError('Could not log out. Please try again.');
      return;
    }

    if (!mounted) return;
    _stopCaregiverRefresh();
    setState(() {
      _currentUser = null;
      _isRecording = false;
      _isSendingRecording = false;
      _recordingPath = null;
      _screen = AppScreen.welcome;
    });
  }

  void _startCaregiverRefresh() {
    _caregiverRefreshTimer?.cancel();
    _caregiverRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshCaregiverData(),
    );
  }

  void _stopCaregiverRefresh() {
    _caregiverRefreshTimer?.cancel();
    _caregiverRefreshTimer = null;
  }

  Future<void> _refreshCaregiverData() async {
    final user = _currentUser;
    if (_isRefreshingCaregiverData ||
        user == null ||
        user.role != Role.caregiver) {
      return;
    }

    _isRefreshingCaregiverData = true;
    try {
      await _loadFeed(caregiverId: user.id, replaceWithEmpty: true);
    } finally {
      _isRefreshingCaregiverData = false;
    }
  }

  Future<void> _toggleRecording() async {
    if (_isSendingRecording) return;

    if (!_isRecording) {
      try {
        final path = await _audioService.startRecording(_seniorId);
        setState(() {
          _recordingPath = path;
          _isRecording = true;
        });
      } catch (error) {
        _showError(error.toString());
      }
      return;
    }

    setState(() {
      _isRecording = false;
      _isSendingRecording = true;
    });
    try {
      final stoppedPath = await _audioService.stopRecording();
      final localPath = stoppedPath ?? _recordingPath;
      if (localPath == null) {
        throw StateError('No recorded audio was available to upload.');
      }
      final storagePath = await _audioService.uploadRecording(
        seniorId: _seniorId,
        localPath: localPath,
      );
      if (storagePath.isEmpty) {
        throw StateError(
            'Recorded audio upload did not return a storage path.');
      }
      _recordingPath = null;
      if (mounted) _showMessageSentDialog();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSendingRecording = false);
      }
    }
  }

  void _showMessageSentDialog() {
    var dismissed = false;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 5), () {
          if (!dismissed && Navigator.of(dialogContext).canPop()) {
            dismissed = true;
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          contentPadding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE7F6EC),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 94, color: Color(0xFF198754)),
              ),
              const SizedBox(height: 24),
              const Text('Message Sent',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF061D3B),
                      height: 1.2)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    dismissed = true;
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B63C9),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => dismissed = true);
  }

  String get _seniorId {
    final user = _currentUser;
    if (user != null && user.role == Role.senior) return user.id;
    return 'senior-1';
  }

  Future<void> _registerCaregiverNotifications(String caregiverId) async {
    try {
      await CheckInNotifications.registerCaregiverToken(
        caregiverId: caregiverId,
        api: _api,
      );
    } catch (_) {
      _showError('Notifications could not be enabled on this device.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }
}
