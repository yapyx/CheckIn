import 'package:flutter/material.dart';

class TrustFooter extends StatelessWidget {
  const TrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 49),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1F3),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF4B5563)),
            SizedBox(width: 8),
            Text('Government-grade protection', style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w400, fontSize: 14, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
