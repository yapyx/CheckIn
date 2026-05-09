import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({required this.title, this.onBack, this.avatar = 'A', super.key});

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
