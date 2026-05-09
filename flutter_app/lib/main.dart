import 'package:flutter/material.dart';

void main() {
  runApp(const CheckInApp());
}

enum AppScreen {
  welcome,
  elderSignup,
  caregiverSignup,
  caregiverHome,
  family,
  message,
  elderHome,
  recorder,
  delivered,
  health,
  settings,
}

enum Role { elder, caregiver }

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
}

enum MessageTone { critical, warm, plain }

class CheckInApp extends StatelessWidget {
  const CheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CheckIn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0968B8),
          primary: const Color(0xFF0968B8),
          secondary: const Color(0xFF69ADFF),
          error: const Color(0xFFDC151B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        fontFamily: 'Arial',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFF9CA8B8)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      home: const CheckInHome(),
    );
  }
}

class CheckInHome extends StatefulWidget {
  const CheckInHome({super.key});

  @override
  State<CheckInHome> createState() => _CheckInHomeState();
}

class _CheckInHomeState extends State<CheckInHome> {
  AppScreen _screen = AppScreen.welcome;
  Role _selectedRole = Role.elder;
  CheckInMessage? _selectedMessage;
  bool _isRecording = false;

  final List<String> _family = const ['Grandpa Joe', 'Grandma Mary'];
  final List<CheckInMessage> _messages = const [
    CheckInMessage(
      id: 'critical',
      kind: 'Critical Alert',
      title: 'Medication Reminder Missed',
      time: '10 mins ago',
      copy: "Sarah hasn't acknowledged her morning blood pressure medication. This may require immediate attention.",
      tone: MessageTone.critical,
      icon: Icons.warning_rounded,
      transcript: 'I forgot whether I took my blood pressure pill this morning, and I feel a little dizzy.',
      summary: 'Possible missed blood pressure medication with dizziness reported.',
      intent: 'Medical Alert',
      mood: 'Concerned',
    ),
    CheckInMessage(
      id: 'note',
      kind: 'Personal Note',
      title: 'Feeling Lonely',
      time: '45 mins ago',
      copy: 'Just wanted to say hi and ask about dinner plans tonight. It has been a quiet afternoon.',
      tone: MessageTone.warm,
      icon: Icons.favorite_border_rounded,
      transcript: 'I was just wondering if you are coming over for dinner today? I made your favorite chicken stew.',
      summary: 'Grandma Mary is checking dinner plans and would appreciate a response.',
      intent: 'Routine Inquiry',
      mood: 'Anticipatory',
    ),
    CheckInMessage(
      id: 'daily',
      kind: 'Check-in',
      title: 'Daily Status',
      time: '5 hours ago',
      copy: "I'm doing well today, the weather looks lovely through the window.",
      tone: MessageTone.plain,
      icon: Icons.check_circle_outline_rounded,
      transcript: "I'm doing well today, the weather looks lovely through the window.",
      summary: 'Daily wellbeing check-in, no action needed.',
      intent: 'Daily Check-in',
      mood: 'Content',
    ),
  ];

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
        return _WelcomeScreen(
          selectedRole: _selectedRole,
          onRoleSelected: (role) => setState(() => _selectedRole = role),
          onCreateAccount: () => _go(_selectedRole == Role.elder ? AppScreen.elderSignup : AppScreen.caregiverSignup),
        );
      case AppScreen.elderSignup:
        return _SignupScreen(
          title: 'Join CheckIn',
          subtitle: 'Please fill in your details to get started.',
          fields: const ['User ID', 'Create Password', 'Age', 'Health Conditions', 'Notes / Other Information'],
          onCreate: () => _go(AppScreen.elderHome),
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverSignup:
        return _SignupScreen(
          title: 'Create Caregiver Account',
          fields: const ['User ID', 'Create Password', 'Occupation', 'Others/Specializations'],
          onCreate: () => _go(AppScreen.caregiverHome),
          onCancel: () => _go(AppScreen.welcome),
        );
      case AppScreen.caregiverHome:
        return _CaregiverHomeScreen(
          messages: _messages,
          onMessageSelected: (message) {
            setState(() {
              _selectedMessage = message;
              _screen = AppScreen.message;
            });
          },
          onFamily: () => _go(AppScreen.family),
        );
      case AppScreen.family:
        return _FamilyScreen(family: _family, onHome: () => _go(AppScreen.caregiverHome));
      case AppScreen.message:
        return _MessageDetailScreen(
          message: _selectedMessage ?? _messages.first,
          onBack: () => _go(AppScreen.caregiverHome),
          onReply: () => _go(AppScreen.delivered),
        );
      case AppScreen.elderHome:
        return _ElderHomeScreen(
          onRecord: () => _go(AppScreen.recorder),
          onHealth: () => _go(AppScreen.health),
          onSettings: () => _go(AppScreen.settings),
        );
      case AppScreen.recorder:
        return _RecorderScreen(
          isRecording: _isRecording,
          onToggleRecording: () => setState(() => _isRecording = !_isRecording),
          onDone: () {
            setState(() {
              _isRecording = false;
              _screen = AppScreen.delivered;
            });
          },
        );
      case AppScreen.delivered:
        return _DeliveredScreen(onHome: () => _go(AppScreen.elderHome));
      case AppScreen.health:
        return _SimpleStatusScreen(
          title: 'Health Logs',
          icon: Icons.monitor_heart_outlined,
          body: 'Medication, mood, and symptom trends will appear here after daily voice check-ins are processed.',
          onBack: () => _go(AppScreen.elderHome),
        );
      case AppScreen.settings:
        return _SimpleStatusScreen(
          title: 'Settings',
          icon: Icons.settings_outlined,
          body: 'Manage trusted contacts, emergency preferences, reminders, and accessibility options.',
          onBack: () => _go(AppScreen.elderHome),
        );
    }
  }
}

class _ScreenFrame extends StatelessWidget {
  const _ScreenFrame({required this.child, this.bottomNavigationBar, this.backgroundColor});

  final Widget child;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.selectedRole, required this.onRoleSelected, required this.onCreateAccount});

  final Role selectedRole;
  final ValueChanged<Role> onRoleSelected;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 20),
          const _HeroCard(),
          const SizedBox(height: 24),
          SegmentedButton<Role>(
            segments: const [
              ButtonSegment(value: Role.elder, label: Text('Sign Up')),
              ButtonSegment(value: Role.caregiver, label: Text('Sign In')),
            ],
            selected: {selectedRole},
            onSelectionChanged: (selection) => onRoleSelected(selection.first),
          ),
          const SizedBox(height: 24),
          const Text('Tell us who you are', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _RoleCard(
            role: Role.elder,
            selectedRole: selectedRole,
            icon: Icons.directions_walk_rounded,
            title: 'I am an Elder',
            subtitle: 'I want to receive care',
            onTap: onRoleSelected,
          ),
          _RoleCard(
            role: Role.caregiver,
            selectedRole: selectedRole,
            icon: Icons.support_agent_rounded,
            title: 'I am a Caregiver',
            subtitle: 'I am here to support someone',
            onTap: onRoleSelected,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onCreateAccount, child: const Text('Create New Account')),
          const _TrustFooter(),
        ],
      ),
    );
  }
}

class _SignupScreen extends StatelessWidget {
  const _SignupScreen({required this.title, required this.fields, required this.onCreate, required this.onCancel, this.subtitle});

  final String title;
  final String? subtitle;
  final List<String> fields;
  final VoidCallback onCreate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: const TextStyle(fontSize: 18, color: Color(0xFF5F6670))),
          ],
          const SizedBox(height: 20),
          for (final field in fields) _TextEntry(label: field),
          const SizedBox(height: 8),
          const Text(
            'By clicking Create, you agree to our Data Processing Agreement and Terms of Conduct.',
            style: TextStyle(color: Color(0xFF4E535D)),
          ),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: onCreate, child: const Text('Create')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
          const _TrustFooter(),
        ],
      ),
    );
  }
}

class _CaregiverHomeScreen extends StatelessWidget {
  const _CaregiverHomeScreen({required this.messages, required this.onMessageSelected, required this.onFamily});

  final List<CheckInMessage> messages;
  final ValueChanged<CheckInMessage> onMessageSelected;
  final VoidCallback onFamily;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      bottomNavigationBar: _CaregiverNav(onHome: () {}, onFamily: onFamily, activeFamily: false),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _TopBar(title: 'CheckIn'),
          const Text('Mon, 15 Feb', style: TextStyle(color: Color(0xFF68707C))),
          const SizedBox(height: 12),
          const Text('Hello, Angelica', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Your family needs you', style: TextStyle(fontSize: 22, color: Color(0xFF3C414C))),
          const SizedBox(height: 20),
          for (final message in messages) _MessageCard(message: message, onTap: () => onMessageSelected(message)),
        ],
      ),
    );
  }
}

class _FamilyScreen extends StatelessWidget {
  const _FamilyScreen({required this.family, required this.onHome});

  final List<String> family;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      bottomNavigationBar: _CaregiverNav(onHome: onHome, onFamily: () {}, activeFamily: true),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _TopBar(title: 'Family'),
          const SizedBox(height: 16),
          for (final member in family)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.elderly_rounded)),
                title: Text(member, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                subtitle: const Text('Daily check-ins enabled'),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Family Member')),
        ],
      ),
    );
  }
}

class _MessageDetailScreen extends StatelessWidget {
  const _MessageDetailScreen({required this.message, required this.onBack, required this.onReply});

  final CheckInMessage message;
  final VoidCallback onBack;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _TopBar(title: message.kind, onBack: onBack),
          if (message.tone == MessageTone.critical) const _EmergencyBanner(),
          _VoiceCard(message: message),
          const Text('AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _AnalysisTile(label: 'Intent', value: message.intent)),
              const SizedBox(width: 12),
              Expanded(child: _AnalysisTile(label: 'Mood', value: message.mood)),
            ],
          ),
          const SizedBox(height: 20),
          Text('"${message.transcript}"', style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic, height: 1.45)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: onReply, icon: const Icon(Icons.reply_rounded), label: const Text('Send quick reply')),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onReply, icon: const Icon(Icons.check_rounded), label: const Text('Mark as handled')),
        ],
      ),
    );
  }
}

class _ElderHomeScreen extends StatelessWidget {
  const _ElderHomeScreen({required this.onRecord, required this.onHealth, required this.onSettings});

  final VoidCallback onRecord;
  final VoidCallback onHealth;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) onHealth();
          if (index == 2) onSettings();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Health Logs'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _TopBar(title: 'CheckIn', avatar: 'M'),
          const SizedBox(height: 24),
          const Text('Hi Mary, ready for your daily check-in?', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          const Text('Record a short update for your care team. We will share urgent concerns right away.', style: TextStyle(fontSize: 20, color: Color(0xFF4E535D))),
          const SizedBox(height: 36),
          ElevatedButton.icon(onPressed: onRecord, icon: const Icon(Icons.mic_rounded), label: const Text('Start Voice Check-in')),
          const SizedBox(height: 20),
          const _CareStatusCard(),
        ],
      ),
    );
  }
}

class _RecorderScreen extends StatelessWidget {
  const _RecorderScreen({required this.isRecording, required this.onToggleRecording, required this.onDone});

  final bool isRecording;
  final VoidCallback onToggleRecording;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
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

class _DeliveredScreen extends StatelessWidget {
  const _DeliveredScreen({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      backgroundColor: const Color(0xFFEEF3FA),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 36),
          const CircleAvatar(radius: 68, backgroundColor: Color(0xFFD6E5FF), child: Icon(Icons.check_rounded, size: 78, color: Color(0xFF0968B8))),
          const SizedBox(height: 32),
          const Text('Your message was delivered', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Text('Angelica will see your check-in soon.', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Color(0xFF4E535D))),
          const SizedBox(height: 40),
          const _CareStatusCard(),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onHome, child: const Text('Back Home')),
        ],
      ),
    );
  }
}

class _SimpleStatusScreen extends StatelessWidget {
  const _SimpleStatusScreen({required this.title, required this.icon, required this.body, required this.onBack});

  final String title;
  final IconData icon;
  final String body;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(title: title, onBack: onBack),
            const Spacer(),
            Center(child: Icon(icon, size: 92, color: const Color(0xFF0968B8))),
            const SizedBox(height: 24),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, color: Color(0xFF4E535D), height: 1.4)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CheckIn', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Color(0xFF061734))),
        Text('Dependable daily care', style: TextStyle(fontSize: 18, color: Color(0xFF68707C))),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x170B1C34), blurRadius: 24, offset: Offset(0, 14))]),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_grocery_store_rounded, size: 56, color: Color(0xFF0968B8)),
          SizedBox(width: 24),
          Icon(Icons.elderly_woman_rounded, size: 72, color: Color(0xFF061734)),
          SizedBox(width: 24),
          Icon(Icons.medical_services_rounded, size: 56, color: Color(0xFF22CA62)),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.selectedRole, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final Role role;
  final Role selectedRole;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<Role> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = role == selectedRole;
    return Card(
      color: selected ? const Color(0xFFE6F1FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? const Color(0xFF0968B8) : const Color(0xFFC7CEDA), width: selected ? 2 : 1),
      ),
      child: ListTile(
        onTap: () => onTap(role),
        leading: CircleAvatar(backgroundColor: const Color(0xFFD7E5FF), child: Icon(icon, color: const Color(0xFF061734))),
        title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0968B8)) : null,
      ),
    );
  }
}

class _TextEntry extends StatelessWidget {
  const _TextEntry({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        minLines: label.contains('Notes') || label.contains('Specializations') ? 3 : 1,
        maxLines: label.contains('Notes') || label.contains('Specializations') ? 3 : 1,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onBack, this.avatar = 'A'});

  final String title;
  final VoidCallback? onBack;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          CircleAvatar(child: Text(avatar)),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.onTap});

  final CheckInMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(message.tone);
    return Card(
      color: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: colors.iconBackground, child: Icon(message.icon, color: colors.icon)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message.kind, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  Text(message.time, style: const TextStyle(color: Color(0xFF6E7480))),
                ],
              ),
              const SizedBox(height: 18),
              Text(message.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message.copy, style: const TextStyle(fontSize: 18, color: Color(0xFF3C414C))),
            ],
          ),
        ),
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
            Text(message.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(message.summary, style: const TextStyle(fontSize: 18, color: Color(0xFF3C414C))),
            const SizedBox(height: 24),
            const _Waveform(),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.filled(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded)),
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
      decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          final height = 16.0 + (index % 5) * 9.0;
          return Container(
            width: 6,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(color: const Color(0xFF0968B8).withOpacity(index.isEven ? .35 : 1), borderRadius: BorderRadius.circular(6)),
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
          Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF5A9BD6), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
          Expanded(child: Text('Emergency attention may be required.', style: TextStyle(color: Color(0xFF9C1015), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CaregiverNav extends StatelessWidget {
  const _CaregiverNav({required this.onHome, required this.onFamily, required this.activeFamily});

  final VoidCallback onHome;
  final VoidCallback onFamily;
  final bool activeFamily;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: activeFamily ? 1 : 0,
      onDestinationSelected: (index) => index == 0 ? onHome() : onFamily(),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.family_restroom_rounded), label: 'Family'),
      ],
    );
  }
}

class _CareStatusCard extends StatelessWidget {
  const _CareStatusCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE6F1FF),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: const [
            CircleAvatar(child: Icon(Icons.work_rounded)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I am working now!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('Will see your message soon. Sent 10:30 AM'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Color(0xFF4E535D)),
          SizedBox(width: 8),
          Text('Government-grade protection', style: TextStyle(color: Color(0xFF4E535D), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

_ToneColors _toneColors(MessageTone tone) {
  switch (tone) {
    case MessageTone.critical:
      return const _ToneColors(Color(0xFFF0F1F3), Color(0xFFDC151B), Color(0xFFFFD7D7), Color(0xFFD71920));
    case MessageTone.warm:
      return const _ToneColors(Color(0xFFFFF0E9), Color(0xFFD89162), Color(0xFFFFD9C8), Color(0xFF88420E));
    case MessageTone.plain:
      return const _ToneColors(Colors.white, Color(0xFFC7CEDA), Color(0xFFDCEAFF), Color(0xFF095FAC));
  }
}

class _ToneColors {
  const _ToneColors(this.background, this.border, this.iconBackground, this.icon);

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color icon;
}
