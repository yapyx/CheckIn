import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar(
      {required this.title, this.onBack, this.avatar = 'A', super.key});

  final String title;
  final VoidCallback? onBack;
  final String avatar;

  String get _avatarAsset =>
      avatar == 'M' ? 'assets/senior pfp.png' : 'assets/caregiver pfp.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
                onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(child: _Title(title: title)),
          CircleAvatar(backgroundImage: AssetImage(_avatarAsset)),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 24, fontWeight: FontWeight.w900);
    if (title != 'CheckIn') return Text(title, style: style);

    return Row(
      children: [
        Image.asset(
          'assets/logo.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        const Text('CheckIn', style: style),
      ],
    );
  }
}
