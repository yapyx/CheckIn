import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../widgets/caregiver_nav.dart';
import '../widgets/screen_frame.dart';
import '../widgets/top_bar.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    required this.family,
    required this.onMemberAdded,
    required this.onHome,
    super.key,
  });

  final List<FamilyMember> family;
  final ValueChanged<FamilyMember> onMemberAdded;
  final VoidCallback onHome;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  late List<FamilyMember> _members;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _members = List.of(widget.family);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: CaregiverNav(onHome: widget.onHome, onFamily: () {}, activeFamily: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          const TopBar(title: 'Family', avatar: 'A'),
          const SizedBox(height: 10),
          const Text('Caring for', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.25)),
          const SizedBox(height: 4),
          const Text('Your Household', style: TextStyle(fontSize: 22, color: Color(0xFF061D3B), fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 22),
          for (final member in _members) _FamilyMemberCard(member: member),
          const SizedBox(height: 16),
          _AddMemberForm(
            userIdController: _userIdController,
            nicknameController: _nicknameController,
            showValidation: _showValidation,
            onAdd: _addMember,
          ),
        ],
      ),
    );
  }

  void _addMember() {
    final userId = _userIdController.text.trim();
    final nickname = _nicknameController.text.trim();
    if (userId.isEmpty || nickname.isEmpty) {
      setState(() => _showValidation = true);
      return;
    }

    final member = FamilyMember(userId: userId, nickname: nickname);
    setState(() {
      _members.add(member);
      _userIdController.clear();
      _nicknameController.clear();
      _showValidation = false;
    });
    widget.onMemberAdded(member);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family member added')),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFDCEBFF),
            child: Icon(Icons.face_rounded, color: Color(0xFF061D3B), size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF061D3B), height: 1.2)),
                const SizedBox(height: 4),
                Text(member.userId, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberForm extends StatelessWidget {
  const _AddMemberForm({
    required this.userIdController,
    required this.nicknameController,
    required this.showValidation,
    required this.onAdd,
  });

  final TextEditingController userIdController;
  final TextEditingController nicknameController;
  final bool showValidation;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5DAE1), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Text('Add Family Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF061D3B), height: 1.2)),
          const SizedBox(height: 8),
          const Text('Connect to an elderly user’s device via ID', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.35)),
          const SizedBox(height: 20),
          _FamilyInput(controller: userIdController, label: 'Elderly User ID', hint: 'e.g. CS-9942-88'),
          const SizedBox(height: 14),
          _FamilyInput(controller: nicknameController, label: 'Nickname', hint: 'e.g. Grandma Mary'),
          if (showValidation) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Please enter both Elderly User ID and Nickname.', style: TextStyle(color: Color(0xFFB42318), fontSize: 13, height: 1.3)),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF061D3B),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyInput extends StatelessWidget {
  const _FamilyInput({required this.controller, required this.label, required this.hint});

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF061D3B), fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB8BEC8), fontWeight: FontWeight.w700),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF8E97A3), width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF0B63C9), width: 1.6),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }
}
