import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('CheckIn',
                style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF061734),
                    height: 1.15)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Dependable daily care',
            style: TextStyle(
                fontSize: 19,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w400,
                height: 1.25)),
      ],
    );
  }
}
