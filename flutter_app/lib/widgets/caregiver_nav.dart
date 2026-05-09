import 'package:flutter/material.dart';

class CaregiverNav extends StatelessWidget {
  const CaregiverNav({
    required this.onHome,
    required this.onFamily,
    required this.activeFamily,
    super.key,
  });

  final VoidCallback onHome;
  final VoidCallback onFamily;
  final bool activeFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _BottomNavItem(
            label: 'Home',
            icon: activeFamily ? Icons.home_outlined : Icons.home_rounded,
            active: !activeFamily,
            onTap: onHome,
          ),
          _BottomNavItem(
            label: 'Family',
            icon: activeFamily ? Icons.group_rounded : Icons.group_outlined,
            active: activeFamily,
            onTap: onFamily,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF0B1F33) : const Color(0xFF6B7280);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
